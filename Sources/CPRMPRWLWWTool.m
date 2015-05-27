//
//  CPRMPRWLWWTool.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRWLWWTool.h"
#import "CPRMPRView.h"
#import <Quartz/Quartz.h>

@interface CPRMPRWLWWTool ()

@property CGFloat mouseDownWindowLevel, mouseDownWindowWidth;

@end

@implementation CPRMPRWLWWTool

@synthesize mouseDownWindowLevel = _mouseDownWindowLevel, mouseDownWindowWidth = _mouseDownWindowWidth;

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event {
    [super view:view mouseDown:event];
    
    self.mouseDownWindowLevel = view.windowLevel;
    self.mouseDownWindowWidth = view.windowWidth;
    
    [NSCursor hide];
    
    return YES;
}

- (BOOL)view:(CPRMPRView*)view mouseDragged:(NSEvent*)event {
    NSPoint location = [view convertPoint:event.locationInWindow fromView:nil];
    
    CGFloat factor = self.mouseDownWindowWidth/80;
    if (factor < 0.01) // *curDCM.slope in OsiriX
        factor = 0.01; // *curDCM.slope in OsiriX

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    view.windowLevel = self.mouseDownWindowLevel + (location.y - self.mouseDownLocation.y) * factor;
    view.windowWidth = self.mouseDownWindowWidth + (location.x - self.mouseDownLocation.x) * factor;

    NSLog(@"WLWW: %f %f", view.windowLevel, view.windowWidth);
    
    [CATransaction commit];

    return YES;
}

- (BOOL)view:(CPRMPRView*)view mouseUp:(NSEvent*)event {
    [NSCursor unhide];
    
    return YES;
}

@end
