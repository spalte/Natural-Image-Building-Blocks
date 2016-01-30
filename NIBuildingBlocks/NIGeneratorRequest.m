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

#import "NIGeneratorRequest.h"
#import "NIBezierPath.h"
#import "NIStraightenedOperation.h"
#import "NIStretchedOperation.h"
#import "NIObliqueSliceOperation.h"

@implementation NIGeneratorRequest

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
    NIGeneratorRequest *copy;

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
    NIGeneratorRequest *generatorRequest;
    if ([object isKindOfClass:[NIGeneratorRequest class]]) {
        generatorRequest = (NIGeneratorRequest *)object;
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

- (instancetype)interpolateBetween:(NIGeneratorRequest *)rightRequest withWeight:(CGFloat)weight
{
    if (weight < 0.5) {
        return [[self copy] autorelease];
    } else {
        return [[rightRequest copy] autorelease];
    }
}

- (instancetype)generatorRequestResizedToPixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh
{
    NIGeneratorRequest *request = [[self copy] autorelease];

    request.pixelsWide = pixelsWide;
    request.pixelsHigh = pixelsHigh;

    return request;
}

- (NIVector (^)(NIVector))convertVolumeVectorToModelVectorBlock
{
    NSAssert(NO, @"Not Implemented");
    return [[^NIVector(NIVector vector) {
        NSAssert(NO, @"Not Implemented"); return NIVectorZero;
    } copy] autorelease];
}

- (NIVector (^)(NIVector))convertVolumeVectorFromModelVectorBlock
{
    NSAssert(NO, @"Not Implemented");
    return [[^NIVector(NIVector vector) {
        NSAssert(NO, @"Not Implemented"); return NIVectorZero;
    } copy] autorelease];
}

- (NIVector)convertVolumeVectorToModelVector:(NIVector)vector
{
    return [self convertVolumeVectorToModelVectorBlock](vector);
}

- (NIVector)convertVolumeVectorFromModelVector:(NIVector)vector
{
    return [self convertVolumeVectorFromModelVectorBlock](vector);
}

- (NIBezierPath *)rimPath
{
    return nil;
}

@end

@implementation NIStraightenedGeneratorRequest

@synthesize bezierPath = _bezierPath;
@synthesize initialNormal = _initialNormal;

@synthesize projectionMode = _projectionMode;
// @synthesize vertical = _vertical;

- (id)init
{
    if ( (self = [super init]) ) {
        _projectionMode = NIProjectionModeNone;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    NIStraightenedGeneratorRequest *copy;

    copy = [super copyWithZone:zone];
    copy.bezierPath = _bezierPath;
    copy.initialNormal = _initialNormal;
    copy.projectionMode = _projectionMode;
    //    copy.vertical = _vertical;
    return copy;
}

- (BOOL)isEqual:(id)object
{
    NIStraightenedGeneratorRequest *straightenedGeneratorRequest;

    if ([object isKindOfClass:[NIStraightenedGeneratorRequest class]]) {
        straightenedGeneratorRequest = (NIStraightenedGeneratorRequest *)object;
        if ([super isEqual:object] &&
            [_bezierPath isEqualToBezierPath:straightenedGeneratorRequest.bezierPath] &&
            NIVectorEqualToVector(_initialNormal, straightenedGeneratorRequest.initialNormal) &&
            _projectionMode == straightenedGeneratorRequest.projectionMode /*&&*/
            /* _vertical == straightenedGeneratorRequest.vertical */) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash // a not that great hash function....
{
    return [super hash] ^ [_bezierPath hash] ^ (NSUInteger)NIVectorLength(_initialNormal) ^ (NSUInteger)_projectionMode /* ^ (NSUInteger)_vertical */;
}


- (void)dealloc
{
    [_bezierPath release];
    _bezierPath = nil;
    [super dealloc];
}

- (Class)operationClass
{
    return [NIStraightenedOperation class];
}

@end

@implementation NIStretchedGeneratorRequest

@synthesize bezierPath = _bezierPath;
@synthesize projectionNormal = _projectionNormal;
@synthesize midHeightPoint = _midHeightPoint;

@synthesize projectionMode = _projectionMode;

- (id)init
{
    if ( (self = [super init]) ) {
        _projectionMode = NIProjectionModeNone;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    NIStretchedGeneratorRequest *copy;

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
    NIStretchedGeneratorRequest *stretchedGeneratorRequest;

    if ([object isKindOfClass:[NIStretchedGeneratorRequest class]]) {
        stretchedGeneratorRequest = (NIStretchedGeneratorRequest *)object;
        if ([super isEqual:object] &&
            [_bezierPath isEqualToBezierPath:stretchedGeneratorRequest.bezierPath] &&
            NIVectorEqualToVector(_projectionNormal, stretchedGeneratorRequest.projectionNormal) &&
            NIVectorEqualToVector(_midHeightPoint, stretchedGeneratorRequest.midHeightPoint) &&
            _projectionMode == stretchedGeneratorRequest.projectionMode) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash // a not that great hash function....
{
    return [super hash] ^ [_bezierPath hash] ^ (NSUInteger)NIVectorLength(_projectionNormal) ^ (NSUInteger)NIVectorLength(_midHeightPoint) ^ (NSUInteger)_projectionMode;
}


- (void)dealloc
{
    [_bezierPath release];
    _bezierPath = nil;
    [super dealloc];
}

- (Class)operationClass
{
    return [NIStretchedOperation class];
}

@end


@implementation NIObliqueSliceGeneratorRequest : NIGeneratorRequest

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
        [key isEqualToString:@"directionZ"] ||
        [key isEqualToString:@"pixelSpacingX"] ||
        [key isEqualToString:@"pixelSpacingY"] ||
        [key isEqualToString:@"slabSampleDistance"]) {
        return [keyPaths setByAddingObjectsFromSet:[NSSet setWithObject:@"sliceToModelTransform"]];
    } else if ([key isEqualToString:@"sliceToModelTransform"]) {
        return [keyPaths setByAddingObjectsFromSet:[NSSet setWithObjects:@"origin", @"directionX", @"directionY", @"directionZ", @"pixelSpacingX", @"pixelSpacingY", @"slabSampleDistance", nil]];
    } else {
        return keyPaths;
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    NIObliqueSliceGeneratorRequest *copy;

    copy = [super copyWithZone:zone];
    copy.origin = _origin;
    copy.directionX = _directionX;
    copy.directionY = _directionY;
    copy.directionZ = _directionZ;
    copy.pixelSpacingX = _pixelSpacingX;
    copy.pixelSpacingY = _pixelSpacingY;
    copy.projectionMode = _projectionMode;

    return copy;
}

- (id)init
{
    if ( (self = [super init]) ) {
        _projectionMode = NIProjectionModeNone;
    }
    return self;
}

- (id)initWithCenter:(NIVector)center pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh xBasis:(NIVector)xBasis yBasis:(NIVector)yBasis
{
    if ( (self = [super init]) ) {
        self.pixelsWide = pixelsWide;
        self.pixelsHigh = pixelsHigh;

        _directionX = NIVectorNormalize(xBasis);
        _pixelSpacingX = NIVectorLength(xBasis);

        _directionY = NIVectorNormalize(yBasis);
        _pixelSpacingY = NIVectorLength(yBasis);

        _origin = NIVectorAdd(NIVectorAdd(center, NIVectorScalarMultiply(xBasis, (CGFloat)pixelsWide/-2.0)), NIVectorScalarMultiply(yBasis, (CGFloat)pixelsHigh/-2.0));

        _projectionMode = NIProjectionModeNone;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    NIObliqueSliceGeneratorRequest *obliqueSliceGeneratorRequest;

    if ([object isKindOfClass:[NIObliqueSliceGeneratorRequest class]]) {
        obliqueSliceGeneratorRequest = (NIObliqueSliceGeneratorRequest *)object;
        if ([super isEqual:object] &&
            NIVectorEqualToVector(_origin, obliqueSliceGeneratorRequest.origin) &&
            NIVectorEqualToVector(_directionX, obliqueSliceGeneratorRequest.directionX) &&
            NIVectorEqualToVector(_directionY, obliqueSliceGeneratorRequest.directionY) &&
            NIVectorEqualToVector(_directionZ, obliqueSliceGeneratorRequest.directionZ) &&
            _pixelSpacingX == obliqueSliceGeneratorRequest.pixelSpacingX &&
            _pixelSpacingY == obliqueSliceGeneratorRequest.pixelSpacingY &&
            _projectionMode == obliqueSliceGeneratorRequest.projectionMode) {
            return YES;
        }
    }
    return NO;
}

- (instancetype)interpolateBetween:(NIGeneratorRequest *)rightRequest withWeight:(CGFloat)weight
{
    if ([rightRequest isKindOfClass:[NIObliqueSliceGeneratorRequest class]] == NO) {
        return [super interpolateBetween:rightRequest withWeight:weight];
    }

    if (weight == 0) {
        return [[self copy] autorelease];
    } else if (weight == 1.0) {
        return [[rightRequest copy] autorelease];
    }

    NIObliqueSliceGeneratorRequest* rightObliqueRequest = (NIObliqueSliceGeneratorRequest *)rightRequest;

    NIVector leftCenter = [self center];
    NIVector rightCenter = [rightObliqueRequest center];

    NIVector leftNormal = NIVectorNormalize(NIVectorCrossProduct(self.directionX, self.directionY));
    NIVector rightNormal = NIVectorNormalize(NIVectorCrossProduct(rightObliqueRequest.directionX, rightObliqueRequest.directionY));

    NIVector normalRotationAxis = NIVectorCrossProduct(leftNormal, rightNormal);
    CGFloat rotationAngle = asin(NIVectorLength(normalRotationAxis));
    if (NIVectorIsZero(normalRotationAxis)) {
        normalRotationAxis = self.directionY;
    } else {
        normalRotationAxis = NIVectorNormalize(normalRotationAxis);
    }
    if (NIVectorDotProduct(leftNormal, rightNormal) < 0) {
        rotationAngle = M_PI - rotationAngle;
    }

    NIVector rotatedDirectionX = NIVectorApplyTransform(self.directionX, NIAffineTransformMakeRotationAroundVector(rotationAngle, normalRotationAxis));
    NIVector xRotationAxis = NIVectorCrossProduct(rotatedDirectionX, rightObliqueRequest.directionX);
    CGFloat xRotationAngle = asin(NIVectorLength(xRotationAxis));
    if (NIVectorDotProduct(rotatedDirectionX, rightObliqueRequest.directionX) < 0) {
        xRotationAngle = M_PI - xRotationAngle;
    }
    if (NIVectorDotProduct(xRotationAxis, rightNormal) < 0) {
        xRotationAngle = -xRotationAngle;
    }

    NIObliqueSliceGeneratorRequest* interpolatedRequest = [[self copy] autorelease];
    interpolatedRequest.pixelSpacingX = 0; // kinda hacky, but setting these to 0 will keep setPixelsWide and setPixelsHigh from doing anything weird
    interpolatedRequest.pixelSpacingY = 0;
    interpolatedRequest.pixelsHigh = (NSInteger)round((((CGFloat)self.pixelsHigh) * (1.0 - weight)) + (((CGFloat)rightObliqueRequest.pixelsHigh) * weight));
    interpolatedRequest.pixelsWide = (NSInteger)round((((CGFloat)self.pixelsWide) * (1.0 - weight)) + (((CGFloat)rightObliqueRequest.pixelsWide) * weight));
    interpolatedRequest.pixelSpacingX = (self.pixelSpacingX * (1.0 - weight)) + (rightObliqueRequest.pixelSpacingX * weight);
    interpolatedRequest.pixelSpacingY = (self.pixelSpacingY * (1.0 - weight)) + (rightObliqueRequest.pixelSpacingY * weight);

    NIVector interpolatedCenter = NIVectorLerp(leftCenter, rightCenter, weight);
    NIVector interpolatedNormal = NIVectorApplyTransform(leftNormal, NIAffineTransformMakeRotationAroundVector(rotationAngle * weight, normalRotationAxis));
    NIVector interpolatedDirectionX = NIVectorApplyTransform(self.directionX, NIAffineTransformMakeRotationAroundVector(rotationAngle * weight, normalRotationAxis));
    interpolatedDirectionX = NIVectorApplyTransform(interpolatedDirectionX, NIAffineTransformMakeRotationAroundVector(xRotationAngle * weight, interpolatedNormal));
    NIVector interpolatedDirectionY = NIVectorApplyTransform(self.directionY, NIAffineTransformMakeRotationAroundVector(rotationAngle * weight, normalRotationAxis));
    interpolatedDirectionY = NIVectorApplyTransform(interpolatedDirectionY, NIAffineTransformMakeRotationAroundVector(xRotationAngle * weight, interpolatedNormal));

    interpolatedRequest.directionX = interpolatedDirectionX;
    interpolatedRequest.directionY = interpolatedDirectionY;

    interpolatedRequest.origin =  NIVectorSubtract(NIVectorSubtract(interpolatedCenter,
                                                                    NIVectorScalarMultiply(interpolatedDirectionX, interpolatedRequest.pixelSpacingX * ((CGFloat)interpolatedRequest.pixelsWide)/2.0)),
                                                   NIVectorScalarMultiply(interpolatedDirectionY, interpolatedRequest.pixelSpacingY * ((CGFloat)interpolatedRequest.pixelsHigh)/2.0));

    return interpolatedRequest;
}

- (instancetype)generatorRequestResizedToPixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh
{
    NIObliqueSliceGeneratorRequest* generatorRequest = [[self copy] autorelease];

    // deal with the width
    CGFloat changeRatio = (CGFloat)self.pixelsWide/(CGFloat)pixelsWide;

    generatorRequest.pixelSpacingX *= changeRatio;
    generatorRequest.pixelSpacingY *= changeRatio;
    generatorRequest.pixelsWide = pixelsWide;
    generatorRequest.origin = NIVectorAdd(self.origin, NIVectorScalarMultiply(generatorRequest.directionY, ((CGFloat)generatorRequest.pixelsHigh / 2.0)*(self.pixelSpacingY - generatorRequest.pixelSpacingY)));

    // deal with the height
    generatorRequest.pixelsHigh = pixelsHigh;
    generatorRequest.origin = NIVectorAdd(generatorRequest.origin, NIVectorScalarMultiply(generatorRequest.directionY, ((CGFloat)((NSInteger)self.pixelsHigh - (NSInteger)pixelsHigh)/2.0) * generatorRequest.pixelSpacingY));
    
    return generatorRequest;
}

- (Class)operationClass
{
    return [NIObliqueSliceOperation class];
}

- (void)setPixelSpacingZ:(CGFloat)pixelSpacingZ
{
    [self setSlabSampleDistance:pixelSpacingZ];
}

- (CGFloat)pixelSpacingZ
{
    return [self slabSampleDistance];
}

- (void)setDirectionX:(NIVector)direction
{
    CGFloat length = NIVectorLength(direction);
    if (length < 0.999 || length > 1.0001) {
        NSLog(@"[NIObliqueSliceGeneratorRequest setDirectionX:] called with non-unit vector %@", NSStringFromNIVector(direction));
        _directionX = NIVectorNormalize(direction);
    } else {
        _directionX = direction;
    }
}

- (void)setDirectionY:(NIVector)direction
{
    CGFloat length = NIVectorLength(direction);
    if (length < 0.999 || length > 1.0001) {
        NSLog(@"[NIObliqueSliceGeneratorRequest setDirectionY:] called with non-unit vector %@", NSStringFromNIVector(direction));
        _directionY = NIVectorNormalize(direction);
    } else {
        _directionY = direction;
    }
}

- (NIVector (^)(NIVector))convertVolumeVectorToModelVectorBlock
{
    NIAffineTransform sliceToModelTransform = self.sliceToModelTransform;

    return [[^NIVector(NIVector vector) {
        return NIVectorApplyTransform(vector, sliceToModelTransform);
    } copy] autorelease];
}

- (NIVector (^)(NIVector))convertVolumeVectorFromModelVectorBlock
{
    NIAffineTransform modelToSliceTransform = NIAffineTransformInvert(self.sliceToModelTransform);

    return [[^NIVector(NIVector vector) {
        return NIVectorApplyTransform(vector, modelToSliceTransform);
    } copy] autorelease];
}

- (NIVector)center
{
    return NIVectorAdd(NIVectorAdd(self.origin, NIVectorScalarMultiply(self.directionX, self.pixelSpacingX * ((CGFloat)self.pixelsWide)/2.0)),
                       NIVectorScalarMultiply(self.directionY, self.pixelSpacingY * ((CGFloat)self.pixelsHigh)/2.0));
}

- (NIPlane)plane
{
    return NIPlaneMake(self.origin, NIVectorNormalize(NIVectorCrossProduct(self.directionX, self.directionY)));
}

- (NIBezierPath *)rimPath
{
    NIMutableBezierPath *rimPath = [NIMutableBezierPath bezierPath];

    [rimPath moveToVector:self.origin];
    [rimPath lineToVector:NIVectorAdd(self.origin, NIVectorScalarMultiply(self.directionX, self.pixelSpacingX * self.pixelsWide))];
    [rimPath lineToVector:NIVectorAdd(NIVectorAdd(self.origin, NIVectorScalarMultiply(self.directionX, self.pixelSpacingX * self.pixelsWide)), NIVectorScalarMultiply(self.directionY, self.pixelSpacingY * self.pixelsHigh))];
    [rimPath lineToVector:NIVectorAdd(self.origin, NIVectorScalarMultiply(self.directionY, self.pixelSpacingY * self.pixelsHigh))];
    [rimPath close];

    return rimPath;
}

- (void)setSliceToModelTransform:(NIAffineTransform)sliceToModelTransform
{
// FIXME: this is WRONG for origin.z
    _directionX = NIVectorMake(sliceToModelTransform.m11, sliceToModelTransform.m12, sliceToModelTransform.m13);
    _pixelSpacingX = NIVectorLength(_directionX);
    _directionX = NIVectorNormalize(_directionX);

    _directionY = NIVectorMake(sliceToModelTransform.m21, sliceToModelTransform.m22, sliceToModelTransform.m23);
    _pixelSpacingY = NIVectorLength(_directionY);
    _directionY = NIVectorNormalize(_directionY);

    _origin = NIVectorMake(sliceToModelTransform.m41, sliceToModelTransform.m42, sliceToModelTransform.m43);
}

- (NIAffineTransform)sliceToModelTransform
{
    NIAffineTransform sliceToModelTransform;


    CGFloat slabSampleDistance = 0;
    if (_slabSampleDistance != 0.0) {
        slabSampleDistance = _slabSampleDistance;
    } else {
        if (self.slabWidth != 0) {
            NSLog(@"NIObliqueSliceGeneratorRequest with non-zero slab width is trying to build a sliceToModelTransform when the slabSampleDistance is 0");
        }
        slabSampleDistance = 1; //
    }

#if CGFLOAT_IS_DOUBLE
    NSInteger pixelsDeep = MAX(round(self.slabWidth / slabSampleDistance), 0) + 1;
#else
    NSInteger pixelsDeep = MAX(roundf(self.slabWidth / slabSampleDistance), 0) + 1;
#endif

    NIVector zDirection = NIVectorZero;
    NIVector leftDirection = NIVectorScalarMultiply(NIVectorNormalize(_directionX), _pixelSpacingX);
    NIVector downDirection = NIVectorScalarMultiply(NIVectorNormalize(_directionY), _pixelSpacingY);

    if (NIVectorEqualToVector(_directionZ, NIVectorZero)) {
        zDirection = NIVectorScalarMultiply(NIVectorNormalize(NIVectorCrossProduct(leftDirection, downDirection)), slabSampleDistance);
    } else {
        zDirection = NIVectorScalarMultiply(NIVectorNormalize(_directionZ), slabSampleDistance);
    }

    NIVector origin = NIVectorAdd(_origin, NIVectorScalarMultiply(NIVectorInvert(zDirection), (CGFloat)(pixelsDeep - 1)/2.0));

    sliceToModelTransform = NIAffineTransformIdentity;

    sliceToModelTransform.m11 = _directionX.x * _pixelSpacingX;
    sliceToModelTransform.m12 = _directionX.y * _pixelSpacingX;
    sliceToModelTransform.m13 = _directionX.z * _pixelSpacingX;

    sliceToModelTransform.m21 = _directionY.x * _pixelSpacingY;
    sliceToModelTransform.m22 = _directionY.y * _pixelSpacingY;
    sliceToModelTransform.m23 = _directionY.z * _pixelSpacingY;

    sliceToModelTransform.m31 = zDirection.x;
    sliceToModelTransform.m32 = zDirection.y;
    sliceToModelTransform.m33 = zDirection.z;

    sliceToModelTransform.m41 = origin.x;
    sliceToModelTransform.m42 = origin.y;
    sliceToModelTransform.m43 = origin.z;

    return sliceToModelTransform;
}

@end

@implementation NIObliqueSliceGeneratorRequest (DCMPixAndVolume)

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
    _directionX = NIVectorNormalize(NIVectorMake(orientation[0], orientation[1], orientation[2]));
    _directionY = NIVectorNormalize(NIVectorMake(orientation[3], orientation[4], orientation[5]));
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



