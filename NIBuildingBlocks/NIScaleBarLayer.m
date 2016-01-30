//  Created by Joël Spaltenstein on 4/20/15.
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

#import <Cocoa/Cocoa.h>

#import "NIScaleBarLayer.h"

CGPathRef _horizontalUnitScaleBar5 = NULL;
CGPathRef _verticalUnitScaleBar5 = NULL;
CGPathRef _horizontalUnitScaleBar10 = NULL;

CGPathRef horizontalUnitScaleBar5Path()
{
    if (_horizontalUnitScaleBar5 == nil) {
        NSInteger i;
        CGMutablePathRef path = CGPathCreateMutable();

        for (i = 0; i <= 5; i++) {
            CGPathMoveToPoint(path, NULL, i, 0);
            CGPathAddLineToPoint(path, NULL, i, i%5?5:8);
        }
        CGPathMoveToPoint(path, NULL, 0, 0);
        CGPathAddLineToPoint(path, NULL, i-1, 0);

        _horizontalUnitScaleBar5 = path;
    }
    return _horizontalUnitScaleBar5;
}

CGPathRef verticalUnitScaleBar5()
{
    if (_verticalUnitScaleBar5 == nil) {
        NSInteger i;
        CGMutablePathRef path = CGPathCreateMutable();

        for (i = 0; i <= 5; i++) {
            CGPathMoveToPoint(path, NULL, 0, i);
            CGPathAddLineToPoint(path, NULL, i%5?5:8, i);
        }
        CGPathMoveToPoint(path, NULL, 0, 0);
        CGPathAddLineToPoint(path, NULL, 0, i-1);

        _verticalUnitScaleBar5 = path;
    }
    return _verticalUnitScaleBar5;
}

CGPathRef horizontalUnitScaleBar10Path()
{
    if (_horizontalUnitScaleBar10 == nil) {
        NSInteger i;
        CGMutablePathRef path = CGPathCreateMutable();

        for (i = 0; i <= 10; i++) {
            CGPathMoveToPoint(path, NULL, i, 0);
            CGPathAddLineToPoint(path, NULL, i, i%5?5:8);
        }
        CGPathMoveToPoint(path, NULL, 0, 0);
        CGPathAddLineToPoint(path, NULL, i-1, 0);

        _horizontalUnitScaleBar10 = path;
    }
    return _horizontalUnitScaleBar10;
}


@implementation NIScaleBarLayer

@synthesize orientation = _orientation;

- (instancetype)init
{
    if ( (self = [super init]) ) {
        self.path = horizontalUnitScaleBar10Path();
        self.strokeColor = [NSColor greenColor].CGColor;
        self.lineWidth = 1;
    }
    return self;
}

- (void)setPointSpacing:(CGFloat)pointSpacing // spacing in mm/point
{
    if (pointSpacing == 0) {
        self.path = nil;
        self.bounds = CGRectZero;
        [self setNeedsDisplay];
        return;
    }

    CGPathRef scaled5Path = NULL;

    if (_orientation == NIScaleBarLayerHorizontalOrientation) {
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(10.0/(pointSpacing), 1);
        scaled5Path = CGPathCreateCopyByTransformingPath(horizontalUnitScaleBar5Path(), &scaleTransform);
    } else {
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(1, 10.0/(pointSpacing));
        scaled5Path = CGPathCreateCopyByTransformingPath(verticalUnitScaleBar5(), &scaleTransform);
    }

    self.path = scaled5Path;
    self.bounds = CGPathGetBoundingBox(scaled5Path);
    CGPathRelease(scaled5Path);
    [self setNeedsDisplay];
}

- (void)setOrientation:(NIScaleBarLayerOrientation)orientation
{
    if (orientation != _orientation) {
        CGFloat pointSpacing = self.pointSpacing;
        _orientation = orientation;
        [self setPointSpacing:pointSpacing];
    }
}

- (CGFloat)pointSpacing
{
    if (self.bounds.size.width == 0) {
        return 0;
    } else {
        return 100.0/self.bounds.size.width;
    }
}

@end









