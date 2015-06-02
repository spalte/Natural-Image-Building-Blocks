//
//  NIMPRView+Events.m
//  NIMPR
//
//  Created by Alessandro Volz on 5/27/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRView+Private.h"
#import "NIMPRView+Events.h"
#import "NIMPRMoveTool.h"
#import "NIMPRRotateTool.h"
#import "NIMPRZoomTool.h"
#import <NIBuildingBlocks/NIIntersection.h>
#import "NIMPRController.h"
#import <objc/runtime.h>

@implementation NIMPRView (Events)

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)tool:(NIMPRTool*)tool sel:(SEL)sel event:(NSEvent*)event or:(void(^)())block {
    NSString* ssel = NSStringFromSelector(sel);
    if ([ssel hasPrefix:@"rightMouse"] || [ssel hasPrefix:@"otherMouse"])
        ssel = [@"mouse" stringByAppendingString:[ssel substringFromIndex:NSMaxRange([ssel rangeOfString:@"Mouse"])]];
    
    if ([ssel isEqualToString:@"mouseDown:"]) {
        self.mouseDown = YES;
//        [self.latestMouseDownEvents insertObject:event atIndex:0];
//        if (self.latestMouseDownEvents.count > 3)
//            [self.latestMouseDownEvents removeObjectAtIndex:3];
    } else if ([ssel isEqualToString:@"mouseUp:"])
        self.mouseDown = NO;
    
//    NSLog(@"%@ %d", ssel, self.mouseDown);
    
    SEL vsel = NSSelectorFromString([@"view:" stringByAppendingString:ssel]), orvsel = NSSelectorFromString([NSString stringWithFormat:@"view:%@or:", ssel]);
    if ([tool respondsToSelector:orvsel]) {
        if ([[tool performSelector:orvsel withObjects:self:event:block] boolValue])
            return;
    } else if ([tool respondsToSelector:vsel])
        if ([[tool performSelector:vsel withObjects:self:event] boolValue])
            return;
    
    if (block)
        block();
    else if ([NIMPRView.superclass respondsToSelector:sel])
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
        NIMPRView* view = [[self.window.contentView hitTest:event.locationInWindow] if:NIMPRView.class];
        if (view != self)
            [view hover:event location:[view convertPoint:event.locationInWindow fromView:nil]];
        else {
            if (event.clickCount == 2)
                self.ltcOnDoubleClick = [self toolForLocation:[view convertPoint:event.locationInWindow fromView:nil] event:nil];
            if (event.clickCount >= 2) {
                if (self.ltcOnDoubleClick == NIMPRRotateAxisTool.class) {
                    if (event.clickCount == 2)
                        [self rotateToInitial];
                    else if (event.clickCount == 3)
                        [self.window.windowController rotateToInitial];
                } else if (self.ltcOnDoubleClick == NIMPRMoveOthersTool.class) {
                    if (event.clickCount == 2)
                        [self.window.windowController moveToInitial];
                }
            }
        }
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
    [self tool:self.ltool sel:_cmd event:event or:^{
        [self hover:event location:[self convertPoint:event.locationInWindow fromView:nil]];
    }];
}

- (void)keyDown:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event or:^{
        NIMPRToolTag tool = 0;
        
        if ((event.modifierFlags&NSDeviceIndependentModifierFlagsMask) == 0)
            switch ([event.characters.lowercaseString characterAtIndex:0]) {
                case 'w': {
                    tool = NIMPRToolWLWW;
                } break;
                case 'm': {
                    tool = NIMPRToolMove;
                } break;
                case 'z': {
                    tool = NIMPRToolZoom;
                } break;
                case 'r': {
                    tool = NIMPRToolRotate;
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
        [self hover:event location:[self convertPoint:[self.window convertPointFromScreen:[NSEvent mouseLocation]] fromView:nil]];
    }];
}

- (void)hover:(NSEvent*)event location:(NSPoint)location {
    if (self.mouseDown)
        return;
    
    if (!event)
        event = [NSApp currentEvent];
    
    Class ltc = [self toolForLocation:location event:event];
    
    if (self.ltool.class != ltc)
        self.ltool = [[[ltc alloc] init] autorelease];
    
    [self enumerateIntersectionsWithBlock:^(NSString* key, NIIntersection* intersection, BOOL* stop) {
        intersection.maskAroundMouse = !ltc;
    }];
    
    [NIMPRTool setCursor:(NSPointInRect(location, self.bounds)? [self.ltool cursors][0] : nil)];
    
    Class rtc = nil;
    
    if (ltc == NIMPRMoveOthersTool.class)
        rtc = NIMPRCenterZoomTool.class;
    
    if (self.rtool.class != rtc)
        self.rtool = [[[rtc alloc] init] autorelease];
}

- (Class)toolForLocation:(NSPoint)location event:(NSEvent*)event {
    CGFloat distance;
    NSString* ikey = [self intersectionClosestToPoint:location closestPoint:NULL distance:&distance];
    
    BOOL rotate = (ikey && distance < 4);
    
    __block BOOL move, cmove = move = rotate;
    if ([self.window.windowController spacebarIsDown])
        move = YES;
    else if (cmove)
        [self enumerateIntersectionsWithBlock:^(NSString* key, NIIntersection* intersection, BOOL* stop) {
            if ([key isEqualToString:ikey])
                return;
            if ([intersection distanceToPoint:location closestPoint:NULL] > 6) {
                cmove = move = NO;
                *stop = YES;
            }
        }];
    else if ((event.modifierFlags&NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask)
        rotate = YES;
    
    Class ltc = nil;
    
    if (cmove)
        ltc = NIMPRMoveOthersTool.class;
    else if (move)
        ltc = NIMPRMoveTool.class;
    else if (rotate) {
        ltc = NIMPRRotateAxisTool.class;
        if ((event.modifierFlags&NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask)
            ltc = NIMPRRotateTool.class;
    }
    
    return ltc;
}

@end
