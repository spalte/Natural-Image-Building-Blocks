//
//  CPRMPRWLWWTool.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRWLWWTool.h"
#import "CPRMPRView.h"
#import "CPRIntersection.h"

@interface CPRMPRWLWWTool ()

@property CGFloat mouseDownWindowLevel, mouseDownWindowWidth;
@property NSPoint previousLocation;

@end

@implementation CPRMPRWLWWTool

@synthesize mouseDownWindowLevel = _mouseDownWindowLevel, mouseDownWindowWidth = _mouseDownWindowWidth;
@synthesize previousLocation = _previousLocation;

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event or:(void(^)())or {
    return [super view:view mouseDown:event or:or confirm:^{
        self.previousLocation = self.mouseDownLocation;

        self.mouseDownWindowLevel = view.windowLevel;
        self.mouseDownWindowWidth = view.windowWidth;
        
        [NSCursor hide];
        [view enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
            intersection.maskAroundMouse = NO;
        }];
    }];
}

- (BOOL)view:(CPRMPRView*)view mouseDragged:(NSEvent*)event {
    [super view:view mouseDragged:event];
    
    NSPoint ldelta = NSMakePoint(self.currentLocation.x-self.previousLocation.x, self.currentLocation.y-self.previousLocation.y);

//    CGFloat factor = self.mouseDownWindowWidth/80;
//    if (factor < 0.01) // *curDCM.slope in OsiriX
//        factor = 0.01; // *curDCM.slope in OsiriX
//
//    CGFloat windowLevel = self.mouseDownWindowLevel + (self.currentLocation.y - self.mouseDownLocation.y) * factor;
//    CGFloat windowWidth = self.mouseDownWindowWidth + (self.currentLocation.x - self.mouseDownLocation.x) * factor;
////    NSLog(@"WLWW: %f %f", windowLevel, windowWidth);
    
    CGFloat windowLevel = view.windowLevel + ldelta.y*view.windowLevel/100;
    CGFloat windowWidth = view.windowWidth + ldelta.x*view.windowWidth/100;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    if ([view.window.windowController respondsToSelector:@selector(setWindowLevel:)] && [view.window.windowController respondsToSelector:@selector(setWindowWidth:)]) {
        [view.window.windowController setWindowLevel:windowLevel];
        [view.window.windowController setWindowWidth:windowWidth];
    } else {
        [view setWindowLevel:windowLevel];
        [view setWindowWidth:windowWidth];
    }
    
    [CATransaction commit];

    self.previousLocation = self.currentLocation;

    return YES;
}

- (BOOL)view:(CPRMPRView*)view mouseUp:(NSEvent*)event {
    if (![super view:view mouseUp:event]) {
        [self moveCursorToMouseDownLocation];
        [NSCursor unhide];
    }
    
    return YES;
}

//- (NSCursor*)cursor {
//    return nil;
//}

@end
