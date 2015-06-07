//
//  NIWindowingView.m
//  NIBuildingBlocks
//
//  Created by Joël Spaltenstein on 6/5/15.
//  Copyright (c) 2015 Spaltenstein Natural Image. All rights reserved.
//

#import "NIWindowingView.h"

@implementation NIWindowingView

@synthesize windowLevel = _windowLevel;
@synthesize windowWidth = _windowWidth;


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)mouseDown:(NSEvent *)theEvent
{
    _clickPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    _clickWindowLevel = _windowLevel;
    _clickWindowWidth = _windowWidth;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint dragPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    self.windowLevel = _clickWindowLevel + (dragPoint.y - _clickPoint.y)*10.0;
    self.windowWidth = MAX(_clickWindowWidth + (dragPoint.x - _clickPoint.x)*10.0, 0);
}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSPoint dragPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    self.windowLevel = _clickWindowLevel + (dragPoint.y - _clickPoint.y)*10.0;
    self.windowWidth = MAX(_clickWindowWidth + (dragPoint.x - _clickPoint.x)*10.0, 0);

    _clickPoint = NSZeroPoint;
    _clickWindowLevel = 0;
    _clickWindowWidth = 0;
}

- (BOOL)isOpaque
{
    return YES;
}

@end
