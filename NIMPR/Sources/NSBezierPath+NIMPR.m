//
//  NSBezierPath+NIMPR.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/16/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NSBezierPath+NIMPR.h"

@implementation NSBezierPath (NIMPR)

#define FLATNESS 2e-5

void _parameterizeLine(NSPoint *coefficients, NSPoint startPoint, NSPoint endPoint) {
    coefficients[0] = startPoint;
    coefficients[1].x = endPoint.x - startPoint.x;
    if (ABS(coefficients[1].x) < FLATNESS)         // this line is horizontal
        coefficients[1].x = 0;
    coefficients[1].y = endPoint.y - startPoint.y;  // this line is vertical
    if (ABS(coefficients[1].y) < FLATNESS)
        coefficients[1].y = 0;
}

// Given a curveto's endpoints and control points, compute the coefficients to trace out the curve as p(t) = c[0] + c[1]*t + c[2]*t^2 + c[3]*t^3
void _parameterizeCurve(NSPoint *coefficients, NSPoint startPoint, NSPoint endPoint, NSPoint controlPoint1, NSPoint controlPoint2) {
    coefficients[0] = startPoint;
    coefficients[1].x = (CGFloat)(3.0 * (controlPoint1.x - startPoint.x));  // 1st tangent
    coefficients[1].y = (CGFloat)(3.0 * (controlPoint1.y - startPoint.y));  // 1st tangent
    coefficients[2].x = (CGFloat)(3.0 * (startPoint.x - 2 * controlPoint1.x + controlPoint2.x));
    coefficients[2].y = (CGFloat)(3.0 * (startPoint.y - 2 * controlPoint1.y + controlPoint2.y));
    coefficients[3].x = (CGFloat)(endPoint.x - startPoint.x + 3.0 * ( controlPoint1.x - controlPoint2.x ));
    coefficients[3].y = (CGFloat)(endPoint.y - startPoint.y + 3.0 * ( controlPoint1.y - controlPoint2.y ));
}

static BOOL _straightLineIntersectsRect(const NSPoint *a, NSRect rect) {
    // PENDING: needs some work...
    if (NSPointInRect(a[0], rect)) {
        return YES;
    }
    if (a[1].x != 0) {
        double t = (NSMinX(rect) - a[0].x)/a[1].x;
        double y;
        if (t >= 0 && t <= 1) {
            y = t * a[1].y + a[0].y;
            if (y >= NSMinY(rect) && y < NSMaxY(rect)) {
                return YES;
            }
        }
        t = (NSMaxX(rect) - a[0].x)/a[1].x;
        if (t >= 0 && t <= 1) {
            y = t * a[1].y + a[0].y;
            if (y >= NSMinY(rect) && y < NSMaxY(rect)) {
                return YES;
            }
        }
    }
    if (a[1].y != 0) {
        double t = (NSMinY(rect) - a[0].y)/a[1].y;
        double x;
        if (t >= 0 && t <= 1) {
            x = t * a[1].x + a[0].x;
            if (x >= NSMinX(rect) && x < NSMaxX(rect)) {
                return YES;
            }
        }
        t = (NSMaxY(rect) - a[0].y)/a[1].y;
        if (t >= 0 && t <= 1) {
            x = t * a[1].x + a[0].x;
            if (x >= NSMinX(rect) && x < NSMaxX(rect)) {
                return YES;
            }
        }
    }
    //    } else {
    //        if (a[0].x < NSMinX(rect) || a[0].x > NSMaxX(rect)) {
    //            return NO;
    //        }
    //        if (a[0].y < NSMinY(rect)) {
    //            if ((a[0].y + a[1].y) >= NSMinY(rect)) {
    //                return YES;
    //            }
    //        } else if (a[0].y <= NSMaxY(rect)) {
    //            return YES;
    //        }
    //    }
    return NO;
}

static void splitParameterizedCurveLeft(const NSPoint *c, NSPoint *left)
{
    // This is just a substitution of t' = t / 2
    left[0].x = c[0].x;
    left[0].y = c[0].y;
    left[1].x = c[1].x / 2;
    left[1].y = c[1].y / 2;
    left[2].x = c[2].x / 4;
    left[2].y = c[2].y / 4;
    left[3].x = c[3].x / 8;
    left[3].y = c[3].y / 8;
}

static void splitParameterizedCurveRight(const NSPoint *c, NSPoint *right)
{
    // This is just a substitution of t' = (t + 1) / 2
    right[0].x = c[0].x + c[1].x/2 + c[2].x/4 + c[3].x/8;
    right[0].y = c[0].y + c[1].y/2 + c[2].y/4 + c[3].y/8;
    right[1].x =          c[1].x/2 + c[2].x/2 + c[3].x*3/8;
    right[1].y =          c[1].y/2 + c[2].y/2 + c[3].y*3/8;
    right[2].x =                     c[2].x/4 + c[3].x*3/8;
    right[2].y =                     c[2].y/4 + c[3].y*3/8;
    right[3].x =                                c[3].x/8;
    right[3].y =                                c[3].y/8;
}

// Returns the bounds of a cubic curve for t=0..1. Curve need not be monotonic.
// Input curve is represented as coefficients.
// This just converts back to the control-point representation and computes the bounding box of the control+end points.
static NSRect _parameterizedCurveBounds(const NSPoint *curve) {
    CGFloat minX = curve[0].x;
    CGFloat maxX = curve[0].x;
    CGFloat minY = curve[0].y;
    CGFloat maxY = curve[0].y;
    NSRect rect;
    NSPoint points[3];
    unsigned i;
    
    points[0].x = (CGFloat)(curve[0].x + 0.3333* curve[1].x);
    points[0].y = (CGFloat)(curve[0].y + 0.3333* curve[1].y);
    points[1].x = (CGFloat)(curve[0].x + 0.3333* curve[2].x + 0.6666* curve[1].x);
    points[1].y = (CGFloat)(curve[0].y + 0.3333* curve[2].y + 0.6666* curve[1].y);
    points[2].x = (CGFloat)(curve[3].x + curve[2].x + curve[1].x + curve[0].x);
    points[2].y = (CGFloat)(curve[3].y + curve[2].y + curve[1].y + curve[0].y);
    
    for(i=0;i<3;i++) {
        NSPoint p = points[i];
        if (p.x > maxX) {
            maxX = p.x;
        } else if (p.x < minX) {
            minX = p.x;
        }
        if (p.y > maxY) {
            maxY = p.y;
        } else if (p.y < minY) {
            minY = p.y;
        }
    }
    rect.origin.x = minX;
    rect.origin.y = minY;
    rect.size.width = maxX - minX;
    if (rect.size.width < 1) {
        rect.size.width = 1;
    }
    rect.size.height = maxY - minY;
    if (rect.size.height < 1) {
        rect.size.height = 1;
    }
    return rect;
}

static BOOL _curvedLineIntersectsRect(const NSPoint *c, NSRect rect, CGFloat tolerance) {
    NSRect bounds = _parameterizedCurveBounds(c);
    if (NSIntersectsRect(rect, bounds)) {
        if (bounds.size.width <= tolerance ||
            bounds.size.height <= tolerance) {
            return YES;
        } else {
            NSPoint half[4];
            splitParameterizedCurveLeft(c, half);
            if (_curvedLineIntersectsRect(half, rect, tolerance))
                return YES;
            splitParameterizedCurveRight(c, half);
            if (_curvedLineIntersectsRect(half, rect, tolerance))
                return YES;
        }
    }
    return NO;
}

- (BOOL)intersectsRect:(NSRect)rect // from https://github.com/omnigroup/OmniGroup/blob/master/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSBezierPath-OAExtensions.m
{
    NSInteger count = [self elementCount];
    NSInteger i;
    NSPoint points[3];
    NSPoint startPoint;
    NSPoint currentPoint;
    NSPoint line[2];
    NSPoint curve[4];
    BOOL needANewStartPoint;
    
    if (count == 0)
        return NO;
    
    NSBezierPathElement element = [self elementAtIndex:0 associatedPoints:points];
    if (element != NSMoveToBezierPathElement) {
        return NO;  // must start with a moveTo
    }
    
    startPoint = currentPoint = points[0];
    needANewStartPoint = NO;
    
    for(i=1;i<count;i++) {
        NSBezierPathElement element = [self elementAtIndex:i associatedPoints:points];
        switch(element) {
            case NSMoveToBezierPathElement:
                currentPoint = points[0];
                if (needANewStartPoint) {
                    startPoint = currentPoint;
                    needANewStartPoint = NO;
                }
                break;
            case NSClosePathBezierPathElement:
                _parameterizeLine(line, currentPoint,startPoint);
                if (_straightLineIntersectsRect(line, rect)) {
                    return YES;
                }
                currentPoint = startPoint;
                needANewStartPoint = YES;
                break;
            case NSLineToBezierPathElement:
                _parameterizeLine(line, currentPoint,points[0]);
                if (_straightLineIntersectsRect(line, rect)){
                    return YES;
                }
                currentPoint = points[0];
                break;
            case NSCurveToBezierPathElement: {
                _parameterizeCurve(curve, currentPoint, points[2], points[0], points[1]);
                if (_curvedLineIntersectsRect(curve, rect, [self lineWidth]+1)) {
                    return YES;
                }
                currentPoint = points[2];
                break;
            }
        }
    }
    
    return NO;
}
@end
