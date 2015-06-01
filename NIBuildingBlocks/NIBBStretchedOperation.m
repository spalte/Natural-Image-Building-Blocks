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

#import "NIBBStretchedOperation.h"
#import "NIBBGeneratorRequest.h"
#import "NIBBGeometry.h"
#import "NIBBBezierCore.h"
#import "NIBBBezierCoreAdditions.h"
#import "NIBBBezierPath.h"
#import "NIBBVolumeData.h"
#import "NIBBHorizontalFillOperation.h"
#import "NIBBProjectionOperation.h"
#include <libkern/OSAtomic.h>

static const NSUInteger FILL_HEIGHT = 40;
static NSOperationQueue *_stretchedOperationFillQueue = nil;

@interface NIBBStretchedOperation ()

+ (NSOperationQueue *) _fillQueue;
- (CGFloat)_slabSampleDistance;
- (NSUInteger)_pixelsDeep;

@end

@implementation NIBBStretchedOperation

@dynamic request;

- (id)initWithRequest:(NIBBStretchedGeneratorRequest *)request volumeData:(NIBBVolumeData *)volumeData
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
    CGFloat bezierLength;
    CGFloat projectedBezierLength;
    CGFloat fillDistance;
    CGFloat slabDistance;
    NSInteger numVectors;
    NSInteger i;
    NSInteger y;
    NSInteger z;
    NSInteger pixelsWide;
    NSInteger pixelsHigh;
    NSInteger pixelsDeep;
    NIBBVector projectionNormal;
    NIBBVector midHeightPoint;
    NIBBVectorArray vectors;
    NIBBVectorArray fillVectors;
    NIBBVectorArray fillNormals;
    NIBBVectorArray normals;
    NIBBVectorArray tangents;
    NIBBVectorArray inSlabNormals;
    NIBBMutableBezierCoreRef flattenedBezierCore;
    NIBBMutableBezierCoreRef projectedBezierCore;
    NIBBHorizontalFillOperation *horizontalFillOperation;
    NSMutableSet *fillOperations;
	NSOperationQueue *fillQueue;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    @try {
        if ([self isCancelled] == NO && self.request.pixelsHigh > 0) {        
            flattenedBezierCore = NIBBBezierCoreCreateMutableCopy([self.request.bezierPath NIBBBezierCore]);
            NIBBBezierCoreSubdivide(flattenedBezierCore, 3.0);
            NIBBBezierCoreFlatten(flattenedBezierCore, 0.6);
            bezierLength = NIBBBezierCoreLength(flattenedBezierCore);
            pixelsWide = self.request.pixelsWide;
            pixelsHigh = self.request.pixelsHigh;
            pixelsDeep = [self _pixelsDeep];
            projectionNormal = self.request.projectionNormal;
            midHeightPoint = self.request.midHeightPoint;
            projectedBezierCore = NIBBBezierCoreCreateMutableCopyProjectedToPlane(flattenedBezierCore, NIBBPlaneMake(NIBBVectorZero, projectionNormal));
            projectedBezierLength = NIBBBezierCoreLength(projectedBezierCore);
            numVectors = pixelsWide;
            _sampleSpacing = projectedBezierLength / (CGFloat)pixelsWide;
            
            _floatBytes = malloc(sizeof(float) * pixelsWide * pixelsHigh * pixelsDeep);
            vectors = malloc(sizeof(NIBBVector) * pixelsWide);
            fillVectors = malloc(sizeof(NIBBVector) * pixelsWide);
            fillNormals = malloc(sizeof(NIBBVector) * pixelsWide);
            tangents = malloc(sizeof(NIBBVector) * pixelsWide);
            normals = malloc(sizeof(NIBBVector) * pixelsWide);
            inSlabNormals = malloc(sizeof(NIBBVector) * pixelsWide);
            
            if (_floatBytes == NULL || vectors == NULL || fillVectors == NULL || fillNormals == NULL || tangents == NULL || normals == NULL || inSlabNormals == NULL) {
                free(_floatBytes);
                free(vectors);
                free(fillVectors);
                free(fillNormals);
                free(tangents);
                free(normals);
                free(inSlabNormals);
                
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
                
                NIBBBezierCoreRelease(flattenedBezierCore);
                NIBBBezierCoreRelease(projectedBezierCore);
                return;
            }
            
            numVectors = NIBBBezierCoreGetProjectedVectorInfo(flattenedBezierCore, _sampleSpacing, 0, self.request.projectionNormal, vectors, tangents, normals, NULL, pixelsWide);
            
            if (numVectors > 0) {
                while (numVectors < pixelsWide) { // make sure that the full array is filled and that there is not a vector that did not get filled due to roundoff error
                    vectors[numVectors] = vectors[numVectors - 1];
                    tangents[numVectors] = tangents[numVectors - 1];
                    normals[numVectors] = normals[numVectors - 1];
                    numVectors++;
                }
            } else { // there are no vectors at all to copy from, so just zero out everthing
                while (numVectors < pixelsWide) { // make sure that the full array is filled and that there is not a vector that did not get filled due to roundoff error
                    vectors[numVectors] = NIBBVectorZero;
                    tangents[numVectors] = NIBBVectorZero;
                    normals[numVectors] = NIBBVectorZero;
                    numVectors++;
                }
            }
            
            NIBBPlane topPlane;
            topPlane = NIBBPlaneMake(NIBBVectorAdd(NIBBVectorScalarMultiply(NIBBVectorNormalize(projectionNormal), _sampleSpacing*pixelsHigh*.5), midHeightPoint), projectionNormal);
            for (i = 0; i < numVectors; i++) { // this implementation is a bit of a hack, just put the values that the straightened NIBB would want, and use code copied from straightened NIBB
                vectors[i] = NIBBLineIntersectionWithPlane(NIBBLineMake(vectors[i], projectionNormal), NIBBPlaneMake(midHeightPoint, projectionNormal));
//                vectors[i] = NIBBLineIntersectionWithPlane(NIBBLineMake(vectors[i], projectionNormal), topPlane);
                tangents[i] = NIBBVectorNormalize(NIBBVectorCrossProduct(normals[i], projectionNormal));
                normals[i] = NIBBVectorNormalize(projectionNormal);
            }
            
            memcpy(fillNormals, normals, sizeof(NIBBVector) * pixelsWide);
            NIBBVectorScalarMultiplyVectors(_sampleSpacing, fillNormals, pixelsWide);
            
            memcpy(inSlabNormals, normals, sizeof(NIBBVector) * pixelsWide);
            NIBBVectorCrossProductWithVectors(inSlabNormals, tangents, pixelsWide);
            NIBBVectorScalarMultiplyVectors([self _slabSampleDistance], inSlabNormals, pixelsWide);
            
            fillOperations = [NSMutableSet set];
            
            for (z = 0; z < pixelsDeep; z++) {
                for (y = 0; y < pixelsHigh; y += FILL_HEIGHT) {
                    fillDistance = (CGFloat)y - (CGFloat)(pixelsHigh - 1)/2.0; // the distance to go out from the centerline
                    slabDistance = (CGFloat)z - (CGFloat)(pixelsDeep - 1)/2.0; // the distance to go out from the centerline
                    for (i = 0; i < pixelsWide; i++) {
                        fillVectors[i] = NIBBVectorAdd(NIBBVectorAdd(vectors[i], NIBBVectorScalarMultiply(fillNormals[i], fillDistance)), NIBBVectorScalarMultiply(inSlabNormals[i], slabDistance));
                    }
                    
                    horizontalFillOperation = [[NIBBHorizontalFillOperation alloc] initWithVolumeData:_volumeData interpolationMode:self.request.interpolationMode floatBytes:_floatBytes + (y*pixelsWide) + (z*pixelsWide*pixelsHigh) width:pixelsWide height:MIN(FILL_HEIGHT, pixelsHigh - y)
                                                                                             vectors:fillVectors normals:fillNormals];
                    [horizontalFillOperation setQueuePriority:[self queuePriority]];
					[fillOperations addObject:horizontalFillOperation];
                    [horizontalFillOperation addObserver:self forKeyPath:@"isFinished" options:0 context:&self->_fillOperations];
                    [self retain]; // so we don't get released while the operation is going
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
            
            _outstandingFillOperationCount = (int32_t)[fillOperations count];
            
			fillQueue = [[self class] _fillQueue];
			for (horizontalFillOperation in fillOperations) {
				[fillQueue addOperation:horizontalFillOperation];
			}
			
			free(vectors);
            free(fillVectors);
            free(fillNormals);
            free(tangents);
            free(normals);
            free(inSlabNormals);
            NIBBBezierCoreRelease(flattenedBezierCore);
            NIBBBezierCoreRelease(projectedBezierCore);
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
                oustandingFillOperationCount = OSAtomicDecrement32Barrier(&_outstandingFillOperationCount);
                if (oustandingFillOperationCount == 0) { // done with the fill operations, now do the projection
                    volumeTransform = NIBBAffineTransformMakeScale(1.0/_sampleSpacing, 1.0/_sampleSpacing, 1.0/[self _slabSampleDistance]);
                    generatedVolume = [[NIBBVolumeData alloc] initWithBytesNoCopy:_floatBytes pixelsWide:self.request.pixelsWide pixelsHigh:self.request.pixelsHigh pixelsDeep:[self _pixelsDeep]
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

+ (NSOperationQueue *)_fillQueue
{
    @synchronized (self) {
        if (_stretchedOperationFillQueue == nil) {
            _stretchedOperationFillQueue = [[NSOperationQueue alloc] init];
			[_stretchedOperationFillQueue setMaxConcurrentOperationCount:[[NSProcessInfo processInfo] processorCount]];
        }
    }
    
    return _stretchedOperationFillQueue;
}

- (CGFloat)_slabSampleDistance
{
    if (self.request.slabSampleDistance != 0.0) {
        return self.request.slabSampleDistance;
    } else {
        return self.volumeData.minPixelSpacing; // this should be /2.0 to hit nyquist spacing, but it is too slow, and with this implementation to memory intensive
    }
}

- (NSUInteger)_pixelsDeep
{
    return MAX(self.request.slabWidth / [self _slabSampleDistance], 0) + 1;
}



@end




















