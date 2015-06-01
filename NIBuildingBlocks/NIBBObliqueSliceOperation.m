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

#import "NIBBObliqueSliceOperation.h"
#import "NIBBHorizontalFillOperation.h"
#import "NIBBProjectionOperation.h"
#import "NIBBGeneratorRequest.h"
#import "NIBBVolumeData.h"
#include <libkern/OSAtomic.h>


static const NSUInteger FILL_HEIGHT = 40;
static NSOperationQueue *_obliqueSliceOperationFillQueue = nil;

@interface NIBBObliqueSliceOperation ()

+ (NSOperationQueue *) _fillQueue;
- (CGFloat)_slabSampleDistance;
- (NSUInteger)_pixelsDeep;
- (NIBBAffineTransform)_generatedVolumeTransform;

@end


@implementation NIBBObliqueSliceOperation

@dynamic request;

- (id)initWithRequest:(NIBBObliqueSliceGeneratorRequest *)request volumeData:(NIBBVolumeData *)volumeData
{
    if ( (self = [super initWithRequest:request volumeData:volumeData]) ) {
        _fillOperations = [[NSMutableSet alloc] init];
        
    }
    return self;
}

- (void)dealloc
{
    [_fillOperations release];
    _fillOperations = nil;
    [_projectionOperation release];
	_projectionOperation = nil;
    [super dealloc];
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting {
    return _operationExecuting;
}

- (BOOL)isFinished {
    return _operationFinished;
}

- (BOOL)didFail
{
    return _operationFailed;
}

- (void)cancel
{
    NSOperation *operation;
    @synchronized (_fillOperations) {
        for (operation in _fillOperations) {
            [operation cancel];
        }
    }
    [_projectionOperation cancel];
    
    [super cancel];
}

- (void)start
{
    if ([self isCancelled])
    {
        [self willChangeValueForKey:@"isFinished"];
        _operationFinished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    _operationExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self main];
}

- (void)main
{
    NSInteger i;
    NSInteger y;
    NSInteger z;
    NSInteger pixelsWide;
    NSInteger pixelsHigh;
    NSInteger pixelsDeep;
    NIBBVector origin;
    NIBBVector leftDirection;
    NIBBVector downDirection;
    NIBBVector inSlabNormal;
    NIBBVector heightOffset;
    NIBBVector slabOffset;
    NIBBVectorArray vectors;
    NIBBVectorArray downVectors;
    NIBBVectorArray fillVectors;
    NIBBHorizontalFillOperation *horizontalFillOperation;
    NSMutableSet *fillOperations;
	NSOperationQueue *fillQueue;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    @try {
        
        
        if ([self isCancelled] == NO && self.request.pixelsHigh > 0) {        
            pixelsWide = self.request.pixelsWide;
            pixelsHigh = self.request.pixelsHigh;
            pixelsDeep = [self _pixelsDeep];
            origin = self.request.origin;
            leftDirection = NIBBVectorScalarMultiply(NIBBVectorNormalize(self.request.directionX), self.request.pixelSpacingX);
            downDirection = NIBBVectorScalarMultiply(NIBBVectorNormalize(self.request.directionY), self.request.pixelSpacingY);
            inSlabNormal = NIBBVectorScalarMultiply(NIBBVectorNormalize(NIBBVectorCrossProduct(leftDirection, downDirection)), [self _slabSampleDistance]);
                        
            _floatBytes = malloc(sizeof(float) * pixelsWide * pixelsHigh * pixelsDeep);
            vectors = malloc(sizeof(NIBBVector) * pixelsWide);
            fillVectors = malloc(sizeof(NIBBVector) * pixelsWide);
            downVectors = malloc(sizeof(NIBBVector) * pixelsWide);
            
            if (_floatBytes == NULL || vectors == NULL || fillVectors == NULL || downVectors == NULL) {
                free(_floatBytes);
                free(vectors);
                free(fillVectors);
                free(downVectors);
                
                _floatBytes = NULL;
                
                [self willChangeValueForKey:@"didFail"];
                [self willChangeValueForKey:@"isFinished"];
                [self willChangeValueForKey:@"isExecuting"];
                _operationExecuting = NO;
                _operationFinished = YES;
                _operationFailed = YES;
                [self didChangeValueForKey:@"isExecuting"];
                [self didChangeValueForKey:@"isFinished"];
                [self didChangeValueForKey:@"didFail"];
                
                return;
            }
            
            for (i = 0; i < pixelsWide; i++) {
                vectors[i] = NIBBVectorAdd(origin, NIBBVectorScalarMultiply(leftDirection, (CGFloat)i));
                downVectors[i] = downDirection;
            }
            
                        
            fillOperations = [NSMutableSet set];
            
            for (z = 0; z < pixelsDeep; z++) {
                slabOffset = NIBBVectorScalarMultiply(inSlabNormal, (CGFloat)z - (CGFloat)(pixelsDeep - 1)/2.0);
                for (y = 0; y < pixelsHigh; y += FILL_HEIGHT) {
                    heightOffset = NIBBVectorScalarMultiply(downDirection, (CGFloat)y);
                    for (i = 0; i < pixelsWide; i++) {
                        fillVectors[i] = NIBBVectorAdd(NIBBVectorAdd(vectors[i], heightOffset), slabOffset);
                    }
                    
                    horizontalFillOperation = [[NIBBHorizontalFillOperation alloc] initWithVolumeData:_volumeData interpolationMode:self.request.interpolationMode floatBytes:_floatBytes + (y*pixelsWide) + (z*pixelsWide*pixelsHigh) width:pixelsWide height:MIN(FILL_HEIGHT, pixelsHigh - y)
                                                                                             vectors:fillVectors normals:downVectors];
                    [horizontalFillOperation setQueuePriority:[self queuePriority]];
					[fillOperations addObject:horizontalFillOperation];
                    [horizontalFillOperation addObserver:self forKeyPath:@"isFinished" options:0 context:&self->_fillOperations];
                    [self retain]; // so we don't get release while the operation is going
                    [horizontalFillOperation release];
                }
            }
            
            @synchronized (_fillOperations) {
                [_fillOperations setSet:fillOperations];
            }            
            
            if ([self isCancelled]) {
                for (horizontalFillOperation in fillOperations) {
                    [horizontalFillOperation cancel];
                }                
            }
            
            _oustandingFillOperationCount = (int32_t)[fillOperations count];
            
			fillQueue = [[self class] _fillQueue];
			for (horizontalFillOperation in fillOperations) {
				[fillQueue addOperation:horizontalFillOperation];
			}
			
			free(vectors);
            free(fillVectors);
            free(downVectors);
        } else {
            [self willChangeValueForKey:@"isFinished"];
            [self willChangeValueForKey:@"isExecuting"];
            _operationExecuting = NO;
            _operationFinished = YES;
            [self didChangeValueForKey:@"isExecuting"];
            [self didChangeValueForKey:@"isFinished"];
            return;
        }
    }
    @catch (...) {
        [self willChangeValueForKey:@"isFinished"];
        [self willChangeValueForKey:@"isExecuting"];
        _operationExecuting = NO;
        _operationFinished = YES;
        [self didChangeValueForKey:@"isExecuting"];
        [self didChangeValueForKey:@"isFinished"];
    }
    @finally {
        [pool release];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSOperation *operation;
    NIBBVolumeData *generatedVolume;
    NIBBAffineTransform volumeTransform;
    NIBBProjectionOperation *projectionOperation;
    int32_t oustandingFillOperationCount;
    
    if (context == &self->_fillOperations) {
        assert([object isKindOfClass:[NSOperation class]]);
        operation = (NSOperation *)object;
        
        if ([keyPath isEqualToString:@"isFinished"]) {
            if ([operation isFinished]) {
                [operation removeObserver:self forKeyPath:@"isFinished"];
                [self autorelease]; // to balance the retain when we observe operations
                oustandingFillOperationCount = OSAtomicDecrement32Barrier(&_oustandingFillOperationCount);
                if (oustandingFillOperationCount == 0) { // done with the fill operations, now do the projection
                    volumeTransform = [self _generatedVolumeTransform];
                    generatedVolume = [[NIBBVolumeData alloc] initWithFloatBytesNoCopy:_floatBytes pixelsWide:self.request.pixelsWide pixelsHigh:self.request.pixelsHigh pixelsDeep:[self _pixelsDeep]
                                                                      volumeTransform:volumeTransform outOfBoundsValue:_volumeData.outOfBoundsValue freeWhenDone:YES];
                    _floatBytes = NULL;
                    projectionOperation = [[NIBBProjectionOperation alloc] init];
					[projectionOperation setQueuePriority:[self queuePriority]];
					
                    projectionOperation.volumeData = generatedVolume;
                    projectionOperation.projectionMode = self.request.projectionMode;
					if ([self isCancelled]) {
						[projectionOperation cancel];
					}
                    
                    [generatedVolume release];
                    [projectionOperation addObserver:self forKeyPath:@"isFinished" options:0 context:&self->_fillOperations];
                    [self retain]; // so we don't get released while the operation is going
                    _projectionOperation = projectionOperation;
                    [[[self class] _fillQueue] addOperation:projectionOperation];
                } else if (oustandingFillOperationCount == -1) {
                    assert([operation isKindOfClass:[NIBBProjectionOperation class]]);
                    projectionOperation = (NIBBProjectionOperation *)operation;
                    self.generatedVolume = projectionOperation.generatedVolume;
                    
                    [self willChangeValueForKey:@"isFinished"];
                    [self willChangeValueForKey:@"isExecuting"];
                    _operationExecuting = NO;
                    _operationFinished = YES;
                    [self didChangeValueForKey:@"isExecuting"];
                    [self didChangeValueForKey:@"isFinished"];
                }
                
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

+ (NSOperationQueue *) _fillQueue
{
    @synchronized (self) {
        if (_obliqueSliceOperationFillQueue == nil) {
            _obliqueSliceOperationFillQueue = [[NSOperationQueue alloc] init];
			[_obliqueSliceOperationFillQueue setMaxConcurrentOperationCount:[[NSProcessInfo processInfo] processorCount]];
        }
    }
    
    return _obliqueSliceOperationFillQueue;
}

- (CGFloat)_slabSampleDistance
{
    if (self.request.slabSampleDistance != 0.0) {
        return self.request.slabSampleDistance;
    } else {
        return self.volumeData.minPixelSpacing;
    }
}

- (NSUInteger)_pixelsDeep
{
    return MAX(self.request.slabWidth / [self _slabSampleDistance], 0) + 1;
}

- (NIBBAffineTransform)_generatedVolumeTransform
{
    NIBBAffineTransform volumeTransform;
    NIBBVector leftDirection;
    NIBBVector downDirection;
    NIBBVector inSlabNormal;
    NIBBVector volumeOrigin;
    
    leftDirection = NIBBVectorScalarMultiply(NIBBVectorNormalize(self.request.directionX), self.request.pixelSpacingX);
    downDirection = NIBBVectorScalarMultiply(NIBBVectorNormalize(self.request.directionY), self.request.pixelSpacingY);
    inSlabNormal = NIBBVectorScalarMultiply(NIBBVectorNormalize(NIBBVectorCrossProduct(leftDirection, downDirection)), [self _slabSampleDistance]);
    
    volumeOrigin = NIBBVectorAdd(self.request.origin, NIBBVectorScalarMultiply(inSlabNormal, (CGFloat)([self _pixelsDeep] - 1)/-2.0));
    
    volumeTransform = NIBBAffineTransformIdentity;
    volumeTransform.m41 = volumeOrigin.x;
    volumeTransform.m42 = volumeOrigin.y;
    volumeTransform.m43 = volumeOrigin.z;
    volumeTransform.m11 = leftDirection.x;
    volumeTransform.m12 = leftDirection.y;
    volumeTransform.m13 = leftDirection.z;
    volumeTransform.m21 = downDirection.x;
    volumeTransform.m22 = downDirection.y;
    volumeTransform.m23 = downDirection.z;
    volumeTransform.m31 = inSlabNormal.x;
    volumeTransform.m32 = inSlabNormal.y;
    volumeTransform.m33 = inSlabNormal.z;
    
    volumeTransform = NIBBAffineTransformInvert(volumeTransform);
    return volumeTransform;
}

@end































