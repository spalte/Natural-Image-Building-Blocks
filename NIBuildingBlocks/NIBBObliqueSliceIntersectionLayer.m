//  Created by Joël Spaltenstein on 4/24/15.
//  Copyright (c) 2015 Spaltenstein Natural Image
//  Copyright (c) 2015 Michael Hilker and Andreas Holzamer
//  Copyright (c) 2015 volz io
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


#import "NIBBObliqueSliceIntersectionLayer.h"

CF_EXTERN_C_BEGIN

struct NIBBIntersectionSegment {
    NIBBVector start;
    NIBBVector end;
};
typedef struct NIBBIntersectionSegment NIBBIntersectionSegment;
typedef NIBBIntersectionSegment *NIBBIntersectionSegmentPointer;

@interface NSValue (NIBBIntersectionSegmentAdditions)
+ (NSValue *)valueWithNIBBIntersectionSegment:(NIBBIntersectionSegment)segment;
@property (readonly) NIBBIntersectionSegment NIBBIntersectionSegmentValue;
@end

@implementation NSValue (NIBBIntersectionSegmentAdditions)
+ (NSValue *)valueWithNIBBIntersectionSegment:(NIBBIntersectionSegment)segment;
{
    return [NSValue valueWithBytes:&segment objCType:@encode(NIBBIntersectionSegment)];
}

- (NIBBIntersectionSegment)NIBBIntersectionSegmentValue;
{
    NIBBIntersectionSegment segment;
    assert(strcmp([self objCType], @encode(NIBBIntersectionSegment)) == 0);
    [self getValue:&segment];
    return segment;
}
@end

NIBBIntersectionSegment NIBBIntersectionSegmentMake(NIBBVector start, NIBBVector end);
//NIBBIntersectionSegment NIBBIntersectionSegmentMakeFromVectors(NIBBVector vector1, NIBBVector vector2);

CGFloat NIBBIntersectionSegmentLength(NIBBIntersectionSegment segment);
NIBBVector NIBBIntersectionSegmentDirection(NIBBIntersectionSegment segment);
NIBBIntersectionSegment NIBBIntersectionSegmentApplyTransform(NIBBIntersectionSegment segment, NIBBAffineTransform transform);

// projects the vector onto the segment and returns
// -1 if the segment has length 0
// 0 if the vector is before the segment
// within (0, 1) if the vector is within the segment
// 1 if the vector is afer the segment
CGFloat NIBBIntersectionSegmentVectorSituation(NIBBIntersectionSegment segment, NIBBVector vector);

// returns the number of resulting segments, whis is also the number of resulting segments set
// 0 if the sphere totally encompases the segment and there is no segment left
// 1 if the sphere does not touch the segment or if the sphere cuts one end of the input segment
// 2 if the sphere cuts in the middle of the segment and there are two resulting segments
CFIndex NIBBIntersectionSegmentDivideWithSphere(NIBBIntersectionSegment segment, NIBBVector sphereCenter, CGFloat sphereRadius, NIBBIntersectionSegmentPointer resultingSegment1, NIBBIntersectionSegmentPointer resultingSegment2);


NIBBIntersectionSegment NIBBIntersectionSegmentMake(NIBBVector start, NIBBVector end)
{
    NIBBIntersectionSegment segment;
    segment.start = start;
    segment.end = end;
    return segment;
}

CGFloat NIBBIntersectionSegmentLength(NIBBIntersectionSegment segment)
{
    return NIBBVectorLength(NIBBVectorSubtract(segment.end, segment.start));
}

NIBBVector NIBBIntersectionSegmentDirection(NIBBIntersectionSegment segment)
{
    return NIBBVectorNormalize(NIBBVectorSubtract(segment.end, segment.start));
}

NIBBIntersectionSegment NIBBIntersectionSegmentApplyTransform(NIBBIntersectionSegment segment, NIBBAffineTransform transform)
{
    NIBBIntersectionSegment transformedSegment;
    transformedSegment.start = NIBBVectorApplyTransform(segment.start, transform);
    transformedSegment.end = NIBBVectorApplyTransform(segment.end, transform);
    return transformedSegment;
}

CGFloat NIBBIntersectionSegmentVectorSituation(NIBBIntersectionSegment segment, NIBBVector vector)
{
    CGFloat segmentLength = NIBBIntersectionSegmentLength(segment);
    if (segmentLength == 0) {
        return -1;
    }

    CGFloat dotProduct = NIBBVectorDotProduct(NIBBVectorSubtract(vector, segment.start), NIBBIntersectionSegmentDirection(segment));
    if (dotProduct < 0) {
        return 0;
    } else if (dotProduct < segmentLength) {
        return dotProduct / segmentLength;
    } else {
        return 1;
    }
}

CFIndex NIBBIntersectionSegmentDivideWithSphere(NIBBIntersectionSegment segment, NIBBVector sphereCenter, CGFloat sphereRadius, NIBBIntersectionSegmentPointer resultingSegment1, NIBBIntersectionSegmentPointer resultingSegment2)
{
    if (NIBBIntersectionSegmentLength(segment) == 0) {
        return 0;
    }

    NIBBLine line = NIBBLineMake(segment.start, NIBBIntersectionSegmentDirection(segment));
    NIBBVector firstIntersection = NIBBVectorZero;
    NIBBVector secondIntersection = NIBBVectorZero;

    CFIndex intersections = NIBBLineIntersectionWithSphere(line, sphereCenter, sphereRadius, &firstIntersection, &secondIntersection);
    if (intersections < 2) { // the sphere in nowhere near the segment, no need to cut it
        if (resultingSegment1 != NULL) {
            *resultingSegment1 = segment;
        }
        if (resultingSegment2 != NULL) {
            *resultingSegment2 = segment;
        }
        return 1;
    }

    CGFloat intersectionSituation1 = NIBBIntersectionSegmentVectorSituation(segment, firstIntersection);
    CGFloat intersectionSituation2 = NIBBIntersectionSegmentVectorSituation(segment, secondIntersection);
    if (intersectionSituation2 < intersectionSituation1) { // put them in order
        CGFloat temp = intersectionSituation1;
        intersectionSituation1 = intersectionSituation2;
        intersectionSituation2 = temp;
        NIBBVector tempVector = firstIntersection;
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


@implementation NIBBObliqueSliceIntersectionLayer

@synthesize rimPath = _rimPath;
@synthesize gapAroundMouse = _gapAroundMouse;
@synthesize gapAroundPosition = _gapAroundPosition;

@dynamic sliceToDicomTransform;
@dynamic mouseGapPosition;
@dynamic mouseGapRadius;
@dynamic gapPosition;
@dynamic gapRadius;

+ (id)defaultValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"sliceToDicomTransform"]) {
        return [NSValue valueWithNIBBAffineTransform:NIBBAffineTransformIdentity];
    } else {
        return [super defaultValueForKey:key];
    }
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"sliceToDicomTransform"]) {
        return YES;
    } else if ([key isEqualToString:@"mouseGapPosition"]) {
        return YES;
    } else if ([key isEqualToString:@"mouseGapRadius"]) {
        return YES;
    } else if ([key isEqualToString:@"gapPosition"]) {
        return YES;
    } else if ([key isEqualToString:@"gapRadius"]) {
        return YES;
    } else {
        return [super needsDisplayForKey:key];
    }
}

- (instancetype)initWithLayer:(id)layer
{
    if ( (self = [super initWithLayer:layer]) ) {
        if ([layer isKindOfClass:[NIBBObliqueSliceIntersectionLayer class]]) {
            NIBBObliqueSliceIntersectionLayer *intersectionLayer = (NIBBObliqueSliceIntersectionLayer *)layer;
            _rimPath = [intersectionLayer.rimPath copy];
            _gapAroundMouse = intersectionLayer.gapAroundMouse;
            _gapAroundPosition = intersectionLayer.gapAroundPosition;
        }
    }

    return self;
}

- (void)dealloc
{
    [_rimPath release];
    _rimPath = 0;

    [super dealloc];
}

- (NSColor *)intersectionColor
{
    return [NSColor colorWithCGColor:self.strokeColor];
}

- (void)setIntersectionColor:(NSColor *)intersectionColor
{
    self.strokeColor = [intersectionColor CGColor];
}

- (void)setIntersectionThickness:(CGFloat)intersectionThickness
{
    self.lineWidth = intersectionThickness;
}

- (CGFloat)intersectionThickness
{
    return self.lineWidth;
}

- (void)setRimPath:(NIBBBezierPath *)rimPath
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

- (NIBBVector)origin
{
    NIBBAffineTransform sliceToDicomTransform = self.sliceToDicomTransform;
    return NIBBVectorMake(sliceToDicomTransform.m41, sliceToDicomTransform.m42, sliceToDicomTransform.m43);
}

- (void)setOrigin:(NIBBVector)origin
{
    NIBBAffineTransform sliceToDicomTransform = self.sliceToDicomTransform;
    sliceToDicomTransform.m41 = origin.x;
    sliceToDicomTransform.m42 = origin.y;
    sliceToDicomTransform.m43 = origin.z;
    self.sliceToDicomTransform = sliceToDicomTransform;
}

- (NIBBVector)directionX
{
    NIBBAffineTransform sliceToDicomTransform = self.sliceToDicomTransform;
    return NIBBVectorNormalize(NIBBVectorMake(sliceToDicomTransform.m11, sliceToDicomTransform.m12, sliceToDicomTransform.m13));
}

- (void)setDirectionX:(NIBBVector)directionX
{
    directionX = NIBBVectorScalarMultiply(NIBBVectorNormalize(directionX), self.pointSpacingX);
    NIBBAffineTransform sliceToDicomTransform = self.sliceToDicomTransform;
    sliceToDicomTransform.m11 = directionX.x;
    sliceToDicomTransform.m11 = directionX.y;
    sliceToDicomTransform.m11 = directionX.z;

    NIBBVector directionZ = NIBBVectorNormalize(NIBBVectorCrossProduct(directionX, self.directionY));
    sliceToDicomTransform.m31 = directionZ.x;
    sliceToDicomTransform.m31 = directionZ.y;
    sliceToDicomTransform.m31 = directionZ.z;

    self.sliceToDicomTransform = sliceToDicomTransform;
}

- (NIBBVector)directionY
{
    NIBBAffineTransform sliceToDicomTransform = self.sliceToDicomTransform;
    return NIBBVectorNormalize(NIBBVectorMake(sliceToDicomTransform.m21, sliceToDicomTransform.m22, sliceToDicomTransform.m23));
}

- (void)setDirectionY:(NIBBVector)directionY
{
    directionY = NIBBVectorScalarMultiply(NIBBVectorNormalize(directionY), self.pointSpacingY);
    NIBBAffineTransform sliceToDicomTransform = self.sliceToDicomTransform;
    sliceToDicomTransform.m21 = directionY.x;
    sliceToDicomTransform.m21 = directionY.y;
    sliceToDicomTransform.m21 = directionY.z;

    NIBBVector directionZ = NIBBVectorNormalize(NIBBVectorCrossProduct(self.directionX, directionY));
    sliceToDicomTransform.m31 = directionZ.x;
    sliceToDicomTransform.m31 = directionZ.y;
    sliceToDicomTransform.m31 = directionZ.z;

    self.sliceToDicomTransform = sliceToDicomTransform;
}

- (CGFloat)pointSpacingX
{
    NIBBAffineTransform sliceToDicomTransform = self.sliceToDicomTransform;
    return NIBBVectorLength(NIBBVectorMake(sliceToDicomTransform.m11, sliceToDicomTransform.m12, sliceToDicomTransform.m13));
}

- (void)setPointSpacingX:(CGFloat)pointSpacingX
{
    NIBBVector basisX = NIBBVectorScalarMultiply(self.directionX, pointSpacingX);
    NIBBAffineTransform sliceToDicomTransform = self.sliceToDicomTransform;
    sliceToDicomTransform.m11 = basisX.x;
    sliceToDicomTransform.m11 = basisX.y;
    sliceToDicomTransform.m11 = basisX.z;

    self.sliceToDicomTransform = sliceToDicomTransform;
}

- (CGFloat)pointSpacingY
{
    NIBBAffineTransform sliceToDicomTransform = self.sliceToDicomTransform;
    return NIBBVectorLength(NIBBVectorMake(sliceToDicomTransform.m21, sliceToDicomTransform.m22, sliceToDicomTransform.m23));
}

- (void)setPointSpacingY:(CGFloat)pointSpacingY
{
    NIBBVector basisY = NIBBVectorScalarMultiply(self.directionY, pointSpacingY);
    NIBBAffineTransform sliceToDicomTransform = self.sliceToDicomTransform;
    sliceToDicomTransform.m21 = basisY.x;
    sliceToDicomTransform.m21 = basisY.y;
    sliceToDicomTransform.m21 = basisY.z;

    self.sliceToDicomTransform = sliceToDicomTransform;
}

- (void)display
{
    NSInteger i;

    if (self.pointSpacingX == 0 || self.pointSpacingX == 0) {
        self.path = NULL;
        return;
    }

    NIBBPlane plane = NIBBPlaneMake(self.origin, NIBBVectorCrossProduct(self.directionX, self.directionY));
    NSArray *intersections = [_rimPath intersectionsWithPlane:plane];

    NSMutableArray *segments = [NSMutableArray array];
    NIBBIntersectionSegment segment;
    NIBBAffineTransform dicomToSliceTransform = NIBBAffineTransformInvert(self.sliceToDicomTransform);
    for (i = 0; i < [intersections count]; i++) {
        if (i % 2) {
            segment.end = [intersections[i] NIBBVectorValue];
            segment = NIBBIntersectionSegmentApplyTransform(segment, dicomToSliceTransform); // transform the intersection into points within the layer
            segment.start.z = 0;
            segment.end.z = 0;
            [segments addObject:[NSValue valueWithNIBBIntersectionSegment:segment]];
        } else {
            segment.start = [intersections[i] NIBBVectorValue];
        }
    }

    NSMutableArray *dividedSegments = nil;
    if (self.gapAroundMouse) {
        dividedSegments = [NSMutableArray array];
        for (i = 0; i < [segments count]; i++) {
            NIBBIntersectionSegment firstSegment;
            NIBBIntersectionSegment secondSegment;
            NSInteger segmentCount = NIBBIntersectionSegmentDivideWithSphere([segments[i] NIBBIntersectionSegmentValue], NIBBVectorMakeFromNSPoint(self.mouseGapPosition), self.mouseGapRadius,
                                                                            &firstSegment, &secondSegment);
            if (segmentCount > 0) {
                [dividedSegments addObject:[NSValue valueWithNIBBIntersectionSegment:firstSegment]];
            }
            if (segmentCount > 1) {
                [dividedSegments addObject:[NSValue valueWithNIBBIntersectionSegment:secondSegment]];
            }
        }
        segments = dividedSegments;
    }

    if (self.gapAroundPosition) {
        dividedSegments = [NSMutableArray array];
        for (i = 0; i < [segments count]; i++) {
            NIBBIntersectionSegment firstSegment;
            NIBBIntersectionSegment secondSegment;
            NSInteger segmentCount = NIBBIntersectionSegmentDivideWithSphere([segments[i] NIBBIntersectionSegmentValue], NIBBVectorMakeFromNSPoint(self.gapPosition), self.gapRadius,
                                                                            &firstSegment, &secondSegment);
            if (segmentCount > 0) {
                [dividedSegments addObject:[NSValue valueWithNIBBIntersectionSegment:firstSegment]];
            }
            if (segmentCount > 1) {
                [dividedSegments addObject:[NSValue valueWithNIBBIntersectionSegment:secondSegment]];
            }
        }
        segments = dividedSegments;
    }

    CGMutablePathRef path = CGPathCreateMutable();
    for (i = 0; i < [segments count]; i++) {
        NIBBIntersectionSegment dividedGapSegment = [segments[i] NIBBIntersectionSegmentValue];

        CGPathMoveToPoint(path, NULL, dividedGapSegment.start.x, dividedGapSegment.start.y);
        CGPathAddLineToPoint(path, NULL, dividedGapSegment.end.x, dividedGapSegment.end.y);
    }

    self.path = path;
    CGPathRelease(path);
}


@end
