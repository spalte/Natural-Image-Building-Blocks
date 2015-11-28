//  Copyright (c) 2015 OsiriX Foundation
//  Copyright (c) 2015 Spaltenstein Natural Image
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

#import "NIObliqueSliceOperation.h"
#import "NIHorizontalFillOperation.h"
#import "NIProjectionOperation.h"
#import "NIGeneratorRequest.h"
#import "NIVolumeData.h"
#include <libkern/OSAtomic.h>


static const NSUInteger FILL_HEIGHT = 40;
static NSOperationQueue *_obliqueSliceOperationFillQueue = nil;

@interface NIObliqueSliceOperation ()

+ (NSOperationQueue *) _fillQueue;
- (CGFloat)_slabSampleDistance;
- (NSUInteger)_pixelsDeep;
- (NIAffineTransform)_generatedModelToVoxelTransform;

@end


@implementation NIObliqueSliceOperation

@dynamic request;

- (id)initWithRequest:(NIObliqueSliceGeneratorRequest *)request volumeData:(NIVolumeData *)volumeData
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
    NIVector origin;
    NIVector leftDirection;
    NIVector downDirection;
    NIVector inSlabNormal;
    NIVector heightOffset;
    NIVector slabOffset;
    NIVectorArray vectors;
    NIVectorArray downVectors;
    NIVectorArray fillVectors;
    NIHorizontalFillOperation *horizontalFillOperation;
    NSMutableSet *fillOperations;
    NSOperationQueue *fillQueue;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    @try {


        if ([self isCancelled] == NO && self.request.pixelsHigh > 0) {
            pixelsWide = self.request.pixelsWide;
            pixelsHigh = self.request.pixelsHigh;
            pixelsDeep = [self _pixelsDeep];
            origin = self.request.origin;
            leftDirection = NIVectorScalarMultiply(NIVectorNormalize(self.request.directionX), self.request.pixelSpacingX);
            downDirection = NIVectorScalarMultiply(NIVectorNormalize(self.request.directionY), self.request.pixelSpacingY);
            if (NIVectorEqualToVector(self.request.directionZ, NIVectorZero)) {
                inSlabNormal = NIVectorScalarMultiply(NIVectorNormalize(NIVectorCrossProduct(leftDirection, downDirection)), [self _slabSampleDistance]);
            } else {
                inSlabNormal = NIVectorScalarMultiply(NIVectorNormalize(self.request.directionZ), [self _slabSampleDistance]);
            }

            _floatBytes = malloc(sizeof(float) * pixelsWide * pixelsHigh * pixelsDeep);
            vectors = malloc(sizeof(NIVector) * pixelsWide);
            fillVectors = malloc(sizeof(NIVector) * pixelsWide);
            downVectors = malloc(sizeof(NIVector) * pixelsWide);

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
                vectors[i] = NIVectorAdd(origin, NIVectorScalarMultiply(leftDirection, (CGFloat)i));
                downVectors[i] = downDirection;
            }


            fillOperations = [NSMutableSet set];

            for (z = 0; z < pixelsDeep; z++) {
                slabOffset = NIVectorScalarMultiply(inSlabNormal, (CGFloat)z - (CGFloat)(pixelsDeep - 1)/2.0);
                for (y = 0; y < pixelsHigh; y += FILL_HEIGHT) {
                    heightOffset = NIVectorScalarMultiply(downDirection, (CGFloat)y);
                    for (i = 0; i < pixelsWide; i++) {
                        fillVectors[i] = NIVectorAdd(NIVectorAdd(vectors[i], heightOffset), slabOffset);
                    }

                    horizontalFillOperation = [[NIHorizontalFillOperation alloc] initWithVolumeData:_volumeData interpolationMode:self.request.interpolationMode floatBytes:_floatBytes + (y*pixelsWide) + (z*pixelsWide*pixelsHigh) width:pixelsWide height:MIN(FILL_HEIGHT, pixelsHigh - y)
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
    NIVolumeData *generatedVolume;
    NIAffineTransform modelToVoxelTransform;
    NIProjectionOperation *projectionOperation;
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
                    modelToVoxelTransform = [self _generatedModelToVoxelTransform];
                    generatedVolume = [[NIVolumeData alloc] initWithBytesNoCopy:_floatBytes pixelsWide:self.request.pixelsWide pixelsHigh:self.request.pixelsHigh pixelsDeep:[self _pixelsDeep]
                                                                modelToVoxelTransform:modelToVoxelTransform outOfBoundsValue:_volumeData.outOfBoundsValue freeWhenDone:YES];
                    _floatBytes = NULL;
                    projectionOperation = [[NIProjectionOperation alloc] init];
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
                    assert([operation isKindOfClass:[NIProjectionOperation class]]);
                    projectionOperation = (NIProjectionOperation *)operation;
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
#if CGFLOAT_IS_DOUBLE
    return MAX(round(self.request.slabWidth / [self _slabSampleDistance]), 0) + 1;
#else
    return MAX(roundf(self.request.slabWidth / [self _slabSampleDistance]), 0) + 1;
#endif
}

- (NIAffineTransform)_generatedModelToVoxelTransform
{
    NIAffineTransform modelToVoxelTransform;
    NIVector leftDirection;
    NIVector downDirection;
    NIVector inSlabNormal;
    NIVector volumeOrigin;

    leftDirection = NIVectorScalarMultiply(NIVectorNormalize(self.request.directionX), self.request.pixelSpacingX);
    downDirection = NIVectorScalarMultiply(NIVectorNormalize(self.request.directionY), self.request.pixelSpacingY);
    if (NIVectorEqualToVector(self.request.directionZ, NIVectorZero)) {
        inSlabNormal = NIVectorScalarMultiply(NIVectorNormalize(NIVectorCrossProduct(leftDirection, downDirection)), [self _slabSampleDistance]);
    } else {
        inSlabNormal = NIVectorScalarMultiply(NIVectorNormalize(self.request.directionZ), [self _slabSampleDistance]);
    }

    volumeOrigin = NIVectorAdd(self.request.origin, NIVectorScalarMultiply(inSlabNormal, (CGFloat)([self _pixelsDeep] - 1)/-2.0));

    modelToVoxelTransform = NIAffineTransformIdentity;
    modelToVoxelTransform.m41 = volumeOrigin.x;
    modelToVoxelTransform.m42 = volumeOrigin.y;
    modelToVoxelTransform.m43 = volumeOrigin.z;
    modelToVoxelTransform.m11 = leftDirection.x;
    modelToVoxelTransform.m12 = leftDirection.y;
    modelToVoxelTransform.m13 = leftDirection.z;
    modelToVoxelTransform.m21 = downDirection.x;
    modelToVoxelTransform.m22 = downDirection.y;
    modelToVoxelTransform.m23 = downDirection.z;
    modelToVoxelTransform.m31 = inSlabNormal.x;
    modelToVoxelTransform.m32 = inSlabNormal.y;
    modelToVoxelTransform.m33 = inSlabNormal.z;
    modelToVoxelTransform = NIAffineTransformInvert(modelToVoxelTransform);
    
    return modelToVoxelTransform;
}

@end































