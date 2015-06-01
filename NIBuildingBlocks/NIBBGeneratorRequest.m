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

#import "NIBBGeneratorRequest.h"
#import "NIBBBezierPath.h"
#import "NIBBStraightenedOperation.h"
#import "NIBBStretchedOperation.h"
#import "NIBBObliqueSliceOperation.h"

@implementation NIBBGeneratorRequest

@synthesize pixelsWide = _pixelsWide;
@synthesize pixelsHigh = _pixelsHigh;
@synthesize slabWidth = _slabWidth;
@synthesize slabSampleDistance = _slabSampleDistance;
@synthesize interpolationMode = _interpolationMode;
@synthesize context = _context;

- (id)init
{
    if ( (self = [super init]) ) {
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    NIBBGeneratorRequest *copy;

    copy = [[[self class] allocWithZone:zone] init];
    copy.pixelsWide = _pixelsWide;
    copy.pixelsHigh = _pixelsHigh;
    copy.slabWidth = _slabWidth;
    copy.slabSampleDistance = _slabSampleDistance;
    copy.interpolationMode = _interpolationMode;
    copy.context = _context;

    return copy;
}

- (BOOL)isEqual:(id)object
{
    NIBBGeneratorRequest *generatorRequest;
    if ([object isKindOfClass:[NIBBGeneratorRequest class]]) {
        generatorRequest = (NIBBGeneratorRequest *)object;
        if (_pixelsWide == generatorRequest.pixelsWide &&
            _pixelsHigh == generatorRequest.pixelsHigh &&
            _slabWidth == generatorRequest.slabWidth &&
            _slabSampleDistance == generatorRequest.slabSampleDistance &&
            _interpolationMode == generatorRequest.interpolationMode &&
            _context == generatorRequest.context) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash
{
    return _pixelsWide ^ _pixelsHigh ^ *((NSUInteger *)&_slabWidth) ^ *((NSUInteger *)&_slabSampleDistance) ^ *((NSUInteger *)&_interpolationMode) ^ ((NSUInteger)_context);
}

- (Class)operationClass
{
    return nil;
}

- (instancetype)interpolateBetween:(NIBBGeneratorRequest *)rightRequest withWeight:(CGFloat)weight
{
    if (weight < 0.5) {
        return [[self copy] autorelease];
    } else {
        return [[rightRequest copy] autorelease];
    }
}

- (instancetype)generatorRequestResizedToPixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh
{
    NIBBGeneratorRequest *request = [[self copy] autorelease];

    request.pixelsWide = pixelsWide;
    request.pixelsHigh = pixelsHigh;

    return request;
}

- (NIBBVector (^)(NIBBVector))convertVolumeVectorToDICOMVectorBlock
{
    NSAssert(NO, @"Not Implemented");
    return [[^NIBBVector(NIBBVector vector) {
        NSAssert(NO, @"Not Implemented"); return NIBBVectorZero;
    } copy] autorelease];
}

- (NIBBVector (^)(NIBBVector))convertVolumeVectorFromDICOMVectorBlock
{
    NSAssert(NO, @"Not Implemented");
    return [[^NIBBVector(NIBBVector vector) {
        NSAssert(NO, @"Not Implemented"); return NIBBVectorZero;
    } copy] autorelease];
}

- (NIBBVector)convertVolumeVectorToDICOMVector:(NIBBVector)vector
{
    return [self convertVolumeVectorToDICOMVectorBlock](vector);
}

- (NIBBVector)convertVolumeVectorFromDICOMVector:(NIBBVector)vector
{
    return [self convertVolumeVectorFromDICOMVectorBlock](vector);
}

- (NIBBBezierPath *)rimPath
{
    return nil;
}

@end

@implementation NIBBStraightenedGeneratorRequest

@synthesize bezierPath = _bezierPath;
@synthesize initialNormal = _initialNormal;

@synthesize projectionMode = _projectionMode;
// @synthesize vertical = _vertical;

- (id)init
{
    if ( (self = [super init]) ) {
        _projectionMode = NIBBProjectionModeNone;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    NIBBStraightenedGeneratorRequest *copy;

    copy = [super copyWithZone:zone];
    copy.bezierPath = _bezierPath;
    copy.initialNormal = _initialNormal;
    copy.projectionMode = _projectionMode;
    //    copy.vertical = _vertical;
    return copy;
}

- (BOOL)isEqual:(id)object
{
    NIBBStraightenedGeneratorRequest *straightenedGeneratorRequest;

    if ([object isKindOfClass:[NIBBStraightenedGeneratorRequest class]]) {
        straightenedGeneratorRequest = (NIBBStraightenedGeneratorRequest *)object;
        if ([super isEqual:object] &&
            [_bezierPath isEqualToBezierPath:straightenedGeneratorRequest.bezierPath] &&
            NIBBVectorEqualToVector(_initialNormal, straightenedGeneratorRequest.initialNormal) &&
            _projectionMode == straightenedGeneratorRequest.projectionMode /*&&*/
            /* _vertical == straightenedGeneratorRequest.vertical */) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash // a not that great hash function....
{
    return [super hash] ^ [_bezierPath hash] ^ (NSUInteger)NIBBVectorLength(_initialNormal) ^ (NSUInteger)_projectionMode /* ^ (NSUInteger)_vertical */;
}


- (void)dealloc
{
    [_bezierPath release];
    _bezierPath = nil;
    [super dealloc];
}

- (Class)operationClass
{
    return [NIBBStraightenedOperation class];
}

@end

@implementation NIBBStretchedGeneratorRequest

@synthesize bezierPath = _bezierPath;
@synthesize projectionNormal = _projectionNormal;
@synthesize midHeightPoint = _midHeightPoint;

@synthesize projectionMode = _projectionMode;

- (id)init
{
    if ( (self = [super init]) ) {
        _projectionMode = NIBBProjectionModeNone;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    NIBBStretchedGeneratorRequest *copy;

    copy = [super copyWithZone:zone];
    copy.bezierPath = _bezierPath;
    copy.projectionNormal = _projectionNormal;
    copy.midHeightPoint = _midHeightPoint;
    copy.projectionMode = _projectionMode;
    //    copy.vertical = _vertical;
    return copy;
}

- (BOOL)isEqual:(id)object
{
    NIBBStretchedGeneratorRequest *stretchedGeneratorRequest;

    if ([object isKindOfClass:[NIBBStretchedGeneratorRequest class]]) {
        stretchedGeneratorRequest = (NIBBStretchedGeneratorRequest *)object;
        if ([super isEqual:object] &&
            [_bezierPath isEqualToBezierPath:stretchedGeneratorRequest.bezierPath] &&
            NIBBVectorEqualToVector(_projectionNormal, stretchedGeneratorRequest.projectionNormal) &&
            NIBBVectorEqualToVector(_midHeightPoint, stretchedGeneratorRequest.midHeightPoint) &&
            _projectionMode == stretchedGeneratorRequest.projectionMode) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash // a not that great hash function....
{
    return [super hash] ^ [_bezierPath hash] ^ (NSUInteger)NIBBVectorLength(_projectionNormal) ^ (NSUInteger)NIBBVectorLength(_midHeightPoint) ^ (NSUInteger)_projectionMode;
}


- (void)dealloc
{
    [_bezierPath release];
    _bezierPath = nil;
    [super dealloc];
}

- (Class)operationClass
{
    return [NIBBStretchedOperation class];
}

@end


@implementation NIBBObliqueSliceGeneratorRequest : NIBBGeneratorRequest

@synthesize origin = _origin;
@synthesize directionX = _directionX;
@synthesize directionY = _directionY;
@synthesize directionZ = _directionZ;
@synthesize pixelSpacingX = _pixelSpacingX;
@synthesize pixelSpacingY = _pixelSpacingY;
@synthesize projectionMode = _projectionMode;

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

    if ([key isEqualToString:@"origin"] ||
        [key isEqualToString:@"directionX"] ||
        [key isEqualToString:@"directionY"] ||
        [key isEqualToString:@"pixelSpacingX"] ||
        [key isEqualToString:@"pixelSpacingY"]) {
        return [keyPaths setByAddingObjectsFromSet:[NSSet setWithObject:@"sliceToDicomTransform"]];
    } else if ([key isEqualToString:@"sliceToDicomTransform"]) {
        return [keyPaths setByAddingObjectsFromSet:[NSSet setWithObjects:@"origin", @"directionX", @"directionY", @"pixelSpacingX", @"pixelSpacingY", nil]];
    } else {
        return keyPaths;
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    NIBBObliqueSliceGeneratorRequest *copy;

    copy = [super copyWithZone:zone];
    copy.origin = _origin;
    copy.directionX = _directionX;
    copy.directionY = _directionY;
    copy.pixelSpacingX = _pixelSpacingX;
    copy.pixelSpacingY = _pixelSpacingY;
    copy.projectionMode = _projectionMode;

    return copy;
}

- (id)init
{
    if ( (self = [super init]) ) {
        _projectionMode = NIBBProjectionModeNone;
    }
    return self;
}

- (id)initWithCenter:(NIBBVector)center pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh xBasis:(NIBBVector)xBasis yBasis:(NIBBVector)yBasis
{
    if ( (self = [super init]) ) {
        self.pixelsWide = pixelsWide;
        self.pixelsHigh = pixelsHigh;

        _directionX = NIBBVectorNormalize(xBasis);
        _pixelSpacingX = NIBBVectorLength(xBasis);

        _directionY = NIBBVectorNormalize(yBasis);
        _pixelSpacingY = NIBBVectorLength(yBasis);

        _origin = NIBBVectorAdd(NIBBVectorAdd(center, NIBBVectorScalarMultiply(xBasis, (CGFloat)pixelsWide/-2.0)), NIBBVectorScalarMultiply(yBasis, (CGFloat)pixelsHigh/-2.0));

        _projectionMode = NIBBProjectionModeNone;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    NIBBObliqueSliceGeneratorRequest *obliqueSliceGeneratorRequest;

    if ([object isKindOfClass:[NIBBObliqueSliceGeneratorRequest class]]) {
        obliqueSliceGeneratorRequest = (NIBBObliqueSliceGeneratorRequest *)object;
        if ([super isEqual:object] &&
            NIBBVectorEqualToVector(_origin, obliqueSliceGeneratorRequest.origin) &&
            NIBBVectorEqualToVector(_directionX, obliqueSliceGeneratorRequest.directionX) &&
            NIBBVectorEqualToVector(_directionY, obliqueSliceGeneratorRequest.directionY) &&
            _pixelSpacingX == obliqueSliceGeneratorRequest.pixelSpacingX &&
            _pixelSpacingY == obliqueSliceGeneratorRequest.pixelSpacingY &&
            _projectionMode == obliqueSliceGeneratorRequest.projectionMode) {
            return YES;
        }
    }
    return NO;
}

- (instancetype)interpolateBetween:(NIBBGeneratorRequest *)rightRequest withWeight:(CGFloat)weight
{
    if ([rightRequest isKindOfClass:[NIBBObliqueSliceGeneratorRequest class]] == NO) {
        return [super interpolateBetween:rightRequest withWeight:weight];
    }

    if (weight == 0) {
        return [[self copy] autorelease];
    } else if (weight == 1.0) {
        return [[rightRequest copy] autorelease];
    }

    NIBBObliqueSliceGeneratorRequest* rightObliqueRequest = (NIBBObliqueSliceGeneratorRequest *)rightRequest;

    NIBBVector leftCenter = [self center];
    NIBBVector rightCenter = [rightObliqueRequest center];

    NIBBVector leftNormal = NIBBVectorNormalize(NIBBVectorCrossProduct(self.directionX, self.directionY));
    NIBBVector rightNormal = NIBBVectorNormalize(NIBBVectorCrossProduct(rightObliqueRequest.directionX, rightObliqueRequest.directionY));

    NIBBVector normalRotationAxis = NIBBVectorCrossProduct(leftNormal, rightNormal);
    CGFloat rotationAngle = asin(NIBBVectorLength(normalRotationAxis));
    if (NIBBVectorIsZero(normalRotationAxis)) {
        normalRotationAxis = self.directionY;
    } else {
        normalRotationAxis = NIBBVectorNormalize(normalRotationAxis);
    }
    if (NIBBVectorDotProduct(leftNormal, rightNormal) < 0) {
        rotationAngle = M_PI - rotationAngle;
    }

    NIBBVector rotatedDirectionX = NIBBVectorApplyTransform(self.directionX, NIBBAffineTransformMakeRotationAroundVector(rotationAngle, normalRotationAxis));
    NIBBVector xRotationAxis = NIBBVectorCrossProduct(rotatedDirectionX, rightObliqueRequest.directionX);
    CGFloat xRotationAngle = asin(NIBBVectorLength(xRotationAxis));
    if (NIBBVectorDotProduct(rotatedDirectionX, rightObliqueRequest.directionX) < 0) {
        xRotationAngle = M_PI - xRotationAngle;
    }
    if (NIBBVectorDotProduct(xRotationAxis, rightNormal) < 0) {
        xRotationAngle = -xRotationAngle;
    }

    NIBBObliqueSliceGeneratorRequest* interpolatedRequest = [[self copy] autorelease];
    interpolatedRequest.pixelSpacingX = 0; // kinda hacky, but setting these to 0 will keep setPixelsWide and setPixelsHigh from doing anything weird
    interpolatedRequest.pixelSpacingY = 0;
    interpolatedRequest.pixelsHigh = (NSInteger)round((((CGFloat)self.pixelsHigh) * (1.0 - weight)) + (((CGFloat)rightObliqueRequest.pixelsHigh) * weight));
    interpolatedRequest.pixelsWide = (NSInteger)round((((CGFloat)self.pixelsWide) * (1.0 - weight)) + (((CGFloat)rightObliqueRequest.pixelsWide) * weight));
    interpolatedRequest.pixelSpacingX = (self.pixelSpacingX * (1.0 - weight)) + (rightObliqueRequest.pixelSpacingX * weight);
    interpolatedRequest.pixelSpacingY = (self.pixelSpacingY * (1.0 - weight)) + (rightObliqueRequest.pixelSpacingY * weight);

    NIBBVector interpolatedCenter = NIBBVectorLerp(leftCenter, rightCenter, weight);
    NIBBVector interpolatedNormal = NIBBVectorApplyTransform(leftNormal, NIBBAffineTransformMakeRotationAroundVector(rotationAngle * weight, normalRotationAxis));
    NIBBVector interpolatedDirectionX = NIBBVectorApplyTransform(self.directionX, NIBBAffineTransformMakeRotationAroundVector(rotationAngle * weight, normalRotationAxis));
    interpolatedDirectionX = NIBBVectorApplyTransform(interpolatedDirectionX, NIBBAffineTransformMakeRotationAroundVector(xRotationAngle * weight, interpolatedNormal));
    NIBBVector interpolatedDirectionY = NIBBVectorApplyTransform(self.directionY, NIBBAffineTransformMakeRotationAroundVector(rotationAngle * weight, normalRotationAxis));
    interpolatedDirectionY = NIBBVectorApplyTransform(interpolatedDirectionY, NIBBAffineTransformMakeRotationAroundVector(xRotationAngle * weight, interpolatedNormal));

    interpolatedRequest.directionX = interpolatedDirectionX;
    interpolatedRequest.directionY = interpolatedDirectionY;

    interpolatedRequest.origin =  NIBBVectorSubtract(NIBBVectorSubtract(interpolatedCenter,
                                                                    NIBBVectorScalarMultiply(interpolatedDirectionX, interpolatedRequest.pixelSpacingX * ((CGFloat)interpolatedRequest.pixelsWide)/2.0)),
                                                   NIBBVectorScalarMultiply(interpolatedDirectionY, interpolatedRequest.pixelSpacingY * ((CGFloat)interpolatedRequest.pixelsHigh)/2.0));

    return interpolatedRequest;
}

- (instancetype)generatorRequestResizedToPixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh
{
    NIBBObliqueSliceGeneratorRequest* generatorRequest = [[self copy] autorelease];

    // deal with the width
    CGFloat changeRatio = (CGFloat)self.pixelsWide/(CGFloat)pixelsWide;

    generatorRequest.pixelSpacingX *= changeRatio;
    generatorRequest.pixelSpacingY *= changeRatio;
    generatorRequest.pixelsWide = pixelsWide;
    generatorRequest.origin = NIBBVectorAdd(self.origin, NIBBVectorScalarMultiply(generatorRequest.directionY, ((CGFloat)generatorRequest.pixelsHigh / 2.0)*(self.pixelSpacingY - generatorRequest.pixelSpacingY)));

    // deal with the height
    generatorRequest.pixelsHigh = pixelsHigh;
    generatorRequest.origin = NIBBVectorAdd(generatorRequest.origin, NIBBVectorScalarMultiply(generatorRequest.directionY, ((CGFloat)((NSInteger)self.pixelsHigh - (NSInteger)pixelsHigh)/2.0) * generatorRequest.pixelSpacingY));
    
    return generatorRequest;
}

- (Class)operationClass
{
    return [NIBBObliqueSliceOperation class];
}

- (void)setPixelSpacingZ:(CGFloat)pixelSpacingZ
{
    [self setSlabSampleDistance:pixelSpacingZ];
}

- (CGFloat)pixelSpacingZ
{
    return [self slabSampleDistance];
}

- (void)setDirectionX:(NIBBVector)direction
{
    CGFloat length = NIBBVectorLength(direction);
    if (length < 0.999 || length > 1.0001) {
        NSLog(@"[NIBBObliqueSliceGeneratorRequest setDirectionX:] called with non-unit vector %@", NSStringFromNIBBVector(direction));
        _directionX = NIBBVectorNormalize(direction);
    } else {
        _directionX = direction;
    }
}

- (void)setDirectionY:(NIBBVector)direction
{
    CGFloat length = NIBBVectorLength(direction);
    if (length < 0.999 || length > 1.0001) {
        NSLog(@"[NIBBObliqueSliceGeneratorRequest setDirectionY:] called with non-unit vector %@", NSStringFromNIBBVector(direction));
        _directionY = NIBBVectorNormalize(direction);
    } else {
        _directionY = direction;
    }
}

- (NIBBVector (^)(NIBBVector))convertVolumeVectorToDICOMVectorBlock
{
    NIBBAffineTransform sliceToDicomTransform = self.sliceToDicomTransform;

    return [[^NIBBVector(NIBBVector vector) {
        return NIBBVectorApplyTransform(vector, sliceToDicomTransform);
    } copy] autorelease];
}

- (NIBBVector (^)(NIBBVector))convertVolumeVectorFromDICOMVectorBlock
{
    NIBBAffineTransform dicomToSliceTransform = NIBBAffineTransformInvert(self.sliceToDicomTransform);

    return [[^NIBBVector(NIBBVector vector) {
        return NIBBVectorApplyTransform(vector, dicomToSliceTransform);
    } copy] autorelease];
}

- (NIBBVector)center
{
    return NIBBVectorAdd(NIBBVectorAdd(self.origin, NIBBVectorScalarMultiply(self.directionX, self.pixelSpacingX * ((CGFloat)self.pixelsWide)/2.0)),
                       NIBBVectorScalarMultiply(self.directionY, self.pixelSpacingY * ((CGFloat)self.pixelsHigh)/2.0));
}

- (NIBBPlane)plane
{
    return NIBBPlaneMake(self.origin, NIBBVectorNormalize(NIBBVectorCrossProduct(self.directionX, self.directionY)));
}

- (NIBBBezierPath *)rimPath
{
    NIBBMutableBezierPath *rimPath = [NIBBMutableBezierPath bezierPath];

    [rimPath moveToVector:self.origin];
    [rimPath lineToVector:NIBBVectorAdd(self.origin, NIBBVectorScalarMultiply(self.directionX, self.pixelSpacingX * self.pixelsWide))];
    [rimPath lineToVector:NIBBVectorAdd(NIBBVectorAdd(self.origin, NIBBVectorScalarMultiply(self.directionX, self.pixelSpacingX * self.pixelsWide)), NIBBVectorScalarMultiply(self.directionY, self.pixelSpacingY * self.pixelsHigh))];
    [rimPath lineToVector:NIBBVectorAdd(self.origin, NIBBVectorScalarMultiply(self.directionY, self.pixelSpacingY * self.pixelsHigh))];
    [rimPath close];

    return rimPath;
}

- (void)setSliceToDicomTransform:(NIBBAffineTransform)sliceToDicomTransform
{
    _directionX = NIBBVectorMake(sliceToDicomTransform.m11, sliceToDicomTransform.m12, sliceToDicomTransform.m13);
    _pixelSpacingX = NIBBVectorLength(_directionX);
    _directionX = NIBBVectorNormalize(_directionX);

    _directionY = NIBBVectorMake(sliceToDicomTransform.m21, sliceToDicomTransform.m22, sliceToDicomTransform.m23);
    _pixelSpacingY = NIBBVectorLength(_directionY);
    _directionY = NIBBVectorNormalize(_directionY);

    _origin = NIBBVectorMake(sliceToDicomTransform.m41, sliceToDicomTransform.m42, sliceToDicomTransform.m43);
}

- (NIBBAffineTransform)sliceToDicomTransform
{
// FIXME: the sliceToDicomTransform does not return the right value in Z
    NIBBAffineTransform sliceToDicomTransform;
    CGFloat pixelSpacingZ;
    NIBBVector crossVector;

    sliceToDicomTransform = NIBBAffineTransformIdentity;
    crossVector = NIBBVectorNormalize(NIBBVectorCrossProduct(_directionX, _directionY));
    pixelSpacingZ = 1.0; // totally bogus, but there is no right value, and this should give something that is reasonable

    sliceToDicomTransform.m11 = _directionX.x * _pixelSpacingX;
    sliceToDicomTransform.m12 = _directionX.y * _pixelSpacingX;
    sliceToDicomTransform.m13 = _directionX.z * _pixelSpacingX;

    sliceToDicomTransform.m21 = _directionY.x * _pixelSpacingY;
    sliceToDicomTransform.m22 = _directionY.y * _pixelSpacingY;
    sliceToDicomTransform.m23 = _directionY.z * _pixelSpacingY;

    sliceToDicomTransform.m31 = crossVector.x * pixelSpacingZ;
    sliceToDicomTransform.m32 = crossVector.y * pixelSpacingZ;
    sliceToDicomTransform.m33 = crossVector.z * pixelSpacingZ;

    sliceToDicomTransform.m41 = _origin.x;
    sliceToDicomTransform.m42 = _origin.y;
    sliceToDicomTransform.m43 = _origin.z;

    return sliceToDicomTransform;
}


@end

@implementation NIBBObliqueSliceGeneratorRequest (DCMPixAndVolume)

- (void)setOrientation:(float[6])orientation
{
    double doubleOrientation[6];
    NSInteger i;

    for (i = 0; i < 6; i++) {
        doubleOrientation[i] = orientation[i];
    }

    [self setOrientationDouble:doubleOrientation];
}

- (void)setOrientationDouble:(double[6])orientation
{
    _directionX = NIBBVectorNormalize(NIBBVectorMake(orientation[0], orientation[1], orientation[2]));
    _directionY = NIBBVectorNormalize(NIBBVectorMake(orientation[3], orientation[4], orientation[5]));
}

- (void)getOrientation:(float[6])orientation
{
    double doubleOrientation[6];
    NSInteger i;

    [self getOrientationDouble:doubleOrientation];

    for (i = 0; i < 6; i++) {
        orientation[i] = doubleOrientation[i];
    }
}

- (void)getOrientationDouble:(double[6])orientation
{
    orientation[0] = _directionX.x; orientation[1] = _directionX.y; orientation[2] = _directionX.z;
    orientation[3] = _directionY.x; orientation[4] = _directionY.y; orientation[5] = _directionY.z;
}

- (void)setOriginX:(double)origin
{
    _origin.x = origin;
}

- (double)originX
{
    return _origin.x;
}

- (void)setOriginY:(double)origin
{
    _origin.y = origin;
}

- (double)originY
{
    return _origin.y;
}

- (void)setOriginZ:(double)origin
{
    _origin.z = origin;
}

- (double)originZ
{
    return _origin.z;
}

- (void)setSpacingX:(double)spacing
{
    _pixelSpacingX = spacing;
}

- (double)spacingX
{
    return _pixelSpacingX;
}

- (void)setSpacingY:(double)spacing
{
    _pixelSpacingY = spacing;
}

- (double)spacingY
{
    return _pixelSpacingY;
}


@end



