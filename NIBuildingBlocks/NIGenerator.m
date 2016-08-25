//  Copyright (c) 2016 OsiriX Foundation
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

#import "NIGenerator.h"
#import "NIVolumeData.h"
#import "NIGeneratorRequest.h"
#import "NIGeneratorOperation.h"

NSString * const _NIGeneratorRunLoopMode = @"_NIGeneratorRunLoopMode";

static volatile int64_t requestIDCount __attribute__ ((__aligned__(8))) = 0;

@interface NIGenerator ()

+ (NSOperationQueue *)_asynchronousRequestQueue;
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

+ (NSOperationQueue *)_asynchronousRequestQueue
{
    static dispatch_once_t pred;
    static NSOperationQueue *asynchronousRequestQueue = nil;
    dispatch_once(&pred, ^{
        asynchronousRequestQueue = [[NSOperationQueue alloc] init];
        [asynchronousRequestQueue setMaxConcurrentOperationCount:10];
        [asynchronousRequestQueue setName:@"NIGenerator Asynchronous Request Queue"];
        [asynchronousRequestQueue setQualityOfService:NSQualityOfServiceUserInitiated];
    });
    return asynchronousRequestQueue;
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
    NIGeneratorOperation *operation;
    NSOperationQueue *operationQueue;
    NIVolumeData *generatedVolume;
    
    operation = [[[request operationClass] alloc] initWithRequest:request volumeData:volumeData];
	[operation setQueuePriority:NSOperationQueuePriorityVeryHigh];
    [operation setQualityOfService:NSQualityOfServiceUserInteractive];
//    operationQueue = [self _asynchronousRequestQueue];
    operationQueue = [[NSOperationQueue alloc] init];
    if ([operationQueue respondsToSelector:@selector(setQualityOfService:)])
        operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    [operationQueue addOperations:@[operation] waitUntilFinished:YES];
    generatedVolume = [[operation.generatedVolume retain] autorelease];
    [operation release];
    [operationQueue release];
    
    return generatedVolume;
}

+ (NIGeneratorAsynchronousRequestID)asynchronousRequestVolume:(NIGeneratorRequest *)request volumeData:(NIVolumeData *)volumeData completionBlock:(void (^)(NIVolumeData *))completionBlock
{
    NIGeneratorOperation * operation = [[[[request operationClass] alloc] initWithRequest:request volumeData:volumeData] autorelease];
    [operation setQualityOfService:NSQualityOfServiceUserInitiated];
    NIGeneratorAsynchronousRequestID requestID = [self _generateRequestID];
    [self _setOperation:operation forRequestID:requestID];
    void (^completionBlockCopy)(NIVolumeData *) = [[completionBlock copy] autorelease];
    [operation setCompletionBlock:^{
        [self _removeOperationForRequestID:requestID];
        completionBlockCopy(operation.generatedVolume);
    }];
    [[self _asynchronousRequestQueue] addOperation:operation];

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

+ (void)waitUntilAsynchronousRequestFinished:(NIGeneratorAsynchronousRequestID)requestID {
    NSOperation *rop = [self _operationForRequestID:requestID];
    [rop waitUntilFinished];
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
        
        NSUInteger threads = [[NSProcessInfo processInfo] processorCount];
        if( threads > 2)
            threads = 2;
        
        [_generatorQueue setMaxConcurrentOperationCount: threads];
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
	[operation setQueuePriority:NSOperationQueuePriorityNormal];
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









