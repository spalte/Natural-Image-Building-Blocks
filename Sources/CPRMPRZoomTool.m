//
//  CPRMPRZoomTool.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRZoomTool.h"
#import "CPRMPRView.h"
#import "CPRIntersection.h"

@interface CPRMPRZoomTool ()

@property NSPoint previousLocation;
//@property CGFloat mouseDownPixelSpacing;

@end

@implementation CPRMPRZoomTool

@synthesize previousLocation = _previousLocation;
//@synthesize mouseDownPixelSpacing = _mouseDownPixelSpacing;

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event {
    [super view:view mouseDown:event];
    
    self.previousLocation = self.mouseDownLocation;
    //self.mouseDownPixelSpacing = view.pixelSpacing;
    
    [NSCursor hide];
    [view enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
        intersection.maskAroundMouse = NO;
    }];
    
    return YES;
}

- (BOOL)view:(CPRMPRView*)view mouseDragged:(NSEvent*)event {
    NSPoint location = [view convertPoint:event.locationInWindow fromView:nil];
    
    NSPoint ldelta = NSMakePoint(location.x-self.previousLocation.x, location.y-self.previousLocation.y);
    CGFloat delta = ldelta.y;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    view.pixelSpacing = view.pixelSpacing+delta*view.pixelSpacing/100;
//    NSLog(@"pixelspacing initially %f, now %f", self.mouseDownPixelSpacing, view.pixelSpacing);
    
    [CATransaction commit];
    
    self.previousLocation = location;
    
    return YES;
}

- (BOOL)view:(CPRMPRView*)view mouseUp:(NSEvent*)event {
    [NSCursor unhide];
    
    return YES;
}




@end
