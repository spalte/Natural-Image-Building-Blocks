//
//  CPRMPRView+Events.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/27/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRView+Private.h"
#import "CPRMPRView+Events.h"
#import "CPRMPRRotateTool.h"
#import "CPRMPRRotateAxisTool.h"
#import "CPRIntersection.h"

@implementation CPRMPRView (Events)

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)tool:(SEL)sel event:(NSEvent*)event or:(void(^)())block {
    SEL vsel = NSSelectorFromString([@"view:" stringByAppendingString:NSStringFromSelector(sel)]);
    CPRMPRTool* tool = self.tool? self.tool : [self.window.windowController tool];
    if ([tool respondsToSelector:vsel])
        if ([[tool performSelector:vsel withObject:self withObject:event] boolValue])
            return;
    if (block)
        block();
    else if ([CPRMPRView.superclass respondsToSelector:sel])
        [super performSelector:sel withObject:event];
}

- (void)mouseDown:(NSEvent*)event {
    [self tool:_cmd event:event or:nil];
}

- (void)rightMouseDown:(NSEvent*)event {
    [self tool:_cmd event:event or:^{
        [NSMenu popUpContextMenu:self.menu withEvent:event forView:self];
    }];
}

- (void)otherMouseDown:(NSEvent*)event {
    [self tool:_cmd event:event or:nil];
}

- (void)mouseUp:(NSEvent*)event {
    [self tool:_cmd event:event or:^{
        [self hover:event location:[self convertPoint:event.locationInWindow fromView:nil]];
    }];
}

- (void)rightMouseUp:(NSEvent*)event {
    [self tool:_cmd event:event or:nil];
}

- (void)otherMouseUp:(NSEvent*)event {
    [self tool:_cmd event:event or:nil];
}

- (void)mouseMoved:(NSEvent*)event {
    [self tool:_cmd event:event or:^{
        [self hover:event location:[self convertPoint:event.locationInWindow fromView:nil]];
    }];
}

- (void)mouseDragged:(NSEvent*)event {
    [self tool:_cmd event:event or:nil];
    [super mouseDragged:event];
}

- (void)scrollWheel:(NSEvent*)event {
    [self tool:_cmd event:event or:nil];
}

- (void)rightMouseDragged:(NSEvent*)event {
    [self tool:_cmd event:event or:nil];
}

- (void)otherMouseDragged:(NSEvent*)event {
    [self tool:_cmd event:event or:nil];
}

- (void)mouseEntered:(NSEvent*)event {
    [self.window makeFirstResponder:self];
    [self.window makeKeyAndOrderFront:self];
    self.tool = [self.window.windowController tool];
    [self tool:_cmd event:event or:nil];
}

- (void)mouseExited:(NSEvent*)event {
    [self tool:_cmd event:event or:nil];
    self.tool = nil;
}

- (void)keyDown:(NSEvent*)event {
    [self tool:_cmd event:event or:nil];
}

- (void)keyUp:(NSEvent*)event {
    [self tool:_cmd event:event or:nil];
}

- (void)flagsChanged:(NSEvent*)event {
    [self tool:_cmd event:event or:^{
        [self hover:event location:[self convertPoint:[self.window convertScreenToBase:[NSEvent mouseLocation]] fromView:nil]];
    }];
}

- (void)hover:(NSEvent*)event location:(NSPoint)location {
    CGFloat distance;
    NSString* ikey = [self intersectionClosestToPoint:location closestPoint:NULL distance:&distance];
    
    BOOL flag = (ikey && distance < 4);
    
    Class /*wtc = [[self.window.windowController tool] class],*/ tc = nil;
    
    if (flag) {
        tc = CPRMPRRotateAxisTool.class;
        if ((event.modifierFlags&NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask)
            tc = CPRMPRRotateTool.class;
    }
    
    if (self.tool.class != tc)
        self.tool = [[[tc alloc] init] autorelease];
    
    [self enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
        intersection.maskAroundMouse = !flag;
    }];
    
    CPRMPRTool* tool = self.tool? self.tool : [self.window.windowController tool];
    
    NSCursor* cursor = tool? tool.hoverCursor : NSCursor.arrowCursor;
    if (flag)
        cursor = NSCursor.openHandCursor;
    
    if (NSCursor.currentCursor != cursor)
        [cursor set];
}

@end
