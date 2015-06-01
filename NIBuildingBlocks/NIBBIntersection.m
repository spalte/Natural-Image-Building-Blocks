//  Created by Joël Spaltenstein on 4/26/15.
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

#import "NIBBIntersection.h"
#import "NIBBIntersectionPrivate.h"
#import "NIBBGeneratorRequest.h"
#import "NIBBGeometry.h"
#import "NIBBObliqueSliceIntersectionLayer.h"
#import <QuartzCore/QuartzCore.h>

@interface NIBBIntersection ()

- (void)updateLayer;

@end

@implementation NIBBIntersection

- (instancetype)init
{
    if ( (self = [super init]) ) {
        _color = [[NSColor whiteColor] retain];
        _thickness = 1.5;
        _maskAroundMouse = YES;
        _maskAroundMouseRadius = 80;
        _maskCirclePointRadius = 80;
    }
    return self;
}

@synthesize intersectingObject = _intersectingObject;
@synthesize maskAroundMouse = _maskAroundMouse;
@synthesize maskAroundMouseRadius = _maskAroundMouseRadius;
@synthesize maskAroundCirclePoint = _maskAroundCirclePoint;
@synthesize maskCirclePoint = _maskCirclePoint;
@synthesize maskCirclePointRadius = _maskCirclePointRadius;
@synthesize color = _color;
@synthesize thickness = _thickness;

- (void)dealloc
{
    [_intersectionLayer release];
    _intersectionLayer = nil;

    [_intersectingObject release];
    _intersectingObject = nil;

    [super dealloc];
}

- (void)setIntersectingObject:(id)intersectingObject
{
    if ([_intersectingObject isEqual:intersectingObject] == NO) {
        [_intersectingObject release];
        _intersectingObject = [intersectingObject retain];
        [self updateLayer];
    }
}

- (void)setMaskAroundMouse:(BOOL)maskAroundMouse
{
    if (_maskAroundMouse != maskAroundMouse) {
        _maskAroundMouse = maskAroundMouse;
        [self updateLayer];
    }
}

- (void)setMaskAroundMouseRadius:(CGFloat)maskAroundMouseRadius
{
    if (_maskAroundMouseRadius != maskAroundMouseRadius) {
        _maskAroundMouseRadius = maskAroundMouseRadius;
        [self updateLayer];
    }
}

- (void)setMaskAroundCirclePoint:(BOOL)maskAroundCirclePoint
{
    if (_maskAroundCirclePoint != maskAroundCirclePoint) {
        _maskAroundCirclePoint = maskAroundCirclePoint;
        [self updateLayer];
    }
}

- (void)setMaskCirclePoint:(NSPoint)maskCirclePoint
{
    if (NSEqualPoints(_maskCirclePoint, maskCirclePoint) == NO) {
        _maskCirclePoint = maskCirclePoint;
        [self updateLayer];
    }
}

- (void)setMaskCirclePointRadius:(CGFloat)maskCirclePointRadius
{
    if (_maskCirclePointRadius != maskCirclePointRadius) {
        _maskCirclePointRadius = maskCirclePointRadius;
        [self updateLayer];
    }
}

- (void)setColor:(NSColor *)color
{
    if (_color != color) {
        [_color release];
        _color = [color retain];
        [self updateLayer];
    }
}

- (void)setThickness:(CGFloat)thickness
{
    if (_thickness != thickness) {
        _thickness = thickness;
        [self updateLayer];
    }
}

- (void)updateLayer
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    self.intersectionLayer.intersectionColor = self.color;
    self.intersectionLayer.intersectionThickness = self.thickness;
    self.intersectionLayer.rimPath = [self.intersectingObject performSelector:@selector(rimPath)];
    self.intersectionLayer.mouseGapRadius = self.maskAroundMouseRadius;
    self.intersectionLayer.gapAroundPosition = self.maskAroundCirclePoint;
    self.intersectionLayer.gapPosition = self.maskCirclePoint;
    self.intersectionLayer.gapRadius = self.maskCirclePointRadius;

    if (_mouseInBounds && self.maskAroundMouse) {
        self.intersectionLayer.gapAroundMouse = YES;
        self.intersectionLayer.mouseGapPosition = _mousePosition;
    } else {
        self.intersectionLayer.gapAroundMouse = NO;
    }

    [CATransaction commit];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    _mouseInBounds = YES;
    NSPoint pointInView = [_generatorRequestView convertPoint:theEvent.locationInWindow fromView:nil];
    CGPoint pointInLayer = [_intersectionLayer convertPoint:NSPointToCGPoint(pointInView) fromLayer:_generatorRequestView.layer];
    _mousePosition = NSPointFromCGPoint(pointInLayer);
    if (self.maskAroundMouse) {
        [self updateLayer];
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    _mouseInBounds = NO;
    [self updateLayer];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    NSPoint pointInView = [_generatorRequestView convertPoint:theEvent.locationInWindow fromView:nil];
    CGPoint pointInLayer = [_intersectionLayer convertPoint:NSPointToCGPoint(pointInView) fromLayer:_generatorRequestView.layer];
    _mousePosition = NSPointFromCGPoint(pointInLayer);
    if (self.maskAroundMouse) {
        [self updateLayer];
    }
}

- (CGFloat)distanceToPoint:(NSPoint)point closestPoint:(NSPoint *)rpoint
{
    if (_generatorRequestView == nil || _intersectingObject == nil) {;
        return CGFLOAT_MAX;
    }

    NIBBPlane plane = [(NIBBObliqueSliceGeneratorRequest *)_generatorRequestView.presentedGeneratorRequest plane];
    NSArray *intersections = [[(NIBBObliqueSliceGeneratorRequest *)_intersectingObject rimPath] intersectionsWithPlane:plane];
    if ([intersections count] != 2) {
        return CGFLOAT_MAX;
    }

    NIBBMutableBezierPath *intersectionPath = [NIBBMutableBezierPath bezierPath];
    [intersectionPath moveToVector:NIBBVectorMakeFromNSPoint([_generatorRequestView convertPointFromDICOMVector:[intersections[0] NIBBVectorValue]])];
    [intersectionPath lineToVector:NIBBVectorMakeFromNSPoint([_generatorRequestView convertPointFromDICOMVector:[intersections[1] NIBBVectorValue]])];

    NIBBVector closestPoint = [intersectionPath vectorAtRelativePosition:[intersectionPath relativePositionClosestToVector:NIBBVectorMakeFromNSPoint(point)]];
    
    if (rpoint)
        *rpoint = NSPointFromNIBBVector(closestPoint);
    return NIBBVectorDistance(NIBBVectorMakeFromNSPoint(point), closestPoint);
}

@end



@implementation NIBBIntersection (Private)

- (NIBBGeneratorRequestView *)generatorRequestView
{
    return _generatorRequestView;
}

- (void)setGeneratorRequestView:(NIBBGeneratorRequestView *)generatorRequestView
{
    _generatorRequestView = generatorRequestView;
}

- (CALayer<NIBBSliceIntersectionLayer> *)intersectionLayer
{
    return _intersectionLayer;
}

- (void)setIntersectionLayer:(CALayer<NIBBSliceIntersectionLayer> *)intersectionLayer
{
    if (_intersectionLayer != intersectionLayer) {
        [_intersectionLayer release];
        _intersectionLayer = [intersectionLayer retain];
        [self updateLayer];
    }
}

@end










