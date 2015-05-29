//
//  CPRMPRView+Events.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/27/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRView+Private.h"
#import "CPRMPRView+Events.h"
#import "CPRMPRMoveTool.h"
#import "CPRMPRRotateTool.h"
#import "CPRMPRRotateAxisTool.h"
#import "CPRIntersection.h"

@implementation CPRMPRView (Events)

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)tool:(CPRMPRTool*)tool sel:(SEL)sel event:(NSEvent*)event or:(void(^)())block {
    NSString* ssel = NSStringFromSelector(sel);
    if ([ssel hasPrefix:@"rightMouse"] || [ssel hasPrefix:@"otherMouse"])
        ssel = [@"mouse" stringByAppendingString:[ssel substringFromIndex:NSMaxRange([ssel rangeOfString:@"Mouse"])]];
    
    SEL vsel = NSSelectorFromString([@"view:" stringByAppendingString:ssel]), orvsel = NSSelectorFromString([NSString stringWithFormat:@"view:%@or:", ssel]);
    if ([tool respondsToSelector:orvsel]) {
        if ([[tool performSelector:orvsel withObjects:self:event:block] boolValue])
            return;
    } else if ([tool respondsToSelector:vsel])
        if ([[tool performSelector:vsel withObjects:self:event] boolValue])
            return;
    
    if (block)
        block();
    else if ([CPRMPRView.superclass respondsToSelector:sel])
        [super performSelector:sel withObject:event];
}

- (void)mouseDown:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event or:nil];
}

- (void)rightMouseDown:(NSEvent*)event {
    [self tool:self.rtool sel:_cmd event:event or:^{
        [NSMenu popUpContextMenu:self.menu withEvent:event forView:self];
    }];
}

- (void)otherMouseDown:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event or:nil];
}

- (void)mouseUp:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event or:^{
        [self hover:event location:[self convertPoint:event.locationInWindow fromView:nil]];
    }];
}

- (void)rightMouseUp:(NSEvent*)event {
    [self tool:self.rtool sel:_cmd event:event or:nil];
}

- (void)otherMouseUp:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event or:nil];
}

- (void)mouseMoved:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event or:^{
        [self hover:event location:[self convertPoint:event.locationInWindow fromView:nil]];
    }];
}

- (void)mouseDragged:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event or:nil];
    [super mouseDragged:event];
}

- (void)scrollWheel:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event or:nil];
}

- (void)rightMouseDragged:(NSEvent*)event {
    [self tool:self.rtool sel:_cmd event:event or:nil];
}

- (void)otherMouseDragged:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event or:nil];
}

- (void)mouseEntered:(NSEvent*)event {
    [self.window makeFirstResponder:self];
    [self.window makeKeyAndOrderFront:self];
    [self tool:self.ltool sel:_cmd event:event or:nil];
}

- (void)mouseExited:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event or:nil];
}

- (void)keyDown:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event or:^{
        CPRMPRToolTag tool = 0;
        
        if ((event.modifierFlags&NSDeviceIndependentModifierFlagsMask) == 0)
            switch ([event.characters.lowercaseString characterAtIndex:0]) {
                case 'w': {
                    tool = CPRMPRToolWLWW;
                } break;
                case 'm': {
                    tool = CPRMPRToolMove;
                } break;
                case 'z': {
                    tool = CPRMPRToolZoom;
                } break;
                case 'r': {
                    tool = CPRMPRToolRotate;
                } break;
            }
        else
        if ((event.modifierFlags&NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask)
            switch ([event.characters.lowercaseString characterAtIndex:0]) {
                case 'r': {
                    [self.window.windowController reset];
                } break;
            }
        
        if (tool)
            [self.window.windowController setLtoolTag:tool];
    }];
}

- (void)keyUp:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event or:nil];
}

- (void)flagsChanged:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event or:^{
        [self hover:event location:[self convertPoint:[self.window convertScreenToBase:[NSEvent mouseLocation]] fromView:nil]];
    }];
}

- (void)hover:(NSEvent*)event location:(NSPoint)location {
    CGFloat distance;
    NSString* ikey = [self intersectionClosestToPoint:location closestPoint:NULL distance:&distance];
    
    BOOL rotate = (ikey && distance < 4);

    __block BOOL move = rotate; // so,
    if (move)
        [self enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
            if ([key isEqualToString:ikey])
                return;
            if ([intersection distanceToPoint:location closestPoint:NULL] > 4) {
                move = NO;
                *stop = YES;
            }
        }];
    
    Class /*wtc = [[self.window.windowController tool] class],*/ tc = nil;
    
    if (move)
        tc = CPRMPRMoveTool.class;
    else if (rotate) {
        tc = CPRMPRRotateAxisTool.class;
        if ((event.modifierFlags&NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask)
            tc = CPRMPRRotateTool.class;
    }
    
    if (self.ltool.class != tc)
        self.ltool = [[[tc alloc] init] autorelease];
    
    [self enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
        intersection.maskAroundMouse = !rotate;
    }];
    
    CPRMPRTool* tool = [self ltool];
    NSCursor* cursor = tool? tool.cursor : NSCursor.arrowCursor;
    if (rotate)
        cursor = NSCursor.openHandCursor;
    
    if (NSCursor.currentCursor != cursor)
        [cursor set];
}

@end
