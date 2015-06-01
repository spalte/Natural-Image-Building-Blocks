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

#import "NIBBGenerator.h"
#import "NIBBVolumeData.h"
#import "NIBBGeneratorRequest.h"
#import "NIBBGeneratorOperation.h"

static NSOperationQueue *_synchronousRequestQueue = nil;
NSString * const _NIBBGeneratorRunLoopMode = @"_NIBBGeneratorRunLoopMode";

@interface NIBBGenerator ()

+ (NSOperationQueue *)_synchronousRequestQueue;
- (void)_didFinishOperation;
- (void)_cullGeneratedFrameTimes;
- (void)_logFrameRate:(NSTimer *)timer;

@end


@implementation NIBBGenerator

@synthesize delegate = _delegate;
@synthesize volumeData = _volumeData;

+ (NSOperationQueue *)_synchronousRequestQueue
{
    @synchronized (self) {
        if (_synchronousRequestQueue == nil) {
            _synchronousRequestQueue = [[NSOperationQueue alloc] init];
            
            NSUInteger threads = [[NSProcessInfo processInfo] processorCount];
            if( threads > 2)
                threads = 2;
            
			[_synchronousRequestQueue setMaxConcurrentOperationCount: threads];
        }
    }
    
    return _synchronousRequestQueue;
}



+ (NIBBVolumeData *)synchronousRequestVolume:(NIBBGeneratorRequest *)request volumeData:(NIBBVolumeData *)volumeData
{
    NIBBGeneratorOperation *operation;
    NSOperationQueue *operationQueue;
    NIBBVolumeData *generatedVolume;
    
    operation = [[[request operationClass] alloc] initWithRequest:request volumeData:volumeData];
	[operation setQueuePriority:NSOperationQueuePriorityVeryHigh];
    operationQueue = [self _synchronousRequestQueue];
    [operationQueue addOperation:operation];
    [operationQueue waitUntilAllOperationsAreFinished];
    generatedVolume = [[operation.generatedVolume retain] autorelease];
    [operation release];
    
    return generatedVolume;
}

- (id)initWithVolumeData:(NIBBVolumeData *)volumeData
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
		[[NSRunLoop mainRunLoop] runMode:_NIBBGeneratorRunLoopMode beforeDate:[NSDate distantFuture]];
	}
}

- (void)requestVolume:(NIBBGeneratorRequest *)request
{
    NIBBGeneratorOperation *operation;
 
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
    NIBBGeneratorOperation *generatorOperation;
    if (context == &self->_generatorQueue) {
        assert([object isKindOfClass:[NIBBGeneratorOperation class]]);
        generatorOperation = (NIBBGeneratorOperation *)object;
        
        if ([keyPath isEqualToString:@"isFinished"]) {
            if ([object isFinished]) {
                @synchronized (_finishedOperations) {
                    [_finishedOperations addObject:generatorOperation];
                }
                [self performSelectorOnMainThread:@selector(_didFinishOperation) withObject:nil waitUntilDone:NO
											modes:[NSArray arrayWithObjects:NSRunLoopCommonModes, _NIBBGeneratorRunLoopMode, nil]];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)_didFinishOperation;
{
    NIBBVolumeData *volumeData;
    NIBBGeneratorOperation *operation;
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
        [self autorelease]; // to match the retain in -[NIBBGenerator requestVolume:]
        
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
    NSLog(@"NIBBGenerator frame rate: %f", [self frameRate]);
}

@end













