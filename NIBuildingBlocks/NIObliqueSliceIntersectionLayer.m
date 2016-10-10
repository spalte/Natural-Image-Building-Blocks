//  Created by Joël Spaltenstein on 4/24/15.
//  Copyright (c) 2016 Spaltenstein Natural Image
//  Copyright (c) 2016 Michael Hilker and Andreas Holzamer
//  Copyright (c) 2016 volz io
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


#import "NIObliqueSliceIntersectionLayer.h"

CF_EXTERN_C_BEGIN

struct NIIntersectionSegment {
    NIVector start;
    NIVector end;
};
typedef struct NIIntersectionSegment NIIntersectionSegment;
typedef NIIntersectionSegment *NIIntersectionSegmentPointer;

@interface NSValue (NIIntersectionSegmentAdditions)
+ (NSValue *)valueWithNIIntersectionSegment:(NIIntersectionSegment)segment;
@property (readonly) NIIntersectionSegment NIIntersectionSegmentValue;
#if __has_attribute(objc_boxable)
typedef struct __attribute__((objc_boxable)) NIIntersectionSegment NIIntersectionSegment;
#endif
@end

@implementation NSValue (NIIntersectionSegmentAdditions)
+ (NSValue *)valueWithNIIntersectionSegment:(NIIntersectionSegment)segment;
{
    return [NSValue valueWithBytes:&segment objCType:@encode(NIIntersectionSegment)];
}

- (NIIntersectionSegment)NIIntersectionSegmentValue;
{
    NIIntersectionSegment segment;
    assert(strcmp([self objCType], @encode(NIIntersectionSegment)) == 0);
    [self getValue:&segment];
    return segment;
}
@end

NIIntersectionSegment NIIntersectionSegmentMake(NIVector start, NIVector end);
//NIIntersectionSegment NIIntersectionSegmentMakeFromVectors(NIVector vector1, NIVector vector2);

CGFloat NIIntersectionSegmentLength(NIIntersectionSegment segment);
NIVector NIIntersectionSegmentDirection(NIIntersectionSegment segment);
NIIntersectionSegment NIIntersectionSegmentApplyTransform(NIIntersectionSegment segment, NIAffineTransform transform);

// projects the vector onto the segment and returns
// -1 if the segment has length 0
// 0 if the vector is before the segment
// within (0, 1) if the vector is within the segment
// 1 if the vector is afer the segment
CGFloat NIIntersectionSegmentVectorSituation(NIIntersectionSegment segment, NIVector vector);

// returns the number of resulting segments, whis is also the number of resulting segments set
// 0 if the sphere totally encompases the segment and there is no segment left
// 1 if the sphere does not touch the segment or if the sphere cuts one end of the input segment
// 2 if the sphere cuts in the middle of the segment and there are two resulting segments
CFIndex NIIntersectionSegmentDivideWithSphere(NIIntersectionSegment segment, NIVector sphereCenter, CGFloat sphereRadius, NIIntersectionSegmentPointer resultingSegment1, NIIntersectionSegmentPointer resultingSegment2);


NIIntersectionSegment NIIntersectionSegmentMake(NIVector start, NIVector end)
{
    NIIntersectionSegment segment;
    segment.start = start;
    segment.end = end;
    return segment;
}

CGFloat NIIntersectionSegmentLength(NIIntersectionSegment segment)
{
    return NIVectorLength(NIVectorSubtract(segment.end, segment.start));
}

NIVector NIIntersectionSegmentDirection(NIIntersectionSegment segment)
{
    return NIVectorNormalize(NIVectorSubtract(segment.end, segment.start));
}

NIIntersectionSegment NIIntersectionSegmentApplyTransform(NIIntersectionSegment segment, NIAffineTransform transform)
{
    NIIntersectionSegment transformedSegment;
    transformedSegment.start = NIVectorApplyTransform(segment.start, transform);
    transformedSegment.end = NIVectorApplyTransform(segment.end, transform);
    return transformedSegment;
}

CGFloat NIIntersectionSegmentVectorSituation(NIIntersectionSegment segment, NIVector vector)
{
    CGFloat segmentLength = NIIntersectionSegmentLength(segment);
    if (segmentLength == 0) {
        return -1;
    }

    CGFloat dotProduct = NIVectorDotProduct(NIVectorSubtract(vector, segment.start), NIIntersectionSegmentDirection(segment));
    if (dotProduct < 0) {
        return 0;
    } else if (dotProduct < segmentLength) {
        return dotProduct / segmentLength;
    } else {
        return 1;
    }
}

CFIndex NIIntersectionSegmentDivideWithSphere(NIIntersectionSegment segment, NIVector sphereCenter, CGFloat sphereRadius, NIIntersectionSegmentPointer resultingSegment1, NIIntersectionSegmentPointer resultingSegment2)
{
    if (NIIntersectionSegmentLength(segment) == 0) {
        return 0;
    }

    NILine line = NILineMake(segment.start, NIIntersectionSegmentDirection(segment));
    NIVector firstIntersection = NIVectorZero;
    NIVector secondIntersection = NIVectorZero;

    CFIndex intersections = NILineIntersectionWithSphere(line, sphereCenter, sphereRadius, &firstIntersection, &secondIntersection);
    if (intersections < 2) { // the sphere in nowhere near the segment, no need to cut it
        if (resultingSegment1 != NULL) {
            *resultingSegment1 = segment;
        }
        if (resultingSegment2 != NULL) {
            *resultingSegment2 = segment;
        }
        return 1;
    }

    CGFloat intersectionSituation1 = NIIntersectionSegmentVectorSituation(segment, firstIntersection);
    CGFloat intersectionSituation2 = NIIntersectionSegmentVectorSituation(segment, secondIntersection);
    if (intersectionSituation2 < intersectionSituation1) { // put them in order
        CGFloat temp = intersectionSituation1;
        intersectionSituation1 = intersectionSituation2;
        intersectionSituation2 = temp;
        NIVector tempVector = firstIntersection;
        firstIntersection = secondIntersection;
        secondIntersection = tempVector;
    }

    if (intersectionSituation1 == 0 && intersectionSituation2 == 1) { // the sphere straddles the segment, remove the segment
        return 0;
    } else if ((intersectionSituation1 == 0 && intersectionSituation2 == 0) || (intersectionSituation1 == 1 && intersectionSituation2 == 1)) { // intersects the shere before or after the segment, do nothing
        if (resultingSegment1 != NULL) {
            *resultingSegment1 = segment;
        }
        if (resultingSegment2 != NULL) {
            *resultingSegment2 = segment;
        }
        return 1;
    } else if (intersectionSituation1 == 0) { // trim the front
        *resultingSegment1 = segment;
        resultingSegment1->start = secondIntersection;
        return 1;
    } else if (intersectionSituation2 == 1) { // trim the end
        *resultingSegment1 = segment;
        resultingSegment1->end = firstIntersection;
        return 1;
    } else { // cut it in 2
        *resultingSegment1 = segment;
        resultingSegment1->end = firstIntersection;
        *resultingSegment2 = segment;
        resultingSegment2->start = secondIntersection;
        return 2;
    }

    assert(false); // this should never happen
    return 0;
}


CF_EXTERN_C_END


@implementation NIObliqueSliceIntersectionLayer

@synthesize rimPath = _rimPath;
@synthesize gapAroundMouse = _gapAroundMouse;
@synthesize gapAroundPosition = _gapAroundPosition;
@synthesize centerBulletPoint = _centerBulletPoint;
@synthesize intersectionDashingLengths = _intersectionDashingLengths;

@dynamic sliceToModelTransform;
@dynamic mouseGapPosition;
@dynamic mouseGapRadius;
@dynamic centerBulletPointRadius;
@dynamic gapPosition;
@dynamic gapRadius;

+ (id)defaultValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"sliceToModelTransform"]) {
        return [NSValue valueWithNIAffineTransform:NIAffineTransformIdentity];
    } else {
        return [super defaultValueForKey:key];
    }
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"sliceToModelTransform"]) {
        return YES;
    } else if ([key isEqualToString:@"mouseGapPosition"]) {
        return YES;
    } else if ([key isEqualToString:@"mouseGapRadius"]) {
        return YES;
    } else if ([key isEqualToString:@"gapPosition"]) {
        return YES;
    } else if ([key isEqualToString:@"gapRadius"]) {
        return YES;
    } else if ([key isEqualToString:@"centerBulletPointRadius"]) {
        return YES;
    } else {
        return [super needsDisplayForKey:key];
    }
}

- (instancetype)initWithLayer:(id)layer
{
    if ( (self = [super initWithLayer:layer]) ) {
        if ([layer isKindOfClass:[NIObliqueSliceIntersectionLayer class]]) {
            NIObliqueSliceIntersectionLayer *intersectionLayer = (NIObliqueSliceIntersectionLayer *)layer;
            _rimPath = [intersectionLayer.rimPath copy];
            _gapAroundMouse = intersectionLayer.gapAroundMouse;
            _gapAroundPosition = intersectionLayer.gapAroundPosition;
            _centerBulletPoint = intersectionLayer.centerBulletPoint;
            _intersectionDashingLengths = [intersectionLayer.intersectionDashingLengths copy];
        }
    }

    return self;
}

- (void)dealloc
{
    [_rimPath release];
    _rimPath = 0;
    [_intersectionDashingLengths release];
    _intersectionDashingLengths = nil;

    [super dealloc];
}

- (NSColor *)intersectionColor
{
    return [NSColor colorWithCGColor:self.strokeColor];
}

- (void)setIntersectionColor:(NSColor *)intersectionColor
{
    self.strokeColor = [intersectionColor CGColor];
    self.fillColor = [intersectionColor CGColor];
}

- (void)setIntersectionThickness:(CGFloat)intersectionThickness
{
    self.lineWidth = intersectionThickness;
}

- (CGFloat)intersectionThickness
{
    return self.lineWidth;
}

- (void)setIntersectionDashingLengths:(NSArray<NSNumber *> *)intersectionDashingLengths
{
    if (_intersectionDashingLengths != intersectionDashingLengths) {
        [_intersectionDashingLengths release];
        _intersectionDashingLengths = [intersectionDashingLengths copy];
        [self setNeedsDisplay];
    }
}

- (void)setRimPath:(NIBezierPath *)rimPath
{
    if (_rimPath != rimPath) {
        [_rimPath release];
        _rimPath = [rimPath retain];
        [self setNeedsDisplay];
    }
}

- (void)setGapAroundMouse:(BOOL)gapAroundMouse
{
    if (_gapAroundMouse != gapAroundMouse) {
        _gapAroundMouse = gapAroundMouse;
        [self setNeedsDisplay];
    }
}

- (void)setGapAroundPosition:(BOOL)gapAroundPosition
{
    if (_gapAroundPosition != gapAroundPosition) {
        _gapAroundPosition = gapAroundPosition;
        [self setNeedsDisplay];
    }
}

- (void)setCenterBulletPoint:(BOOL)centerBulletPoint
{
    if (_centerBulletPoint != centerBulletPoint) {
        _centerBulletPoint = centerBulletPoint;
        [self setNeedsDisplay];
    }
}

- (NIVector)origin
{
    NIAffineTransform sliceToModelTransform = self.sliceToModelTransform;
    return NIVectorMake(sliceToModelTransform.m41, sliceToModelTransform.m42, sliceToModelTransform.m43);
}

- (void)setOrigin:(NIVector)origin
{
    NIAffineTransform sliceToModelTransform = self.sliceToModelTransform;
    sliceToModelTransform.m41 = origin.x;
    sliceToModelTransform.m42 = origin.y;
    sliceToModelTransform.m43 = origin.z;
    self.sliceToModelTransform = sliceToModelTransform;
}

- (NIVector)directionX
{
    NIAffineTransform sliceToModelTransform = self.sliceToModelTransform;
    return NIVectorNormalize(NIVectorMake(sliceToModelTransform.m11, sliceToModelTransform.m12, sliceToModelTransform.m13));
}

- (void)setDirectionX:(NIVector)directionX
{
    directionX = NIVectorScalarMultiply(NIVectorNormalize(directionX), self.pointSpacingX);
    NIAffineTransform sliceToModelTransform = self.sliceToModelTransform;
    sliceToModelTransform.m11 = directionX.x;
    sliceToModelTransform.m12 = directionX.y;
    sliceToModelTransform.m13 = directionX.z;

    NIVector directionZ = NIVectorNormalize(NIVectorCrossProduct(directionX, self.directionY));
    sliceToModelTransform.m31 = directionZ.x;
    sliceToModelTransform.m32 = directionZ.y;
    sliceToModelTransform.m33 = directionZ.z;

    self.sliceToModelTransform = sliceToModelTransform;
}

- (NIVector)directionY
{
    NIAffineTransform sliceToModelTransform = self.sliceToModelTransform;
    return NIVectorNormalize(NIVectorMake(sliceToModelTransform.m21, sliceToModelTransform.m22, sliceToModelTransform.m23));
}

- (void)setDirectionY:(NIVector)directionY
{
    directionY = NIVectorScalarMultiply(NIVectorNormalize(directionY), self.pointSpacingY);
    NIAffineTransform sliceToModelTransform = self.sliceToModelTransform;
    sliceToModelTransform.m21 = directionY.x;
    sliceToModelTransform.m22 = directionY.y;
    sliceToModelTransform.m23 = directionY.z;

    NIVector directionZ = NIVectorNormalize(NIVectorCrossProduct(self.directionX, directionY));
    sliceToModelTransform.m31 = directionZ.x;
    sliceToModelTransform.m32 = directionZ.y;
    sliceToModelTransform.m33 = directionZ.z;

    self.sliceToModelTransform = sliceToModelTransform;
}

- (CGFloat)pointSpacingX
{
    NIAffineTransform sliceToModelTransform = self.sliceToModelTransform;
    return NIVectorLength(NIVectorMake(sliceToModelTransform.m11, sliceToModelTransform.m12, sliceToModelTransform.m13));
}

- (void)setPointSpacingX:(CGFloat)pointSpacingX
{
    NIVector basisX = NIVectorScalarMultiply(self.directionX, pointSpacingX);
    NIAffineTransform sliceToModelTransform = self.sliceToModelTransform;
    sliceToModelTransform.m11 = basisX.x;
    sliceToModelTransform.m12 = basisX.y;
    sliceToModelTransform.m13 = basisX.z;

    self.sliceToModelTransform = sliceToModelTransform;
}

- (CGFloat)pointSpacingY
{
    NIAffineTransform sliceToModelTransform = self.sliceToModelTransform;
    return NIVectorLength(NIVectorMake(sliceToModelTransform.m21, sliceToModelTransform.m22, sliceToModelTransform.m23));
}

- (void)setPointSpacingY:(CGFloat)pointSpacingY
{
    NIVector basisY = NIVectorScalarMultiply(self.directionY, pointSpacingY);
    NIAffineTransform sliceToModelTransform = self.sliceToModelTransform;
    sliceToModelTransform.m21 = basisY.x;
    sliceToModelTransform.m22 = basisY.y;
    sliceToModelTransform.m23 = basisY.z;

    self.sliceToModelTransform = sliceToModelTransform;
}

- (void)display
{
    NSInteger i;

    if (self.pointSpacingX == 0 || self.pointSpacingX == 0 || _rimPath == nil) {
        self.path = NULL;
        return;
    }

    NIPlane plane = NIPlaneMake(self.origin, NIVectorCrossProduct(self.directionX, self.directionY));
    NSArray<NSValue *> *intersections = [_rimPath intersectionsWithPlane:plane];

    NSMutableArray *segments = [NSMutableArray array];
    NIIntersectionSegment segment;
    NIAffineTransform modelToSliceTransform = NIAffineTransformInvert(self.sliceToModelTransform);
    for (i = 0; i < [intersections count]; i++) {
        if (i % 2) {
            segment.end = [intersections[i] NIVectorValue];
            segment = NIIntersectionSegmentApplyTransform(segment, modelToSliceTransform); // transform the intersection into points within the layer
            segment.start.z = 0;
            segment.end.z = 0;
            [segments addObject:[NSValue valueWithNIIntersectionSegment:segment]];
        } else {
            segment.start = [intersections[i] NIVectorValue];
        }
    }

    NSMutableArray *dividedSegments = nil;
    if (self.gapAroundMouse) {
        dividedSegments = [NSMutableArray array];
        for (i = 0; i < [segments count]; i++) {
            NIIntersectionSegment firstSegment;
            NIIntersectionSegment secondSegment;
            NSInteger segmentCount = NIIntersectionSegmentDivideWithSphere([segments[i] NIIntersectionSegmentValue], NIVectorMakeFromNSPoint(self.mouseGapPosition), self.mouseGapRadius,
                                                                            &firstSegment, &secondSegment);
            if (segmentCount > 0) {
                [dividedSegments addObject:[NSValue valueWithNIIntersectionSegment:firstSegment]];
            }
            if (segmentCount > 1) {
                [dividedSegments addObject:[NSValue valueWithNIIntersectionSegment:secondSegment]];
            }
        }
        segments = dividedSegments;
    }

    if (self.gapAroundPosition) {
        dividedSegments = [NSMutableArray array];
        for (i = 0; i < [segments count]; i++) {
            NIIntersectionSegment firstSegment;
            NIIntersectionSegment secondSegment;
            NSInteger segmentCount = NIIntersectionSegmentDivideWithSphere([segments[i] NIIntersectionSegmentValue], NIVectorMakeFromNSPoint(self.gapPosition), self.gapRadius,
                                                                            &firstSegment, &secondSegment);
            if (segmentCount > 0) {
                [dividedSegments addObject:[NSValue valueWithNIIntersectionSegment:firstSegment]];
            }
            if (segmentCount > 1) {
                [dividedSegments addObject:[NSValue valueWithNIIntersectionSegment:secondSegment]];
            }
        }
        segments = dividedSegments;
    }

    CGMutablePathRef path = CGPathCreateMutable();
    for (i = 0; i < [segments count]; i++) {
        NIIntersectionSegment dividedGapSegment = [segments[i] NIIntersectionSegmentValue];

        CGPathMoveToPoint(path, NULL, dividedGapSegment.start.x, dividedGapSegment.start.y);
        CGPathAddLineToPoint(path, NULL, dividedGapSegment.end.x, dividedGapSegment.end.y);
    }

    if (self.intersectionDashingLengths) {
        CGFloat *dashingFloat = malloc([self.intersectionDashingLengths count] * sizeof(CGFloat));
        for (i = 0; i < [self.intersectionDashingLengths count]; i++) {
            dashingFloat[i] = (CGFloat)[self.intersectionDashingLengths[i] doubleValue];
        }
        CGPathRef dashedPath = CGPathCreateCopyByDashingPath(path, NULL, 0, dashingFloat, [self.intersectionDashingLengths count]);
        CGPathRelease(path);
        path = CGPathCreateMutableCopy(dashedPath);
        CGPathRelease(dashedPath);
        free(dashingFloat);
    }

    if (self.centerBulletPoint && [intersections count] >= 2) {
        NIVector center = NIVectorApplyTransform(NIVectorLerp([intersections[0] NIVectorValue], [intersections.lastObject NIVectorValue], .5), modelToSliceTransform);
        CGRect centerBulletRect = CGRectMake(center.x - self.centerBulletPointRadius/2.0, center.y - self.centerBulletPointRadius/2.0,
                                       self.centerBulletPointRadius, self.centerBulletPointRadius);
        CGPathAddEllipseInRect(path, NULL, centerBulletRect);
    }
    
    self.path = path;
    CGPathRelease(path);
}


@end
