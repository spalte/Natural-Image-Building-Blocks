//
//  NIMPRWindow.m
//  NIMPR
//
//  Created by Alessandro Volz on 5/29/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRWindow.h"
#import "NIMPRWindowController+Private.h"

@interface NSToolbarView : NSView
@end

@implementation NIMPRWindow

- (void)sendEvent:(NSEvent*)event {
    if (event.type == NSKeyDown || event.type == NSKeyUp)
        if ([event.characters characterAtIndex:0] == ' ') {
            BOOL flag = (event.type == NSKeyDown);
            if ([self.windowController spacebarIsDown] != flag)
                [self.windowController setSpacebarDown:flag];
        }
    
    if (event.type == NSRightMouseDown || event.type == NSRightMouseDragged || event.type == NSRightMouseUp) {
        NSView* frameView = [self.contentView superview];
        NSView* view = [frameView hitTest:[frameView convertPoint:event.locationInWindow fromView:nil]];
        if ([view isKindOfClass:NSToolbarView.class])
            for (NSView* subview in view.subviews) {
                NSView* view = [subview hitTest:[subview convertPoint:event.locationInWindow fromView:nil]];
                if (view.interceptsToolbarRightMouseEvents)
                    switch (event.type) {
                        case NSRightMouseDown: return [view rightMouseDown:event];
                        case NSRightMouseDragged: return [view rightMouseDragged:event];
                        case NSRightMouseUp: return [view rightMouseUp:event];
                        default: break;
                    }
            }
    }
    
    [super sendEvent:event];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet* set = [super keyPathsForValuesAffectingValueForKey:key];
    
    if ([key isEqualToString:@"frame"])
        set = [set setByAddingObject:@"contentView.size"];
    
    return set;
}

@end

@implementation NSView (NIMPRWindow)

- (BOOL)interceptsToolbarRightMouseEvents {
    return NO;
}

@end