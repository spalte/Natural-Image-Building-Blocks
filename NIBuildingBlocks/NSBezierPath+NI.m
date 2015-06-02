//  Created by Joël Spaltenstein on 3/7/15.
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

#import "NSBezierPath+NI.h"


int NSPointLexigraphicalCompare(const void *voidPoint1, const void *voidPoint2)
{
    const NSPoint* point1 = voidPoint1;
    const NSPoint* point2 = voidPoint2;

    if (point1->x < point2->x) {
        return NSOrderedAscending;
    } else if (point1->x > point2->x) {
        return NSOrderedDescending;
    }

    if (point1->y < point2->y) {
        return NSOrderedAscending;
    } else if (point1->y > point2->y) {
        return NSOrderedDescending;
    }

    return NSOrderedSame;

}

CGFloat NIAdditionsNSPointVectorsCrossProduct(NSPointPointer p1, NSPointPointer p2, NSPointPointer p3)
{
    return (p2->x-p1->x)*(p3->y-p1->y) - (p2->y-p1->y)*(p3->x-p1->x);
}

CGFloat NIAdditionsNSPointVectorLength(NSPoint p1)
{
#if CGFLOAT_IS_DOUBLE
    return sqrt(p1.x*p1.x + p1.y*p1.y);
#else
    return sqrtf(p1.x*p1.x + p1.y*p1.y);
#endif
}

NSPoint NIAdditionsNSPointVectorSubtract(NSPoint p1, NSPoint p2)
{
    return NSMakePoint(p1.x-p2.x, p1.y-p2.y);
}

CGFloat NIAdditionsNSPointDistance(NSPoint p1, NSPoint p2)
{
    return NIAdditionsNSPointVectorLength(NIAdditionsNSPointVectorSubtract(p1, p2));
}

NSPoint NIAdditionsNSPointVectorNormalize(NSPoint p1)
{
    CGFloat length = NIAdditionsNSPointVectorLength(p1);
    return NSMakePoint(p1.x/length, p1.y/length);
}

CGFloat NIAdditionsNSPointVectorsDotProduct(NSPoint p1, NSPoint p2)
{
    return p1.x*p2.x + p1.y*p2.y;
}


@implementation NSBezierPath (NIAdditions)



- (NSBezierPath *)convexHull
{
    NSBezierPath *flattenedPath = [self bezierPathByFlatteningPath];

    NSInteger elementCount = [flattenedPath elementCount];
    NSInteger i;
    NSInteger k;

    NSPointArray points;
    points = malloc(elementCount * sizeof(NSPoint));

    NSPoint associatedPoints[3];
    NSBezierPathElement elementType;
    for (i = 0, k = 0; i < elementCount; i++) {
        elementType = [flattenedPath elementAtIndex:i associatedPoints:associatedPoints];
        if (elementType == NSMoveToBezierPathElement || elementType == NSLineToBezierPathElement) {
            points[k] = associatedPoints[0];
            k++;
        } else if (elementType == NSClosePathBezierPathElement) {
            i++; // remove the extra moveTo after a closePath
        }
    }

    if (k < 3) {
        free(points);
        return flattenedPath;
    }

    qsort(points, k, sizeof(NSPoint), NSPointLexigraphicalCompare);

    NSPointArray hull;
    hull = malloc(k * sizeof(NSPoint) * 2);

    NSInteger j = 0;
    NSInteger l = 0;

    // lower hull
    for (i = 0; i < k; ++i) {
        while (j >= 2 && NIAdditionsNSPointVectorsCrossProduct(&hull[j-2], &hull[j-1], &points[i]) <= 0) {
            j--;
        };
        assert(i >= 0);
        assert(i < k);
        assert(j >= 0);
        assert(j < k*2);
        hull[j++] = points[i];
    }

    for (i = k-2, l = j+1; i >= 0; --i) {
        while (j >= l && NIAdditionsNSPointVectorsCrossProduct(&hull[j-2], &hull[j-1], &points[i]) <= 0) {
            --j;
        }
        assert(i >= 0);
        assert(i < k);
        assert(j >= 0);
        assert(j < k*2);
        hull[j++] = points[i];
    }

    free(points);

    NSBezierPath *convexPath = [NSBezierPath bezierPath];
    [convexPath appendBezierPathWithPoints:hull count:j-1]; // minus 1 because the last point is the same as the first point 
    [convexPath closePath];

    free(hull);

    return convexPath;
}

- (void)diameterMinStart:(NSPointPointer)minStart minEnd:(NSPointPointer)minEnd maxStart:(NSPointPointer)maxStart maxEnd:(NSPointPointer)maxEnd
{
    NSBezierPath *convexHull = [self convexHull];

    NSInteger elementCount = [convexHull elementCount];
    NSInteger pointCount = 0;
    NSInteger i;

    NSPointArray points;
    points = malloc(elementCount * sizeof(NSPoint));

    NSPoint associatedPoints[3];
    NSBezierPathElement elementType;
    for (i = 0; i < elementCount; i++) {
        elementType = [convexHull elementAtIndex:i associatedPoints:associatedPoints];
        if (elementType == NSMoveToBezierPathElement || elementType == NSLineToBezierPathElement) {
            points[pointCount] = associatedPoints[0];
            pointCount++;
        } else if (elementType == NSClosePathBezierPathElement) {
            i++; // remove the extra moveTo after a closePath
        }
    }

    if (pointCount == 0) {
        if (minStart) {
            *minStart = NSZeroPoint;
        }
        if (minEnd) {
            *minEnd = NSZeroPoint;
        }
        if (maxStart) {
            *maxStart = NSZeroPoint;
        }
        if (maxEnd) {
            *maxEnd = NSZeroPoint;
        }
        free(points);
        return;
    } else if (pointCount == 1) {
        if (minStart) {
            *minStart = points[0];
        }
        if (minEnd) {
            *minEnd = points[0];
        }
        if (maxStart) {
            *maxStart = points[0];
        }
        if (maxEnd) {
            *maxEnd = points[0];
        }
        free(points);
        return;
    } else if (pointCount == 2) {
        if (minStart) {
            *minStart = points[0];
        }
        if (minEnd) {
            *minEnd = points[1];
        }
        if (maxStart) {
            *maxStart = points[0];
        }
        if (maxEnd) {
            *maxEnd = points[1];
        }
        free(points);
        return;
    }

    NSInteger leftPointIndex = 0;
    NSInteger rightPointIndex = 0;

    CGFloat leftMost = points[0].x;
    CGFloat rightMost = points[0].x;

    for (i = 0; i < pointCount; i++) {
        if (leftMost > points[i].x) {
            leftMost = points[i].x;
            leftPointIndex = i;
        }
        if (rightMost < points[i].x) {
            rightMost = points[i].x;
            rightPointIndex = i;
        }
    }

    NSInteger startingLeftPointIndex = leftPointIndex;
    NSInteger startingRightPointIndex = rightPointIndex;
    BOOL pivotLeft = YES;

    CGFloat maxDistance = 0;
    CGFloat minDistance = CGFLOAT_MAX;

    NSPoint caliperVector = NSMakePoint(0, 1);

    do {
        NSPoint leftPoint = points[leftPointIndex];
        NSPoint rightPoint = points[rightPointIndex];
        // based on the two points and the caliper vector, find max and min

        // first look for the max points
        CGFloat pointDistance = NIAdditionsNSPointDistance(leftPoint, rightPoint);
        if (pointDistance > maxDistance) {
            maxDistance = pointDistance;
            if (maxStart) {
                *maxStart = leftPoint;
            }
            if (maxEnd) {
                *maxEnd = rightPoint;
            }
        }

        // now look for the minimum
        // find the calliper width
        NSPoint distanceVector = NIAdditionsNSPointVectorSubtract(leftPoint, rightPoint);
        CGFloat projectionDistance = NIAdditionsNSPointVectorsDotProduct(distanceVector, caliperVector);
        NSPoint projectionVector = NSMakePoint(caliperVector.x*projectionDistance, caliperVector.y*projectionDistance);
        NSPoint caliperSeparationVector = NIAdditionsNSPointVectorSubtract(distanceVector, projectionVector);
        CGFloat caliperSeparation = NIAdditionsNSPointVectorLength(caliperSeparationVector);
        if (caliperSeparation < minDistance) {
            minDistance = caliperSeparation;
            if (pivotLeft) {
                if (minStart) {
                    *minStart = leftPoint;
                }
                if (minEnd) {
                    *minEnd = NSMakePoint(leftPoint.x-caliperSeparationVector.x, leftPoint.y-caliperSeparationVector.y);
                }
            } else {
                if (minStart) {
                    *minStart = rightPoint;
                }
                if (minEnd) {
                    *minEnd = NSMakePoint(rightPoint.x+caliperSeparationVector.x, rightPoint.y+caliperSeparationVector.y);
                }
            }
        }

        // find what point is hit first when rotating the calipers
        NSInteger nextLeftPointIndex = (leftPointIndex + 1) % pointCount;
        NSInteger nextRightPointIndex = (rightPointIndex + 1) % pointCount;
        NSPoint nextLeftPoint = points[nextLeftPointIndex];
        NSPoint nextRightPoint = points[nextRightPointIndex];

        // find the angles
        NSPoint leftVector = NIAdditionsNSPointVectorNormalize(NIAdditionsNSPointVectorSubtract(leftPoint, nextLeftPoint));
        NSPoint rightVector = NIAdditionsNSPointVectorNormalize(NIAdditionsNSPointVectorSubtract(nextRightPoint, rightPoint));

        if (NIAdditionsNSPointVectorsDotProduct(caliperVector, leftVector) > NIAdditionsNSPointVectorsDotProduct(caliperVector, rightVector)) {
            pivotLeft = NO;
            caliperVector = leftVector;
            leftPointIndex = nextLeftPointIndex;
        } else {
            pivotLeft = YES;
            caliperVector = rightVector;
            rightPointIndex = nextRightPointIndex;
        }
    } while (startingLeftPointIndex != leftPointIndex || startingRightPointIndex != rightPointIndex);

    free(points);
}


@end






























