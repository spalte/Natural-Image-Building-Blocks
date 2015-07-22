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
#import "NIMPRAnnotationInteractionTool.h"
#import "NIMPRAnnotationHandleInteractionTool.h"
#import "+NIMPR.h"
#import <objc/runtime.h>

@implementation NIMPRView (Events)

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)tool:(NIMPRTool*)tool sel:(SEL)sel event:(NSEvent*)event otherwise:(void(^)())block {
    NSString* ssel = NSStringFromSelector(sel);
    if ([ssel hasPrefix:@"rightMouse"] || [ssel hasPrefix:@"otherMouse"])
        ssel = [@"mouse" stringByAppendingString:[ssel substringFromIndex:NSMaxRange([ssel rangeOfString:@"Mouse"])]];
    
    if ([ssel isEqualToString:@"mouseDown:"]) {
        self.mouseDown = YES;
    } else if ([ssel isEqualToString:@"mouseUp:"])
        self.mouseDown = NO;

    SEL vsel = NSSelectorFromString([@"view:" stringByAppendingString:ssel]), orvsel = NSSelectorFromString([NSString stringWithFormat:@"view:%@otherwise:", ssel]);
    
    
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
//    [self.mutableHighlightedAnnotations removeAllObjects];
    [self tool:self.ltool sel:_cmd event:event otherwise:nil];
}

- (void)rightMouseDown:(NSEvent*)event {
    [self tool:self.rtool sel:_cmd event:event otherwise:^{
        [NSMenu popUpContextMenu:self.menu withEvent:event forView:self];
    }];
}

- (void)otherMouseDown:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event otherwise:nil];
}

- (void)mouseUp:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event otherwise:^{
        [self flagsChanged:event];
        NIMPRView* view = [[self.window.contentView hitTest:event.locationInWindow] if:NIMPRView.class];
        if (view != self)
            [view hover:event];
        else {
            if (event.clickCount == 2)
                self.ltcAtSecondClick = [self toolForLocation:[view convertPoint:event.locationInWindow fromView:nil] event:nil];
            if (event.clickCount >= 2) {
                if (self.ltcAtSecondClick == NIMPRRotateAxisTool.class) {
                    if (event.clickCount == 2)
                        [self rotateToInitial];
                    else if (event.clickCount == 3)
                        [self.window.windowController rotateToInitial];
                } else if (self.ltcAtSecondClick == NIMPRMoveOthersTool.class) {
                    if (event.clickCount == 2)
                        [self.window.windowController moveToInitial];
                }
            }
        }
    }];
}

- (void)rightMouseUp:(NSEvent*)event {
    [self tool:self.rtool sel:_cmd event:event otherwise:nil];
}

- (void)otherMouseUp:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event otherwise:nil];
}

- (void)mouseMoved:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event otherwise:^{
        [self hover:event];
    }];
}

- (void)mouseDragged:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event otherwise:nil];
    [super mouseDragged:event];
}

- (void)scrollWheel:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event otherwise:nil];
}

- (void)rightMouseDragged:(NSEvent*)event {
    [self tool:self.rtool sel:_cmd event:event otherwise:nil];
}

- (void)otherMouseDragged:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event otherwise:nil];
}

- (void)mouseEntered:(NSEvent*)event {
    [self.window makeFirstResponder:self];
    [self.window makeKeyAndOrderFront:self];
    [self tool:self.ltool sel:_cmd event:event otherwise:nil];
}

- (void)mouseExited:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event otherwise:^{
        [self hover:event];
    }];
}

- (void)keyDown:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event otherwise:^{
        NIMPRToolTag tool = 0;
        
        if ((event.modifierFlags&NSDeviceIndependentModifierFlagsMask) == 0 || (event.modifierFlags&NSDeviceIndependentModifierFlagsMask) == NSFunctionKeyMask)
            switch ([event.characters.lowercaseString characterAtIndex:0]) {
                // tools
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
                case 's': {
                    tool = NIMPRToolInteract;
                } break;
                // action: delete key
                case NSDeleteFunctionKey:
                case NSDeleteCharFunctionKey:
                case 0x7f: {
                    [self.mutableAnnotations minusSet:self.selectedAnnotations];
                } break;
                // action: escape key
                case 0x1b: {
                    [self.mutableSelectedAnnotations removeAllObjects];
                } break;
            }
        else
        if ((event.modifierFlags&NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask)
            switch ([event.characters.lowercaseString characterAtIndex:0]) {
                case 'r': {
                    [self.window.windowController reset];
                } break;
                case 'a': {
                    [self.mutableSelectedAnnotations set:self.annotations];
                } break;
                case 0x7f: {
                    [self.mutableAnnotations removeAllObjects];
                } break;
            }
        
        if (tool)
            [self.window.windowController setLtoolTag:tool];
    }];
}

- (void)keyUp:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event otherwise:nil];
}

- (void)flagsChanged:(NSEvent*)event {
    [self tool:self.ltool sel:_cmd event:event otherwise:^{
        [self hover:event];
    }];
}

- (void)hover:(NSEvent*)event {
    NSPoint location = [event locationInView:self];
    
    BOOL displayOverlays = ((event.modifierFlags&NSCommandKeyMask) == 0) || ((event.modifierFlags&NSShiftKeyMask) == NSShiftKeyMask);
    if ([self.window.windowController displayOverlays] != displayOverlays)
        [self.window.windowController setDisplayOverlays:displayOverlays];
    
    if (self.mouseDown)
        return;

    if (!event)
        event = [NSApp currentEvent];

    Class ltc = [self toolForLocation:location event:event];
    
    if (self.ltool.class != ltc) {
//        if ([self.ltool respondsToSelector:@selector(view:switchingTo:event:)])
//            [self.ltool view:self switchingTo:ltc event:event];
        self.ltool = [[[ltc alloc] init] autorelease];
        if ([self.ltool respondsToSelector:@selector(view:flagsChanged:)])
            [self.ltool view:self flagsChanged:event];
    }
    
    [self enumerateIntersectionsWithBlock:^(NSString* key, NIIntersection* intersection, BOOL* stop) {
        intersection.maskAroundMouse = !ltc;
    }];
    
    [NIMPRTool setCursor:(NSPointInRect(location, self.bounds)? [self.ltool cursorsForView:self][0] : nil)];
    
    Class rtc = nil;
    
    if (ltc == NIMPRMoveOthersTool.class)
        rtc = NIMPRCenterZoomTool.class;
    
    if (self.rtool.class != rtc)
        self.rtool = [[[rtc alloc] init] autorelease];
    
    [self tool:self.ltool sel:@selector(hover:) event:event otherwise:nil];
    [self tool:self.rtool sel:@selector(hover:) event:event otherwise:nil];
}

- (Class)toolForLocation:(NSPoint)location event:(NSEvent*)event {
    if (event.type == NSMouseExited)
        return nil;
    if ((event.modifierFlags&NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask)
        return nil;
    
    NIAnnotationHandle* h = [self handleForSlicePoint:location];
    if (h)
        return NIMPRAnnotationHandleInteractionTool.class;
    
    CGFloat distance;
    NSString* ikey = [self intersectionClosestToPoint:location closestPoint:NULL distance:&distance];
    
    BOOL rotate = (ikey && distance <= 4);
    
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
    else if ((event.modifierFlags&NSDeviceIndependentModifierFlagsMask) == NSAlternateKeyMask)
        rotate = YES;
    
    Class ltc = nil;
    
    if (cmove)
        ltc = NIMPRMoveOthersTool.class;
    else if (move)
        ltc = NIMPRMoveTool.class;
    else if (rotate) {
        ltc = NIMPRRotateAxisTool.class;
        if ((event.modifierFlags&NSDeviceIndependentModifierFlagsMask) == NSAlternateKeyMask)
            ltc = NIMPRRotateTool.class;
    }
    
    if (!ltc) {
        NIAnnotation* annotation = [self annotationAtLocation:location];
        if (annotation)
            ltc = NIMPRAnnotationInteractionTool.class;
    }
    
    return ltc;
}

@end
