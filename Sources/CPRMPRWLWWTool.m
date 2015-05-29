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

@end

@implementation CPRMPRWLWWTool

@synthesize mouseDownWindowLevel = _mouseDownWindowLevel, mouseDownWindowWidth = _mouseDownWindowWidth;

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event or:(void(^)())or {
    return [super view:view mouseDown:event or:or confirm:^{
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
    
    CGFloat factor = self.mouseDownWindowWidth/80;
    if (factor < 0.01) // *curDCM.slope in OsiriX
        factor = 0.01; // *curDCM.slope in OsiriX

    CGFloat windowLevel = self.mouseDownWindowLevel + (self.currentLocation.y - self.mouseDownLocation.y) * factor;
    CGFloat windowWidth = self.mouseDownWindowWidth + (self.currentLocation.x - self.mouseDownLocation.x) * factor;
//    NSLog(@"WLWW: %f %f", windowLevel, windowWidth);
    
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

    return YES;
}

- (BOOL)view:(CPRMPRView*)view mouseUp:(NSEvent*)event {
    if (![super view:view mouseUp:event]) {
        [NSCursor unhide];
    }
    
    return YES;
}

- (NSCursor*)cursor {
    return nil;
}

@end
