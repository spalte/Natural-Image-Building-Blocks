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
    [[NSColor yellowColor] set];
    [@"Click Me" drawAtPoint:NSMakePoint(20,20) withAttributes:nil];
}

@end
