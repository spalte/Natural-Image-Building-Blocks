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

#import "NIAnnularPath.h"
#import "NIGeneratorRequest.h"
#import "NIBezierPath.h"
#import "NSBezierPath+NI.h"

@interface NIAnnularPath ()
- (BOOL)_isCircleWithCenter:(NIVectorPointer)center radius:(CGFloat *)radius;
@end

@implementation NIAnnularPath

@synthesize annularOrigin = _annularOrigin;
@synthesize axialDirection = _axialDirection;

- (instancetype)initWithAnnularOrigin:(NIVector)annularOrigin axialDirection:(NIVector)axialDirection;
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
    NIAnnularPath *copy = [[NIAnnularPath allocWithZone:zone] initWithAnnularOrigin:_annularOrigin axialDirection:_axialDirection];
    for (NSValue *value in [_controlPoints allValues]) {
        [copy addControlPointAtPosition:[value NIVectorValue]];
    }
    return copy;
}

- (NIPlane)plane
{
    return NIPlaneMake(_annularOrigin, _axialDirection);
}

- (NIBezierPath *)bezierpath
{
    NIVector center = NIVectorZero;
    CGFloat radius = 0;

    if ([self _isCircleWithCenter:&center radius:&radius]) {
        return [NIBezierPath bezierPathCircleWithCenter:center radius:radius normal:_axialDirection];
    } else {
        NSMutableArray *orderedControlPointPositions = [NSMutableArray arrayWithArray:[self orderedControlPointPositions]];
        [orderedControlPointPositions addObject:orderedControlPointPositions[0]];
        NIMutableBezierPath *bezierPath = [[[NIMutableBezierPath alloc] initWithNodeArray:orderedControlPointPositions style:NIBezierNodeEndsMeetStyle] autorelease];
        [bezierPath close];

        return bezierPath;
    }
}


- (void)diameterMinStart:(NIVectorPointer)minStart minEnd:(NIVectorPointer)minEnd maxStart:(NIVectorPointer)maxStart maxEnd:(NIVectorPointer)maxEnd
{
    NIVector center = NIVectorZero;
    CGFloat radius = 0;

    if ([self _isCircleWithCenter:&center radius:&radius]) {
        if (minStart) {
            *minStart = NIVectorAdd(center, NIVectorScalarMultiply(NIVectorANormalVector(_axialDirection), -radius));
        }
        if (minEnd) {
            *minEnd = NIVectorAdd(center, NIVectorScalarMultiply(NIVectorANormalVector(_axialDirection), radius));
        }
        if (maxStart) {
            *maxStart = NIVectorAdd(center, NIVectorScalarMultiply(NIVectorCrossProduct(NIVectorANormalVector(_axialDirection), _axialDirection), -radius));
        }
        if (maxEnd) {
            *maxEnd = NIVectorAdd(center, NIVectorScalarMultiply(NIVectorCrossProduct(NIVectorANormalVector(_axialDirection), _axialDirection), radius));
        }
    } else {
        NIBezierPath *bezierPath = [self bezierpath];
        NIVector rotationAxis = NIVectorCrossProduct(_axialDirection, NIVectorZBasis);
        CGFloat rotationAngle = asin(NIVectorLength(rotationAxis));
        if (NIVectorIsZero(rotationAxis)) {
            rotationAxis = NIVectorANormalVector(rotationAxis);
        } else {
            rotationAxis = NIVectorNormalize(rotationAxis);
        }
        if (NIVectorDotProduct(_axialDirection, NIVectorZBasis) < 0) {
            rotationAngle = M_PI - rotationAngle;
        }

        NIAffineTransform transform = NIAffineTransformMakeRotationAroundVector(rotationAngle, rotationAxis);
        NSBezierPath *nsBezierPath = [[[bezierPath bezierPathByApplyingTransform:transform] bezierPathBySubdividing:1] NSBezierPath];

        NSPoint minStartPoint = NSZeroPoint;
        NSPoint minEndPoint = NSZeroPoint;
        NSPoint maxStartPoint = NSZeroPoint;
        NSPoint maxEndPoint = NSZeroPoint;

        NIAffineTransform inverseTransform = NIAffineTransformInvert(transform);
        [nsBezierPath diameterMinStart:&minStartPoint minEnd:&minEndPoint maxStart:&maxStartPoint maxEnd:&maxEndPoint];
        if (minStart) {
            *minStart = NIVectorApplyTransform(NIVectorMakeFromNSPoint(minStartPoint), inverseTransform);
        }
        if (minEnd) {
            *minEnd = NIVectorApplyTransform(NIVectorMakeFromNSPoint(minEndPoint), inverseTransform);
        }
        if (maxStart) {
            *maxStart = NIVectorApplyTransform(NIVectorMakeFromNSPoint(maxStartPoint), inverseTransform);
        }
        if (maxEnd) {
            *maxEnd = NIVectorApplyTransform(NIVectorMakeFromNSPoint(maxEndPoint), inverseTransform);
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

- (NIAnnularPathControlPointID)addControlPointAtPosition:(NIVector)position
{
    // project the position onto the plane
    position = NIPlanePointClosestToVector(self.plane, position);

    NIAnnularPathControlPointID controlPoinID = [self controlPointIDForControlPointNearPosition:position];

    if (controlPoinID != -1) {
        [self setPosition:position forControlPointID:controlPoinID];
        return controlPoinID;
    } else {
        [_controlPoints setObject:[NSValue valueWithNIVector:position] forKey:@(++_idCounter)];
        return _idCounter;
    }
}

- (void)setPosition:(NIVector)position forControlPointID:(NIAnnularPathControlPointID)controlPointID
{
    // project the position onto the plane
    position = NIPlanePointClosestToVector(self.plane, position);

    NIVector previousPosotion = [self positionForControlPointID:controlPointID];
    [_controlPoints removeObjectForKey:@(controlPointID)];

    if ([self controlPointIDForControlPointNearPosition:position] != -1) { // don't allow the point to get to close to another point, so bail out and reset the state
        [_controlPoints setObject:[NSValue valueWithNIVector:previousPosotion] forKey:@(controlPointID)];
    } else {
        [_controlPoints setObject:[NSValue valueWithNIVector:position] forKey:@(controlPointID)];
    }
}

- (NIVector)positionForControlPointID:(NIAnnularPathControlPointID)controlPointID
{
    return [_controlPoints[@(controlPointID)] NIVectorValue];
}

- (NIAnnularPathControlPointID)controlPointIDForControlPointNearPosition:(NIVector)position // returns -1 if there is no control point at the position
{
    for (NSNumber *controlPointIDNumber in _controlPoints) {
        if (NIVectorDistance(position, [_controlPoints[controlPointIDNumber] NIVectorValue]) < 3) {
            return [controlPointIDNumber integerValue];
        }
    }

    return -1;
}

- (void)drawForGeneratorRequest:(NIObliqueSliceGeneratorRequest *)generatorRequest
{
    NIAffineTransform sliceToDicomTransform = generatorRequest.sliceToDicomTransform;
    NIAffineTransform dicomToSliceTransform = NIAffineTransformInvert(sliceToDicomTransform);

    NIBezierPath *bezierPath = [[self bezierpath] bezierPathByApplyingTransform:dicomToSliceTransform];
    NSBezierPath *nsBezierPath = [bezierPath NSBezierPath];
    [nsBezierPath stroke];

    for (NSValue *value in _controlPoints) {
        NSPoint controlPoint = NSPointFromNIVector(NIVectorApplyTransform([value NIVectorValue], dicomToSliceTransform));
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(controlPoint.x - 3, controlPoint.y - 3, 6, 6)] fill];
    }
}

- (NSArray *)orderedControlPointIDs
{
    return [_controlPoints keysSortedByValueUsingComparator:^NSComparisonResult(NSValue *obj1, NSValue *obj2) {
        NIVector direction1 = NIVectorSubtract([obj1 NIVectorValue], _annularOrigin);
        NIVector direction2 = NIVectorSubtract([obj2 NIVectorValue], _annularOrigin);
        CGFloat angle1 = NIVectorAngleBetweenVectorsAroundVector(NIVectorANormalVector(_axialDirection), direction1, _axialDirection);
        CGFloat angle2 = NIVectorAngleBetweenVectorsAroundVector(NIVectorANormalVector(_axialDirection), direction2, _axialDirection);
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

- (BOOL)_isCircleWithCenter:(NIVectorPointer)center radius:(CGFloat *)radius
{
    if ([_controlPoints count] == 0) {
        *radius = 15;
        *center = _annularOrigin;
        return YES;
    } else if ([_controlPoints count] == 1) {
        *radius = 15;
        *center = NIVectorAdd([[_controlPoints allValues][0] NIVectorValue], NIVectorScalarMultiply(NIVectorNormalize(NIVectorSubtract(_annularOrigin, [[_controlPoints allValues][0] NIVectorValue])), 15));
        return YES;
    } else if ([_controlPoints count] == 2) {
        NIVector betweenPosition = NIVectorLerp([[_controlPoints allValues][0] NIVectorValue], [[_controlPoints allValues][1] NIVectorValue], 0.5);
        NIVector base = NIVectorSubtract([[_controlPoints allValues][0] NIVectorValue], [[_controlPoints allValues][1] NIVectorValue]);
        CGFloat baseLength = NIVectorLength(base) / 2.0;
        NIVector heightDirection = NIVectorNormalize(NIVectorCrossProduct(base, _axialDirection));
        if (NIVectorDotProduct(NIVectorSubtract(_annularOrigin, betweenPosition), heightDirection) < 0) {
            heightDirection = NIVectorInvert(heightDirection);
        }

        *radius = MAX(15, baseLength);
        *center = NIVectorAdd(betweenPosition, NIVectorScalarMultiply(heightDirection, sqrt(*radius* *radius - baseLength*baseLength)));
        return YES;
    } else if ([_controlPoints count] == 3) {
        NIVector betweenPosition1 = NIVectorLerp([[_controlPoints allValues][0] NIVectorValue], [[_controlPoints allValues][1] NIVectorValue], 0.5);
        NIVector betweenPosition2 = NIVectorLerp([[_controlPoints allValues][1] NIVectorValue], [[_controlPoints allValues][2] NIVectorValue], 0.5);

        NIPlane plane1 = NIPlaneMake(betweenPosition1, NIVectorNormalize(NIVectorSubtract([[_controlPoints allValues][0] NIVectorValue], [[_controlPoints allValues][1] NIVectorValue])));
        NIPlane plane2 = NIPlaneMake(betweenPosition2, NIVectorNormalize(NIVectorSubtract([[_controlPoints allValues][1] NIVectorValue], [[_controlPoints allValues][2] NIVectorValue])));
        NIPlane annularPlane = NIPlaneMake(_annularOrigin, _axialDirection);

        *center = NILineIntersectionWithPlane(NIPlaneIntersectionWithPlane(plane1, plane2), annularPlane);
        *radius = NIVectorDistance(*center, [[_controlPoints allValues][0] NIVectorValue]);
        return YES;
    }

    return NO;
}

@end

@implementation NSNumber (NIAnnularPath)
+ (NSValue *)numberWithNIAnnularPathControlPointID:(NIAnnularPathControlPointID)controlPointID
{
    return [self numberWithInteger:controlPointID];
}
- (NIAnnularPathControlPointID)NIAnnularPathControlPointIDValue
{
    return [self integerValue];
}
@end
