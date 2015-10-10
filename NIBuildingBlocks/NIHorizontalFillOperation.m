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

#import "NIHorizontalFillOperation.h"
#import "NIVolumeData.h"
#import "NIGeometry.h"

@interface NIHorizontalFillOperation ()

- (void)_nearestNeighborFill;
- (void)_linearInterpolatingFill;
- (void)_cubicInterpolatingFill;
- (void)_unknownInterpolatingFill;

@end


@implementation NIHorizontalFillOperation

@synthesize volumeData = _volumeData;
@synthesize width = _width;
@synthesize height = _height;
@synthesize floatBytes = _floatBytes;
@synthesize vectors = _vectors;
@synthesize normals = _normals;
@synthesize interpolationMode = _interpolationMode;

- (id)initWithVolumeData:(NIVolumeData *)volumeData interpolationMode:(NIInterpolationMode)interpolationMode floatBytes:(float *)floatBytes width:(NSUInteger)width height:(NSUInteger)height vectors:(NIVectorArray)vectors normals:(NIVectorArray)normals
{
    if ( (self = [super init])) {
        _volumeData = [volumeData retain];
        _floatBytes = floatBytes;
        _width = width;
        _height = height;
        _vectors = malloc(width * sizeof(NIVector));
        memcpy(_vectors, vectors, width * sizeof(NIVector));
        _normals = malloc(width * sizeof(NIVector));
        memcpy(_normals, normals, width * sizeof(NIVector));
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

    NSAssert([_volumeData isCurved] == NO, @"NIHorizontalFillOperation only works with volumes that are not curved");

    @try {
        if ([self isCancelled]) {
            return;
        }

        threadPriority = [NSThread threadPriority];
        [NSThread setThreadPriority:threadPriority * .5];

        if (_interpolationMode == NIInterpolationModeLinear) {
            [self _linearInterpolatingFill];
        } else if (_interpolationMode == NIInterpolationModeNearestNeighbor) {
            [self _nearestNeighborFill];
        } else if (_interpolationMode == NIInterpolationModeCubic) {
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
    NIAffineTransform vectorTransform;
    NIVectorArray volumeVectors;
    NIVectorArray volumeNormals;
    NIVolumeDataInlineBuffer inlineBuffer;

    volumeVectors = malloc(_width * sizeof(NIVector));
    memcpy(volumeVectors, _vectors, _width * sizeof(NIVector));
    NIVectorApplyTransformToVectors(_volumeData.volumeTransform, volumeVectors, _width);

    volumeNormals = malloc(_width * sizeof(NIVector));
    memcpy(volumeNormals, _normals, _width * sizeof(NIVector));
    vectorTransform = _volumeData.volumeTransform;
    vectorTransform.m41 = vectorTransform.m42 = vectorTransform.m43 = 0.0;
    NIVectorApplyTransformToVectors(vectorTransform, volumeNormals, _width);

    [_volumeData aquireInlineBuffer:&inlineBuffer];
    for (y = 0; y < _height; y++) {
        if ([self isCancelled]) {
            break;
        }

        for (x = 0; x < _width; x++) {
            _floatBytes[y*_width + x] = NIVolumeDataLinearInterpolatedFloatAtVolumeVector(&inlineBuffer, volumeVectors[x]);
        }

        NIVectorAddVectors(volumeVectors, volumeNormals, _width);
    }

    free(volumeVectors);
    free(volumeNormals);
}

- (void)_nearestNeighborFill
{
    NSUInteger x;
    NSUInteger y;
    NIAffineTransform vectorTransform;
    NIVectorArray volumeVectors;
    NIVectorArray volumeNormals;
    NIVolumeDataInlineBuffer inlineBuffer;

    volumeVectors = malloc(_width * sizeof(NIVector));
    memcpy(volumeVectors, _vectors, _width * sizeof(NIVector));
    NIVectorApplyTransformToVectors(_volumeData.volumeTransform, volumeVectors, _width);

    volumeNormals = malloc(_width * sizeof(NIVector));
    memcpy(volumeNormals, _normals, _width * sizeof(NIVector));
    vectorTransform = _volumeData.volumeTransform;
    vectorTransform.m41 = vectorTransform.m42 = vectorTransform.m43 = 0.0;
    NIVectorApplyTransformToVectors(vectorTransform, volumeNormals, _width);

    [_volumeData aquireInlineBuffer:&inlineBuffer];
    for (y = 0; y < _height; y++) {
        if ([self isCancelled]) {
            break;
        }

        for (x = 0; x < _width; x++) {
            _floatBytes[y*_width + x] = NIVolumeDataNearestNeighborInterpolatedFloatAtVolumeVector(&inlineBuffer, volumeVectors[x]);
        }

        NIVectorAddVectors(volumeVectors, volumeNormals, _width);
    }

    free(volumeVectors);
    free(volumeNormals);
}

- (void)_cubicInterpolatingFill
{
    NSUInteger x;
    NSUInteger y;
    NIAffineTransform vectorTransform;
    NIVectorArray volumeVectors;
    NIVectorArray volumeNormals;
    NIVolumeDataInlineBuffer inlineBuffer;

    volumeVectors = malloc(_width * sizeof(NIVector));
    memcpy(volumeVectors, _vectors, _width * sizeof(NIVector));
    NIVectorApplyTransformToVectors(_volumeData.volumeTransform, volumeVectors, _width);

    volumeNormals = malloc(_width * sizeof(NIVector));
    memcpy(volumeNormals, _normals, _width * sizeof(NIVector));
    vectorTransform = _volumeData.volumeTransform;
    vectorTransform.m41 = vectorTransform.m42 = vectorTransform.m43 = 0.0;
    NIVectorApplyTransformToVectors(vectorTransform, volumeNormals, _width);

    [_volumeData aquireInlineBuffer:&inlineBuffer];
    for (y = 0; y < _height; y++) {
        if ([self isCancelled]) {
            break;
        }

        for (x = 0; x < _width; x++) {
            _floatBytes[y*_width + x] = NIVolumeDataCubicInterpolatedFloatAtVolumeVector(&inlineBuffer, volumeVectors[x]);
        }

        NIVectorAddVectors(volumeVectors, volumeNormals, _width);
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
