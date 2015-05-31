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

/*@interface CPRMPRWLWWTool ()

@property CGFloat mouseDownWindowLevel, mouseDownWindowWidth;

@end*/

@implementation CPRMPRWLWWTool

//@synthesize mouseDownWindowLevel = _mouseDownWindowLevel, mouseDownWindowWidth = _mouseDownWindowWidth;

//- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event or:(void(^)())or {
//    return [super view:view mouseDown:event or:or confirm:^{
//        self.mouseDownWindowLevel = view.windowLevel;
//        self.mouseDownWindowWidth = view.windowWidth;
//    }];
//}

- (BOOL)view:(CPRMPRView*)view move:(NSPoint)ldelta vector:(N3Vector)deltaVector {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    CGFloat step = fmax(view.windowWidth/100, 0.01);
    CGFloat windowLevel = view.windowLevel + ldelta.y*step;
    CGFloat windowWidth = fmax(view.windowWidth + ldelta.x*step, 0.01);
    NSLog(@"WLWW %f %f", windowLevel, windowWidth);
    
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

- (NSArray*)cursors {
    return @[ NSCursor.arrowCursor, NSNull.null ];
}

@end
