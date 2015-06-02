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

#import <Cocoa/Cocoa.h>
#import "NIGeometry.h"
#import "NIVolumeData.h"

typedef NS_ENUM(NSInteger, NIProjectionMode)
{
    NIProjectionModeVR, // don't use this, it is not implemented
    NIProjectionModeMIP,
    NIProjectionModeMinIP,
    NIProjectionModeMean,

    NIProjectionModeNone = 0xFFFFFF,
};

// a class to encapsulate all the different parameters required to generate a NI Image
// still working on how to engineer this, it this version sticks, this will be broken up into two files

@class NIBezierPath;

@interface NIGeneratorRequest : NSObject  <NSCopying> {
    NSUInteger _pixelsWide;
    NSUInteger _pixelsHigh;

    CGFloat _slabWidth;
    CGFloat _slabSampleDistance;

    NIInterpolationMode _interpolationMode;

    void *_context;
}

- (instancetype)interpolateBetween:(NIGeneratorRequest *)rightRequest withWeight:(CGFloat)weight;
- (instancetype)generatorRequestResizedToPixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh;

// specifify the size of the returned data
@property (nonatomic, readwrite, assign) NSUInteger pixelsWide;
@property (nonatomic, readwrite, assign) NSUInteger pixelsHigh;

@property (nonatomic, readwrite, assign) CGFloat slabWidth; // width of the slab in millimeters
@property (nonatomic, readwrite, assign) CGFloat slabSampleDistance; // mm/slab if this is set to 0, a reasonable value will be picked automatically, otherwise, this value

@property (nonatomic, readwrite, assign) NIInterpolationMode interpolationMode;

@property (nonatomic, readwrite, assign) void *context;

- (BOOL)isEqual:(id)object;

- (NIVector (^)(NIVector))convertVolumeVectorToDICOMVectorBlock;
- (NIVector (^)(NIVector))convertVolumeVectorFromDICOMVectorBlock;

- (NIVector)convertVolumeVectorToDICOMVector:(NIVector)vector;
- (NIVector)convertVolumeVectorFromDICOMVector:(NIVector)vector;

@property (nonatomic, readonly, retain) NIBezierPath *rimPath;

- (Class)operationClass;

@end


@interface NIStraightenedGeneratorRequest : NIGeneratorRequest
{
    NIBezierPath *_bezierPath;
    NIVector _initialNormal;

    enum NIProjectionMode _projectionMode;
    //    BOOL _vertical; // it would be cool to implement this one day
}

@property (nonatomic, readwrite, retain) NIBezierPath *bezierPath;
@property (nonatomic, readwrite, assign) NIVector initialNormal; // the down direction on the left/top of the output NI, this vector must be normal to the initial tangent of the curve

@property (nonatomic, readwrite, assign) NIProjectionMode projectionMode;

// @property (nonatomic, readwrite, assign) BOOL vertical; // the straightened bezier is horizantal across the screen, or vertical it would be cool to implement this one day

- (BOOL)isEqual:(id)object;

@end

@interface NIStretchedGeneratorRequest : NIGeneratorRequest
{
    NIBezierPath *_bezierPath;

    NIVector _projectionNormal;
    NIVector _midHeightPoint; // this point in the volume will be half way up the volume

    NIProjectionMode _projectionMode;
}

@property (nonatomic, readwrite, retain) NIBezierPath *bezierPath;
@property (nonatomic, readwrite, assign) NIVector projectionNormal;
@property (nonatomic, readwrite, assign) NIVector midHeightPoint;
@property (nonatomic, readwrite, assign) NIProjectionMode projectionMode;

- (BOOL)isEqual:(id)object;

@end


@interface NIObliqueSliceGeneratorRequest : NIGeneratorRequest
{
    NIVector _origin;
    NIVector _directionX;
    NIVector _directionY;
    NIVector _directionZ;

    CGFloat _pixelSpacingX;
    CGFloat _pixelSpacingY;

    NIProjectionMode _projectionMode;
}

- (id)init;
- (id)initWithCenter:(NIVector)center pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh xBasis:(NIVector)xBasis yBasis:(NIVector)yBasis; // the length of the vectors will be considered to be the pixel spacing

@property (nonatomic, readwrite, assign) NIVector origin;
@property (nonatomic, readwrite, assign) NIVector directionX;
@property (nonatomic, readwrite, assign) NIVector directionY;
@property (nonatomic, readwrite, assign) NIVector directionZ; // if this is NIVectorZero, it defaults to the cross product of the X and Y directions
@property (nonatomic, readwrite, assign) CGFloat pixelSpacingX; // mm/pixel
@property (nonatomic, readwrite, assign) CGFloat pixelSpacingY;
@property (nonatomic, readwrite, assign) CGFloat pixelSpacingZ; // maps to slabSampleDistance

@property (nonatomic, readwrite, assign) NIProjectionMode projectionMode;

@property (nonatomic, readwrite, assign) NIAffineTransform sliceToDicomTransform;
@property (nonatomic, readonly, assign) NIPlane plane;
@property (nonatomic, readonly, assign) NIVector center;

@end

@interface NIObliqueSliceGeneratorRequest (DCMPixAndVolume) // KVO code is not yet implemented for this category

- (void)setOrientation:(float[6])orientation;
- (void)setOrientationDouble:(double[6])orientation;
- (void)getOrientation:(float[6])orientation;
- (void)getOrientationDouble:(double[6])orientation;

@property (nonatomic, readwrite, assign) double originX;
@property (nonatomic, readwrite, assign) double originY;
@property (nonatomic, readwrite, assign) double originZ;

@property (nonatomic, readwrite, assign) double spacingX;
@property (nonatomic, readwrite, assign) double spacingY;

@end






