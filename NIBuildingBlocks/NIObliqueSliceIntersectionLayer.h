//  Created by Joël Spaltenstein on 4/24/15.
//  Copyright (c) 2017 Spaltenstein Natural Image
//  Copyright (c) 2017 Michael Hilker and Andreas Holzamer
//  Copyright (c) 2017 volz io
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

#ifndef _NISLICEINTERSECTIONLAYER_H_
#define _NISLICEINTERSECTIONLAYER_H_

#import <QuartzCore/QuartzCore.h>
#import "NIBezierPath.h"
#import "NIGeneratorRequestView.h"

@protocol NISliceIntersectionLayer <NSObject>

@property (nonatomic, readwrite, retain, nonnull) NSColor *intersectionColor; // animatable
@property (nonatomic, readwrite, assign) CGFloat intersectionThickness; // animatable
@property (nonatomic, readwrite, copy, nullable) NSArray<NSNumber *> *intersectionDashingLengths; // lengths of the painted segments and unpainted segments

@property (nonatomic, readwrite, retain, nullable) NIBezierPath *rimPath;
@property (nonatomic, readwrite, assign) BOOL gapAroundMouse;
@property (nonatomic, readwrite, assign) NSPoint mouseGapPosition; // animatable
@property (nonatomic, readwrite, assign) CGFloat mouseGapRadius; // animatable

@property (nonatomic, readwrite, assign) BOOL gapAroundPosition;
@property (nonatomic, readwrite, assign) NSPoint gapPosition; // animatable
@property (nonatomic, readwrite, assign) CGFloat gapRadius; // animatable

@property (nonatomic, readwrite, assign) BOOL centerBulletPoint;
@property (nonatomic, readwrite, assign) CGFloat centerBulletPointRadius; // animatable

@end

@interface NIObliqueSliceIntersectionLayer : CAShapeLayer <NISliceIntersectionLayer>
{
    NIBezierPath *_rimPath;
    NSArray<NSNumber *> *_intersectionDashingLengths;
    BOOL _gapAroundMouse;
    BOOL _gapAroundPosition;
    BOOL _centerBulletPoint;
}

@property (nonatomic, readwrite, assign) NIVector origin;
@property (nonatomic, readwrite, assign) NIVector directionX;
@property (nonatomic, readwrite, assign) NIVector directionY;
@property (nonatomic, readwrite, assign) CGFloat pointSpacingX;
@property (nonatomic, readwrite, assign) CGFloat pointSpacingY;

@property (nonatomic, readwrite, assign) NIAffineTransform sliceToModelTransform;

@property (nonatomic, readwrite, retain, nonnull) NSColor *intersectionColor; // animatable
@property (nonatomic, readwrite, assign) CGFloat intersectionThickness; // animatable
@property (nonatomic, readwrite, copy, nullable) NSArray<NSNumber *> *intersectionDashingLengths; // lengths of the painted segments and unpainted segments

@property (nonatomic, readwrite, retain, nullable) NIBezierPath *rimPath;
@property (nonatomic, readwrite, assign) BOOL gapAroundMouse;
@property (nonatomic, readwrite, assign) NSPoint mouseGapPosition; // animatable
@property (nonatomic, readwrite, assign) CGFloat mouseGapRadius; // animatable

@property (nonatomic, readwrite, assign) BOOL gapAroundPosition;
@property (nonatomic, readwrite, assign) NSPoint gapPosition; // animatable
@property (nonatomic, readwrite, assign) CGFloat gapRadius; // animatable

@property (nonatomic, readwrite, assign) BOOL centerBulletPoint;
@property (nonatomic, readwrite, assign) CGFloat centerBulletPointRadius; // animatable


// this would be cool to implement
//@property (nonatomic, readwrite, retain) NSBezierPath *maskPath; // delimits an area in which there should not be any drawing.


@end

#endif /* _NISLICEINTERSECTIONLAYER_H_ */
