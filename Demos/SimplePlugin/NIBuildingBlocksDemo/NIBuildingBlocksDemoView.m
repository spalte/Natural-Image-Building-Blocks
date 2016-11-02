//  Created by Joël Spaltenstein on 6/15/15.
//  Copyright (c) 2016 Spaltenstein Natural Image
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

#import "NIBuildingBlocksDemoView.h"

@implementation NIBuildingBlocksDemoView

- (void)drawOverlay
{
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:24];
    [@"Click Me" drawWithRect:NSMakeRect(200, 200, 100, 100) options:0
                   attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName:[NSColor yellowColor]}];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];

    NIObliqueSliceGeneratorRequest *oldGeneratorRequest = (NIObliqueSliceGeneratorRequest *)self.generatorRequest;

    NIVector xBasis = NIVectorScalarMultiply(oldGeneratorRequest.directionX, oldGeneratorRequest.pixelSpacingX);
    NIVector yBasis = NIVectorScalarMultiply(oldGeneratorRequest.directionY, oldGeneratorRequest.pixelSpacingY);
    xBasis = NIVectorInvert(xBasis);

    NIObliqueSliceGeneratorRequest *newGeneratorRequest = [[[NIObliqueSliceGeneratorRequest alloc] initWithCenter:oldGeneratorRequest.center
                                                                                                       pixelsWide:200 pixelsHigh:200 xBasis:xBasis yBasis:yBasis] autorelease];
    newGeneratorRequest.interpolationMode = NIInterpolationModeCubic;

    [CATransaction begin];
    [CATransaction setAnimationDuration:.8];
    self.generatorRequest = newGeneratorRequest;
    [CATransaction commit];
}

@end
