//
//  NIBuildingBlocksDemoView.m
//  NIBuildingBlocksDemo
//
//  Created by Joël Spaltenstein on 6/15/15.
//  Copyright (c) 2015 Spaltenstein Natural Image. All rights reserved.
//

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
