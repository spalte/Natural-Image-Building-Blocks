//  Created by Joël Spaltenstein on 4/29/15.
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

#import "NIBBAnnularPath.h"
#import "NIBBGeneratorRequest.h"
#import "NIBBBezierPath.h"
#import "NSBezierPath+NIBBAdditions.h"

@interface NIBBAnnularPath ()
- (BOOL)_isCircleWithCenter:(NIBBVectorPointer)center radius:(CGFloat *)radius;
@end

@implementation NIBBAnnularPath

@synthesize annularOrigin = _annularOrigin;
@synthesize axialDirection = _axialDirection;

- (instancetype)initWithAnnularOrigin:(NIBBVector)annularOrigin axialDirection:(NIBBVector)axialDirection;
{
    if ( (self = [super init]) ) {
        _annularOrigin = annularOrigin;
        _axialDirection = axialDirection;
        _controlPoints = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_controlPoints release];
    _controlPoints = nil;

    [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    NIBBAnnularPath *copy = [[NIBBAnnularPath allocWithZone:zone] initWithAnnularOrigin:_annularOrigin axialDirection:_axialDirection];
    for (NSValue *value in [_controlPoints allValues]) {
        [copy addControlPointAtPosition:[value NIBBVectorValue]];
    }
    return copy;
}

- (NIBBPlane)plane
{
    return NIBBPlaneMake(_annularOrigin, _axialDirection);
}

- (NIBBBezierPath *)bezierpath
{
    NIBBVector center = NIBBVectorZero;
    CGFloat radius = 0;

    if ([self _isCircleWithCenter:&center radius:&radius]) {
        return [NIBBBezierPath bezierPathCircleWithCenter:center radius:radius normal:_axialDirection];
    } else {
        NSMutableArray *orderedControlPointPositions = [NSMutableArray arrayWithArray:[self orderedControlPointPositions]];
        [orderedControlPointPositions addObject:orderedControlPointPositions[0]];
        NIBBMutableBezierPath *bezierPath = [[[NIBBMutableBezierPath alloc] initWithNodeArray:orderedControlPointPositions style:NIBBBezierNodeEndsMeetStyle] autorelease];
        [bezierPath close];

        return bezierPath;
    }
}


- (void)diameterMinStart:(NIBBVectorPointer)minStart minEnd:(NIBBVectorPointer)minEnd maxStart:(NIBBVectorPointer)maxStart maxEnd:(NIBBVectorPointer)maxEnd
{
    NIBBVector center = NIBBVectorZero;
    CGFloat radius = 0;

    if ([self _isCircleWithCenter:&center radius:&radius]) {
        if (minStart) {
            *minStart = NIBBVectorAdd(center, NIBBVectorScalarMultiply(NIBBVectorANormalVector(_axialDirection), -radius));
        }
        if (minEnd) {
            *minEnd = NIBBVectorAdd(center, NIBBVectorScalarMultiply(NIBBVectorANormalVector(_axialDirection), radius));
        }
        if (maxStart) {
            *maxStart = NIBBVectorAdd(center, NIBBVectorScalarMultiply(NIBBVectorCrossProduct(NIBBVectorANormalVector(_axialDirection), _axialDirection), -radius));
        }
        if (maxEnd) {
            *maxEnd = NIBBVectorAdd(center, NIBBVectorScalarMultiply(NIBBVectorCrossProduct(NIBBVectorANormalVector(_axialDirection), _axialDirection), radius));
        }
    } else {
        NIBBBezierPath *bezierPath = [self bezierpath];
        NIBBVector rotationAxis = NIBBVectorCrossProduct(_axialDirection, NIBBVectorMake(0, 0, 1));
        CGFloat rotationAngle = asin(NIBBVectorLength(rotationAxis));
        if (NIBBVectorIsZero(rotationAxis)) {
            rotationAxis = NIBBVectorANormalVector(rotationAxis);
        } else {
            rotationAxis = NIBBVectorNormalize(rotationAxis);
        }
        if (NIBBVectorDotProduct(_axialDirection, NIBBVectorMake(0, 0, 1)) < 0) {
            rotationAngle = M_PI - rotationAngle;
        }

        NIBBAffineTransform transform = NIBBAffineTransformMakeRotationAroundVector(rotationAngle, rotationAxis);
        NSBezierPath *nsBezierPath = [[[bezierPath bezierPathByApplyingTransform:transform] bezierPathBySubdividing:1] NSBezierPath];

        NSPoint minStartPoint = NSZeroPoint;
        NSPoint minEndPoint = NSZeroPoint;
        NSPoint maxStartPoint = NSZeroPoint;
        NSPoint maxEndPoint = NSZeroPoint;

        NIBBAffineTransform inverseTransform = NIBBAffineTransformInvert(transform);
        [nsBezierPath diameterMinStart:&minStartPoint minEnd:&minEndPoint maxStart:&maxStartPoint maxEnd:&maxEndPoint];
        if (minStart) {
            *minStart = NIBBVectorApplyTransform(NIBBVectorMakeFromNSPoint(minStartPoint), inverseTransform);
        }
        if (minEnd) {
            *minEnd = NIBBVectorApplyTransform(NIBBVectorMakeFromNSPoint(minEndPoint), inverseTransform);
        }
        if (maxStart) {
            *maxStart = NIBBVectorApplyTransform(NIBBVectorMakeFromNSPoint(maxStartPoint), inverseTransform);
        }
        if (maxEnd) {
            *maxEnd = NIBBVectorApplyTransform(NIBBVectorMakeFromNSPoint(maxEndPoint), inverseTransform);
        }
    }
}

- (CGFloat)perimeter
{
    return [self.bezierpath length];
}

- (CGFloat)area
{
    return [self.bezierpath signedAreaUsingNormal:_axialDirection];
}

- (NIBBAnnularPathControlPointID)addControlPointAtPosition:(NIBBVector)position
{
    // project the position onto the plane
    position = NIBBPlanePointClosestToVector(self.plane, position);

    NIBBAnnularPathControlPointID controlPoinID = [self controlPointIDForControlPointNearPosition:position];

    if (controlPoinID != -1) {
        [self setPosition:position forControlPointID:controlPoinID];
        return controlPoinID;
    } else {
        [_controlPoints setObject:[NSValue valueWithNIBBVector:position] forKey:@(++_idCounter)];
        return _idCounter;
    }
}

- (void)setPosition:(NIBBVector)position forControlPointID:(NIBBAnnularPathControlPointID)controlPointID
{
    // project the position onto the plane
    position = NIBBPlanePointClosestToVector(self.plane, position);

    NIBBVector previousPosotion = [self positionForControlPointID:controlPointID];
    [_controlPoints removeObjectForKey:@(controlPointID)];

    if ([self controlPointIDForControlPointNearPosition:position] != -1) { // don't allow the point to get to close to another point, so bail out and reset the state
        [_controlPoints setObject:[NSValue valueWithNIBBVector:previousPosotion] forKey:@(controlPointID)];
    } else {
        [_controlPoints setObject:[NSValue valueWithNIBBVector:position] forKey:@(controlPointID)];
    }
}

- (NIBBVector)positionForControlPointID:(NIBBAnnularPathControlPointID)controlPointID
{
    return [_controlPoints[@(controlPointID)] NIBBVectorValue];
}

- (NIBBAnnularPathControlPointID)controlPointIDForControlPointNearPosition:(NIBBVector)position // returns -1 if there is no control point at the position
{
    for (NSNumber *controlPointIDNumber in _controlPoints) {
        if (NIBBVectorDistance(position, [_controlPoints[controlPointIDNumber] NIBBVectorValue]) < 3) {
            return [controlPointIDNumber integerValue];
        }
    }

    return -1;
}

- (void)drawForGeneratorRequest:(NIBBObliqueSliceGeneratorRequest *)generatorRequest
{
    NIBBAffineTransform sliceToDicomTransform = generatorRequest.sliceToDicomTransform;
    NIBBAffineTransform dicomToSliceTransform = NIBBAffineTransformInvert(sliceToDicomTransform);

    NIBBBezierPath *bezierPath = [[self bezierpath] bezierPathByApplyingTransform:dicomToSliceTransform];
    NSBezierPath *nsBezierPath = [bezierPath NSBezierPath];
    [nsBezierPath stroke];

    for (NSValue *value in _controlPoints) {
        NSPoint controlPoint = NSPointFromNIBBVector(NIBBVectorApplyTransform([value NIBBVectorValue], dicomToSliceTransform));
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(controlPoint.x - 3, controlPoint.y - 3, 6, 6)] fill];
    }
}

- (NSArray *)orderedControlPointIDs
{
    return [_controlPoints keysSortedByValueUsingComparator:^NSComparisonResult(NSValue *obj1, NSValue *obj2) {
        NIBBVector direction1 = NIBBVectorSubtract([obj1 NIBBVectorValue], _annularOrigin);
        NIBBVector direction2 = NIBBVectorSubtract([obj2 NIBBVectorValue], _annularOrigin);
        CGFloat angle1 = NIBBVectorAngleBetweenVectorsAroundVector(NIBBVectorANormalVector(_axialDirection), direction1, _axialDirection);
        CGFloat angle2 = NIBBVectorAngleBetweenVectorsAroundVector(NIBBVectorANormalVector(_axialDirection), direction2, _axialDirection);
        if (angle1 < angle2) {
            return NSOrderedAscending;
        } else if (angle1 > angle2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
}

- (NSArray *)orderedControlPointPositions
{
    NSArray *sortedKeys = [self orderedControlPointIDs];

    NSMutableArray *orderedControlPointPositions = [NSMutableArray array];
    for (NSNumber *key in sortedKeys) {
        [orderedControlPointPositions addObject:_controlPoints[key]];
    }
    return orderedControlPointPositions;
}

- (BOOL)_isCircleWithCenter:(NIBBVectorPointer)center radius:(CGFloat *)radius
{
    if ([_controlPoints count] == 0) {
        *radius = 15;
        *center = _annularOrigin;
        return YES;
    } else if ([_controlPoints count] == 1) {
        *radius = 15;
        *center = NIBBVectorAdd([[_controlPoints allValues][0] NIBBVectorValue], NIBBVectorScalarMultiply(NIBBVectorNormalize(NIBBVectorSubtract(_annularOrigin, [[_controlPoints allValues][0] NIBBVectorValue])), 15));
        return YES;
    } else if ([_controlPoints count] == 2) {
        NIBBVector betweenPosition = NIBBVectorLerp([[_controlPoints allValues][0] NIBBVectorValue], [[_controlPoints allValues][1] NIBBVectorValue], 0.5);
        NIBBVector base = NIBBVectorSubtract([[_controlPoints allValues][0] NIBBVectorValue], [[_controlPoints allValues][1] NIBBVectorValue]);
        CGFloat baseLength = NIBBVectorLength(base) / 2.0;
        NIBBVector heightDirection = NIBBVectorNormalize(NIBBVectorCrossProduct(base, _axialDirection));
        if (NIBBVectorDotProduct(NIBBVectorSubtract(_annularOrigin, betweenPosition), heightDirection) < 0) {
            heightDirection = NIBBVectorInvert(heightDirection);
        }

        *radius = MAX(15, baseLength);
        *center = NIBBVectorAdd(betweenPosition, NIBBVectorScalarMultiply(heightDirection, sqrt(*radius* *radius - baseLength*baseLength)));
        return YES;
    } else if ([_controlPoints count] == 3) {
        NIBBVector betweenPosition1 = NIBBVectorLerp([[_controlPoints allValues][0] NIBBVectorValue], [[_controlPoints allValues][1] NIBBVectorValue], 0.5);
        NIBBVector betweenPosition2 = NIBBVectorLerp([[_controlPoints allValues][1] NIBBVectorValue], [[_controlPoints allValues][2] NIBBVectorValue], 0.5);

        NIBBPlane plane1 = NIBBPlaneMake(betweenPosition1, NIBBVectorNormalize(NIBBVectorSubtract([[_controlPoints allValues][0] NIBBVectorValue], [[_controlPoints allValues][1] NIBBVectorValue])));
        NIBBPlane plane2 = NIBBPlaneMake(betweenPosition2, NIBBVectorNormalize(NIBBVectorSubtract([[_controlPoints allValues][1] NIBBVectorValue], [[_controlPoints allValues][2] NIBBVectorValue])));
        NIBBPlane annularPlane = NIBBPlaneMake(_annularOrigin, _axialDirection);

        *center = NIBBLineIntersectionWithPlane(NIBBPlaneIntersectionWithPlane(plane1, plane2), annularPlane);
        *radius = NIBBVectorDistance(*center, [[_controlPoints allValues][0] NIBBVectorValue]);
        return YES;
    }

    return NO;
}

@end

@implementation NSNumber (NIBBAnnularPath)
+ (NSValue *)numberWithNIBBAnnularPathControlPointID:(NIBBAnnularPathControlPointID)controlPointID
{
    return [self numberWithInteger:controlPointID];
}
- (NIBBAnnularPathControlPointID)NIBBAnnularPathControlPointIDValue
{
    return [self integerValue];
}
@end
