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

#import "NIBBHorizontalFillOperation.h"
#import "NIBBVolumeData.h"
#import "NIBBGeometry.h"

@interface NIBBHorizontalFillOperation ()

- (void)_nearestNeighborFill;
- (void)_linearInterpolatingFill;
- (void)_cubicInterpolatingFill;
- (void)_unknownInterpolatingFill;

@end


@implementation NIBBHorizontalFillOperation

@synthesize volumeData = _volumeData;
@synthesize width = _width;
@synthesize height = _height;
@synthesize floatBytes = _floatBytes;
@synthesize vectors = _vectors;
@synthesize normals = _normals;
@synthesize interpolationMode = _interpolationMode;

- (id)initWithVolumeData:(NIBBVolumeData *)volumeData interpolationMode:(NIBBInterpolationMode)interpolationMode floatBytes:(float *)floatBytes width:(NSUInteger)width height:(NSUInteger)height vectors:(NIBBVectorArray)vectors normals:(NIBBVectorArray)normals
{
    if ( (self = [super init])) {
        _volumeData = [volumeData retain];
        _floatBytes = floatBytes;
        _width = width;
        _height = height;
        _vectors = malloc(width * sizeof(NIBBVector));
        memcpy(_vectors, vectors, width * sizeof(NIBBVector));
        _normals = malloc(width * sizeof(NIBBVector));
        memcpy(_normals, normals, width * sizeof(NIBBVector));
        _interpolationMode = interpolationMode;
    }
    return self;
}

- (void)dealloc
{
    [_volumeData release];
    _volumeData = nil;
    free(_vectors);
    _vectors = NULL;
    free(_normals);
    _normals = NULL;
    [super dealloc];
}

- (void)main
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    double threadPriority;

    @try {
        if ([self isCancelled]) {
            return;
        }

        threadPriority = [NSThread threadPriority];
        [NSThread setThreadPriority:threadPriority * .5];

        if (_interpolationMode == NIBBInterpolationModeLinear) {
            [self _linearInterpolatingFill];
        } else if (_interpolationMode == NIBBInterpolationModeNearestNeighbor) {
            [self _nearestNeighborFill];
        } else if (_interpolationMode == NIBBInterpolationModeCubic) {
            [self _cubicInterpolatingFill];
        } else {
            [self _unknownInterpolatingFill];
        }

        [NSThread setThreadPriority:threadPriority];
    }
    @catch (...) {
    }
    @finally {
        [pool release];
    }
}

- (void)_linearInterpolatingFill
{
    NSUInteger x;
    NSUInteger y;
    NIBBAffineTransform vectorTransform;
    NIBBVectorArray volumeVectors;
    NIBBVectorArray volumeNormals;
    NIBBVolumeDataInlineBuffer inlineBuffer;

    volumeVectors = malloc(_width * sizeof(NIBBVector));
    memcpy(volumeVectors, _vectors, _width * sizeof(NIBBVector));
    NIBBVectorApplyTransformToVectors(_volumeData.volumeTransform, volumeVectors, _width);

    volumeNormals = malloc(_width * sizeof(NIBBVector));
    memcpy(volumeNormals, _normals, _width * sizeof(NIBBVector));
    vectorTransform = _volumeData.volumeTransform;
    vectorTransform.m41 = vectorTransform.m42 = vectorTransform.m43 = 0.0;
    NIBBVectorApplyTransformToVectors(vectorTransform, volumeNormals, _width);

    [_volumeData aquireInlineBuffer:&inlineBuffer];
    for (y = 0; y < _height; y++) {
        if ([self isCancelled]) {
            break;
        }

        for (x = 0; x < _width; x++) {
            _floatBytes[y*_width + x] = NIBBVolumeDataLinearInterpolatedFloatAtVolumeVector(&inlineBuffer, volumeVectors[x]);
        }

        NIBBVectorAddVectors(volumeVectors, volumeNormals, _width);
    }

    free(volumeVectors);
    free(volumeNormals);
}

- (void)_nearestNeighborFill
{
    NSUInteger x;
    NSUInteger y;
    NIBBAffineTransform vectorTransform;
    NIBBVectorArray volumeVectors;
    NIBBVectorArray volumeNormals;
    NIBBVolumeDataInlineBuffer inlineBuffer;

    volumeVectors = malloc(_width * sizeof(NIBBVector));
    memcpy(volumeVectors, _vectors, _width * sizeof(NIBBVector));
    NIBBVectorApplyTransformToVectors(_volumeData.volumeTransform, volumeVectors, _width);

    volumeNormals = malloc(_width * sizeof(NIBBVector));
    memcpy(volumeNormals, _normals, _width * sizeof(NIBBVector));
    vectorTransform = _volumeData.volumeTransform;
    vectorTransform.m41 = vectorTransform.m42 = vectorTransform.m43 = 0.0;
    NIBBVectorApplyTransformToVectors(vectorTransform, volumeNormals, _width);

    [_volumeData aquireInlineBuffer:&inlineBuffer];
    for (y = 0; y < _height; y++) {
        if ([self isCancelled]) {
            break;
        }

        for (x = 0; x < _width; x++) {
            _floatBytes[y*_width + x] = NIBBVolumeDataNearestNeighborInterpolatedFloatAtVolumeVector(&inlineBuffer, volumeVectors[x]);
        }

        NIBBVectorAddVectors(volumeVectors, volumeNormals, _width);
    }

    free(volumeVectors);
    free(volumeNormals);
}

- (void)_cubicInterpolatingFill
{
    NSUInteger x;
    NSUInteger y;
    NIBBAffineTransform vectorTransform;
    NIBBVectorArray volumeVectors;
    NIBBVectorArray volumeNormals;
    NIBBVolumeDataInlineBuffer inlineBuffer;

    volumeVectors = malloc(_width * sizeof(NIBBVector));
    memcpy(volumeVectors, _vectors, _width * sizeof(NIBBVector));
    NIBBVectorApplyTransformToVectors(_volumeData.volumeTransform, volumeVectors, _width);

    volumeNormals = malloc(_width * sizeof(NIBBVector));
    memcpy(volumeNormals, _normals, _width * sizeof(NIBBVector));
    vectorTransform = _volumeData.volumeTransform;
    vectorTransform.m41 = vectorTransform.m42 = vectorTransform.m43 = 0.0;
    NIBBVectorApplyTransformToVectors(vectorTransform, volumeNormals, _width);

    [_volumeData aquireInlineBuffer:&inlineBuffer];
    for (y = 0; y < _height; y++) {
        if ([self isCancelled]) {
            break;
        }

        for (x = 0; x < _width; x++) {
            _floatBytes[y*_width + x] = NIBBVolumeDataCubicInterpolatedFloatAtVolumeVector(&inlineBuffer, volumeVectors[x]);
        }

        NIBBVectorAddVectors(volumeVectors, volumeNormals, _width);
    }

    free(volumeVectors);
    free(volumeNormals);
}


- (void)_unknownInterpolatingFill
{
    NSLog(@"unknown interpolation mode");
    memset(_floatBytes, 0, _height * _width);
}


@end
