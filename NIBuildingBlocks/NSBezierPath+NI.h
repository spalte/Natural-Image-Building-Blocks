//  Created by Joël Spaltenstein on 3/7/15.
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

NS_ASSUME_NONNULL_BEGIN

@interface NSBezierPath (NIAdditions)

- (NSBezierPath *)convexHull;
- (void)diameterMinStart:(nullable NSPointPointer)minStart minEnd:(nullable NSPointPointer)minEnd maxStart:(nullable NSPointPointer)maxStart maxEnd:(nullable NSPointPointer)maxEnd;

/**
 Returns a bitmap representation of this bezier path.
 The NSBitmapImageRep represents pixels as floats, one per pixel.
 @param scaling the scaling factor
 @param fill flag to determine if the path shall be rendered through a stroke or a fill operation
 @returns the bitmap
 */
- (NSBitmapImageRep*)bitmapWithScaling:(CGFloat)scaling fill:(BOOL)fill;

@end

NS_ASSUME_NONNULL_END