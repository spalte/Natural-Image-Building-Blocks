//  Copyright (c) 2016 Spaltenstein Natural Image
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

/*=========================================================================
 Program:   OsiriX

 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL

 See http://www.osirix-viewer.com/copyright.html for details.

 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import "NIGenerator.h"
#import "NIVolumeData.h"
#import "NIGeneratorRequest.h"
#import "NIGeneratorOperation.h"

NSString * const _NIGeneratorRunLoopMode = @"_NIGeneratorRunLoopMode";

static volatile int64_t requestIDCount __attribute__ ((__aligned__(8))) = 0;

@interface NIGenerator ()

+ (NSMutableDictionary<NSNumber *, NSOperation *> *)_requestIDs;
+ (NIGeneratorAsynchronousRequestID)_generateRequestID;
+ (void)_setOperation:(NSOperation *)operation forRequestID:(NIGeneratorAsynchronousRequestID)requestID;
+ (NSOperation *)_operationForRequestID:(NIGeneratorAsynchronousRequestID)requestID;
+ (void)_removeOperationForRequestID:(NIGeneratorAsynchronousRequestID)requestID;
- (void)_didFinishOperation;
- (void)_cullGeneratedFrameTimes;
- (void)_logFrameRate:(NSTimer *)timer;

@end

@implementation NIGenerator

@synthesize delegate = _delegate;
@synthesize volumeData = _volumeData;

+ (NSOperationQueue *)_synchronousMainThreadRequestQueue
{
    static dispatch_once_t pred;
    static NSOperationQueue *requestQueue = nil;
    dispatch_once(&pred, ^{
        requestQueue = [[NSOperationQueue alloc] init];
        requestQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        [requestQueue setName:@"NIGenerator Synchronous Main Thread Request Queue"];
    });
    return requestQueue;
}


+ (NSOperationQueue *)_userInitiatedRequestQueue
{
    static dispatch_once_t pred;
    static NSOperationQueue *requestQueue = nil;
    dispatch_once(&pred, ^{
        requestQueue = [[NSOperationQueue alloc] init];
        [requestQueue setName:@"NIGenerator User Initiated Request Queue"];
        [requestQueue setQualityOfService:NSQualityOfServiceUserInitiated];
    });
    return requestQueue;
}

+ (NSOperationQueue *)_userInteractiveRequestQueue
{
    static dispatch_once_t pred;
    static NSOperationQueue *requestQueue = nil;
    dispatch_once(&pred, ^{
        requestQueue = [[NSOperationQueue alloc] init];
        if ([requestQueue respondsToSelector:@selector(setQualityOfService:)]) {
            requestQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        }
        [requestQueue setName:@"NIGenerator User Interactive Request Queue"];
    });
    return requestQueue;
}

+ (NSMutableDictionary<NSNumber *, NSOperation *> *)_requestIDs
{
    static dispatch_once_t pred;
    static NSMutableDictionary *requestIDs = nil;
    dispatch_once(&pred, ^{
        requestIDs = [[NSMutableDictionary alloc] init];
    });
    return requestIDs;
}

+ (NIGeneratorAsynchronousRequestID)_generateRequestID
{
    return OSAtomicIncrement64(&requestIDCount);
}

+ (void)_setOperation:(NSOperation *)operation forRequestID:(NIGeneratorAsynchronousRequestID)requestID
{
    NSMutableDictionary<NSNumber *, NSOperation *> *requestIDs = [self _requestIDs];
    @synchronized(requestIDs) {
        [requestIDs setObject:operation forKey:@(requestID)];
    }
}

+ (NSOperation *)_operationForRequestID:(NIGeneratorAsynchronousRequestID)requestID
{
    NSMutableDictionary<NSNumber *, NSOperation *> *requestIDs = [self _requestIDs];
    @synchronized(requestIDs) {
        return [[[requestIDs objectForKey:@(requestID)] retain] autorelease];
    }
}

+ (void)_removeOperationForRequestID:(NIGeneratorAsynchronousRequestID)requestID
{
    NSMutableDictionary<NSNumber *, NSOperation *> *requestIDs = [self _requestIDs];
    @synchronized(requestIDs) {
        [requestIDs removeObjectForKey:@(requestID)];
    }
}


+ (NIVolumeData *)synchronousRequestVolume:(NIGeneratorRequest *)request volumeData:(NIVolumeData *)volumeData
{
    NSAssert(request != nil, @"the generator request can't be nil");
    NSAssert(volumeData != nil, @"the volumeData can't be nil");
    NIGeneratorOperation *operation;
    NSOperationQueue *operationQueue;
    NIVolumeData *generatedVolume;
    
    operation = [[[request operationClass] alloc] initWithRequest:request volumeData:volumeData];
    if ([NSThread isMainThread]) {
        [operation setQualityOfService:NSQualityOfServiceUserInteractive];
        operationQueue = [self _synchronousMainThreadRequestQueue];
    } else {
        [operation setQualityOfService:NSQualityOfServiceUserInitiated];
        operationQueue = [self _userInitiatedRequestQueue];
    }
    [operationQueue addOperations:@[operation] waitUntilFinished:YES];
    generatedVolume = [[operation.generatedVolume retain] autorelease];
    [operation release];
    
    return generatedVolume;
}

+ (NIGeneratorAsynchronousRequestID)asynchronousRequestVolume:(NIGeneratorRequest *)request volumeData:(NIVolumeData *)volumeData completionBlock:(void (^)(NIVolumeData * __nullable))completionBlock
{
    return [self asynchronousRequestVolume:request volumeData:volumeData qualityOfService:NSQualityOfServiceUserInitiated completionBlock:completionBlock];
}

+ (NIGeneratorAsynchronousRequestID)asynchronousRequestVolume:(NIGeneratorRequest *)request volumeData:(NIVolumeData *)volumeData qualityOfService:(NSQualityOfService)qualityOfService completionBlock:(void (^)(NIVolumeData* __nullable generatedVolume))completionBlock;
{
    NSAssert(request != nil, @"the generator request can't be nil");
    NSAssert(volumeData != nil, @"the volumeData request can't be nil");
    NIGeneratorOperation * operation = [[[[request operationClass] alloc] initWithRequest:request volumeData:volumeData] autorelease];
    [operation setQualityOfService:qualityOfService];
    NIGeneratorAsynchronousRequestID requestID = [self _generateRequestID];
    [self _setOperation:operation forRequestID:requestID];
    void (^completionBlockCopy)(NIVolumeData *) = [[completionBlock copy] autorelease];
    [operation setCompletionBlock:^{
        [self _removeOperationForRequestID:requestID];
        completionBlockCopy(operation.generatedVolume);
    }];
    if (qualityOfService == NSQualityOfServiceUserInteractive) {
        [[self _userInteractiveRequestQueue] addOperation:operation];
    } else {
        [[self _userInitiatedRequestQueue] addOperation:operation];
    }

    return requestID;
}

+ (void)cancelAsynchronousRequest:(NIGeneratorAsynchronousRequestID)requestID
{
    NSOperation *operation = [self _operationForRequestID:requestID];
    [operation cancel];
}

+ (void)setPriority:(CGFloat)priority forAsynchronousRequest:(NIGeneratorAsynchronousRequestID)requestID
{
    if (priority > 1) priority = 1;
    if (priority < -1) priority = -1;
    
    NSOperation *operation = [self _operationForRequestID:requestID];
    
    operation.queuePriority = priority * NSOperationQueuePriorityVeryHigh;
}

+ (nullable NIVolumeData *)waitUntilAsynchronousRequestFinished:(NIGeneratorAsynchronousRequestID)requestID {
    NSOperation *rop = [self _operationForRequestID:requestID];
    [rop waitUntilFinished];
    return [(NIGeneratorOperation*)rop generatedVolume];
}

+ (BOOL)isAsynchronousRequestFinished:(NIGeneratorAsynchronousRequestID)requestID {
    NSOperation *rop = [self _operationForRequestID:requestID];
    return !rop || rop.isFinished;
}

- (id)initWithVolumeData:(NIVolumeData *)volumeData
{
	assert([NSThread isMainThread]);

    if ( (self = [super init]) ) {
        _volumeData = [volumeData retain];
        _generatorQueue = [[NSOperationQueue alloc] init];
        _generatorQueue.qualityOfService = NSQualityOfServiceUserInitiated;
        [_generatorQueue setName:@"NIGenerator Request Queue"];

        _observedOperations = [[NSMutableSet alloc] init];
        _finishedOperations = [[NSMutableArray alloc] init];
        _generatedFrameTimes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_volumeData release];
    _volumeData = nil;
    [_generatorQueue release];
    _generatorQueue = nil;
    [_observedOperations release];
    _observedOperations = nil;
    [_finishedOperations release];
    _finishedOperations = nil;
    [_generatedFrameTimes release];
    _generatedFrameTimes = nil;
    [super dealloc];
}

- (void)runUntilAllRequestsAreFinished
{
	assert([NSThread isMainThread]);

	while( [_observedOperations count] > 0) {
		[[NSRunLoop mainRunLoop] runMode:_NIGeneratorRunLoopMode beforeDate:[NSDate distantFuture]];
	}
}

- (void)requestVolume:(NIGeneratorRequest *)request
{
    NIGeneratorOperation *operation;
 
	assert([NSThread isMainThread]);

    for (operation in _observedOperations) {
        if ([operation isExecuting] == NO && [operation isFinished] == NO) {
            [operation cancel];
        }
    }
    
    operation = [[[request operationClass] alloc] initWithRequest:[[request copy] autorelease] volumeData:_volumeData];
    operation.qualityOfService = NSQualityOfServiceUserInitiated;
    [self retain]; // so that the generator can't disappear while the operation is running
    [operation addObserver:self forKeyPath:@"isFinished" options:0 context:&self->_generatorQueue];
    [_observedOperations addObject:operation];
    [_generatorQueue addOperation:operation];
    
    [operation release];
}

- (CGFloat)frameRate
{
	assert([NSThread isMainThread]);

    [self _cullGeneratedFrameTimes];
    return (CGFloat)[_generatedFrameTimes count] / 4.0;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NIGeneratorOperation *generatorOperation;
    if (context == &self->_generatorQueue) {
        assert([object isKindOfClass:[NIGeneratorOperation class]]);
        generatorOperation = (NIGeneratorOperation *)object;
        
        if ([keyPath isEqualToString:@"isFinished"]) {
            if ([object isFinished]) {
                @synchronized (_finishedOperations) {
                    [_finishedOperations addObject:generatorOperation];
                }
                [self performSelectorOnMainThread:@selector(_didFinishOperation) withObject:nil waitUntilDone:NO
											modes:[NSArray arrayWithObjects:NSRunLoopCommonModes, _NIGeneratorRunLoopMode, nil]];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)_didFinishOperation;
{
    NIVolumeData *volumeData;
    NIGeneratorOperation *operation;
    NSArray *finishedOperations;
	NSInteger i;
    BOOL sentGeneratedVolume;
    
	assert([NSThread isMainThread]);

    sentGeneratedVolume = NO;
    
    @synchronized (_finishedOperations) {
        finishedOperations = [_finishedOperations copy];
        [_finishedOperations removeAllObjects];
    }
    
	for (i = [finishedOperations count] - 1; i >= 0; i--) {
		operation = [finishedOperations objectAtIndex:i];
        [operation removeObserver:self forKeyPath:@"isFinished"];
        [self autorelease]; // to match the retain in -[NIGenerator requestVolume:]
        
        volumeData = operation.generatedVolume;
        if (volumeData && [operation isCancelled] == NO && sentGeneratedVolume == NO) {
			[_generatedFrameTimes addObject:[NSDate date]];
			[self _cullGeneratedFrameTimes];
            if ([_delegate respondsToSelector:@selector(generator:didGenerateVolume:request:)]) {
                [_delegate generator:self didGenerateVolume:operation.generatedVolume request:operation.request];
            }
            sentGeneratedVolume = YES;
        } else {
            if ([_delegate respondsToSelector:@selector(generator:didAbandonRequest:)]) {
                [_delegate generator:self didAbandonRequest:operation.request];
            }
        }
        [_observedOperations removeObject:operation];
    }
    
    [finishedOperations release];
}

- (void)_cullGeneratedFrameTimes
{
    BOOL done;
    
	assert([NSThread isMainThread]);

    // remove times that are older than 4 seconds
    done = NO;
    while (!done) {
        if ([_generatedFrameTimes count] && [[_generatedFrameTimes objectAtIndex:0] timeIntervalSinceNow] < -4.0) {
            [_generatedFrameTimes removeObjectAtIndex:0];
        } else {
            done = YES;
        }
    }
}

- (void)_logFrameRate:(NSTimer *)timer
{
    NSLog(@"NIGenerator frame rate: %f", [self frameRate]);
}



@end









