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

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Cocoa/Cocoa.h>

@class NIGeneratorRequest;
@class NIGeneratorRequestView;
@class NIObliqueSliceIntersectionLayer;
@protocol NISliceIntersectionLayer;

// This class will manage the layer
@interface NIIntersection : NSObject
{
@private
    NIGeneratorRequestView *_generatorRequestView; // not retained
    CALayer<NISliceIntersectionLayer> *_intersectionLayer; // retained

    id _intersectingObject;

    BOOL _maskAroundMouse;
    CGFloat _maskAroundMouseRadius;

    BOOL _maskAroundCirclePoint;
    NSPoint _maskCirclePoint;
    CGFloat _maskCirclePointRadius;

    NSColor *_color;
    CGFloat _thickness;

    BOOL _mouseInBounds;
    NSPoint _mousePosition;
}

- (instancetype)init;

@property (nonatomic, readwrite, retain) id intersectingObject; // so far NIObliqueGeneratorRequest is the only object type that can be intersected

@property (nonatomic, readwrite, assign) BOOL maskAroundMouse;
@property (nonatomic, readwrite, assign) CGFloat maskAroundMouseRadius;

@property (nonatomic, readwrite, assign) BOOL maskAroundCirclePoint;
@property (nonatomic, readwrite, assign) NSPoint maskCirclePoint;
@property (nonatomic, readwrite, assign) CGFloat maskCirclePointRadius;

@property (nonatomic, readwrite, retain) NSColor *color;
@property (nonatomic, readwrite, assign) CGFloat thickness;

- (CGFloat)distanceToPoint:(NSPoint)point closestPoint:(NSPoint*)rpoint; // returns CGFLOAT_MAX if can't return an actual distance

@end
