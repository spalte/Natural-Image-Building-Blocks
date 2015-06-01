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

#import <Cocoa/Cocoa.h>
#import "NIBBGeometry.h"
#import "NIBBVolumeData.h"
#import "NIBBProjectionOperation.h"

// a class to encapsulate all the different parameters required to generate a NIBB Image
// still working on how to engineer this, it this version sticks, this will be broken up into two files

@class NIBBBezierPath;

@interface NIBBGeneratorRequest : NSObject  <NSCopying> {
    NSUInteger _pixelsWide;
    NSUInteger _pixelsHigh;

    CGFloat _slabWidth;
    CGFloat _slabSampleDistance;

    NIBBInterpolationMode _interpolationMode;

    void *_context;
}

- (instancetype)interpolateBetween:(NIBBGeneratorRequest *)rightRequest withWeight:(CGFloat)weight;
- (instancetype)generatorRequestResizedToPixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh;

// specifify the size of the returned data
@property (nonatomic, readwrite, assign) NSUInteger pixelsWide;
@property (nonatomic, readwrite, assign) NSUInteger pixelsHigh;

@property (nonatomic, readwrite, assign) CGFloat slabWidth; // width of the slab in millimeters
@property (nonatomic, readwrite, assign) CGFloat slabSampleDistance; // mm/slab if this is set to 0, a reasonable value will be picked automatically, otherwise, this value

@property (nonatomic, readwrite, assign) NIBBInterpolationMode interpolationMode;

@property (nonatomic, readwrite, assign) void *context;

- (BOOL)isEqual:(id)object;

- (NIBBVector (^)(NIBBVector))convertVolumeVectorToDICOMVectorBlock;
- (NIBBVector (^)(NIBBVector))convertVolumeVectorFromDICOMVectorBlock;

- (NIBBVector)convertVolumeVectorToDICOMVector:(NIBBVector)vector;
- (NIBBVector)convertVolumeVectorFromDICOMVector:(NIBBVector)vector;

@property (nonatomic, readonly, retain) NIBBBezierPath *rimPath;

- (Class)operationClass;

@end


@interface NIBBStraightenedGeneratorRequest : NIBBGeneratorRequest
{
    NIBBBezierPath *_bezierPath;
    NIBBVector _initialNormal;

    NIBBProjectionMode _projectionMode;
    //    BOOL _vertical; // it would be cool to implement this one day
}

@property (nonatomic, readwrite, retain) NIBBBezierPath *bezierPath;
@property (nonatomic, readwrite, assign) NIBBVector initialNormal; // the down direction on the left/top of the output NIBB, this vector must be normal to the initial tangent of the curve

@property (nonatomic, readwrite, assign) NIBBProjectionMode projectionMode;

// @property (nonatomic, readwrite, assign) BOOL vertical; // the straightened bezier is horizantal across the screen, or vertical it would be cool to implement this one day

- (BOOL)isEqual:(id)object;

@end

@interface NIBBStretchedGeneratorRequest : NIBBGeneratorRequest
{
    NIBBBezierPath *_bezierPath;

    NIBBVector _projectionNormal;
    NIBBVector _midHeightPoint; // this point in the volume will be half way up the volume

    NIBBProjectionMode _projectionMode;
}

@property (nonatomic, readwrite, retain) NIBBBezierPath *bezierPath;
@property (nonatomic, readwrite, assign) NIBBVector projectionNormal;
@property (nonatomic, readwrite, assign) NIBBVector midHeightPoint;
@property (nonatomic, readwrite, assign) NIBBProjectionMode projectionMode;

- (BOOL)isEqual:(id)object;

@end


@interface NIBBObliqueSliceGeneratorRequest : NIBBGeneratorRequest
{
    NIBBVector _origin;
    NIBBVector _directionX;
    NIBBVector _directionY;
    NIBBVector _directionZ;

    CGFloat _pixelSpacingX;
    CGFloat _pixelSpacingY;

    NIBBProjectionMode _projectionMode;
}

- (id)init;
- (id)initWithCenter:(NIBBVector)center pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh xBasis:(NIBBVector)xBasis yBasis:(NIBBVector)yBasis; // the length of the vectors will be considered to be the pixel spacing

@property (nonatomic, readwrite, assign) NIBBVector origin;
@property (nonatomic, readwrite, assign) NIBBVector directionX;
@property (nonatomic, readwrite, assign) NIBBVector directionY;
@property (nonatomic, readwrite, assign) NIBBVector directionZ; // if this is NIBBVectorZero, it defaults to the cross product of the X and Y directions
@property (nonatomic, readwrite, assign) CGFloat pixelSpacingX; // mm/pixel
@property (nonatomic, readwrite, assign) CGFloat pixelSpacingY;
@property (nonatomic, readwrite, assign) CGFloat pixelSpacingZ; // maps to slabSampleDistance

@property (nonatomic, readwrite, assign) NIBBProjectionMode projectionMode;

@property (nonatomic, readwrite, assign) NIBBAffineTransform sliceToDicomTransform;
@property (nonatomic, readonly, assign) NIBBPlane plane;
@property (nonatomic, readonly, assign) NIBBVector center;

@end

@interface NIBBObliqueSliceGeneratorRequest (DCMPixAndVolume) // KVO code is not yet implemented for this category

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






