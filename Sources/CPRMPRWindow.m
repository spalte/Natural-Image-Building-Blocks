//
//  CPRMPRWindow.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/29/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRWindow.h"
#import "CPRMPRController+Private.h"

@interface NSToolbarView : NSView
@end

@implementation CPRMPRWindow

- (void)sendEvent:(NSEvent*)event {
    if (event.type == NSKeyDown || event.type == NSKeyUp)
        if ([event.characters characterAtIndex:0] == ' ') {
            BOOL flag = (event.type == NSKeyDown);
            if ([self.windowController spacebarIsDown] != flag)
                [self.windowController setSpacebarDown:flag];
        }
    
    if (event.type == NSRightMouseDown) {
        NSView* frameView = [self.contentView superview];
        NSView* view = [frameView hitTest:[frameView convertPoint:event.locationInWindow fromView:nil]];
        if ([view isKindOfClass:NSToolbarView.class])
            for (NSView* subview in view.subviews) {
                NSView* view = [subview hitTest:[subview convertPoint:event.locationInWindow fromView:nil]];
                if (view.interceptsToolbarRightMouseDownEvents)
                    return [view rightMouseDown:event];
            }
    }
    
    [super sendEvent:event];
}

@end

@implementation NSView (CPRMPRWindow)

- (BOOL)interceptsToolbarRightMouseDownEvents {
    return NO;
}

@end