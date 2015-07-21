//
//  NIMPRAnnotationSelectionTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/15/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotationInteractionTool.h"
#import "NIMPRView.h"

@interface NIMPRAnnotationInteractionTool ()

//@property(retain, readwrite) NSSet* mouseDownHighlightedAnnotations;

@end

@implementation NIMPRAnnotationInteractionTool

@synthesize mode = _mode;

- (BOOL)view:(NIMPRView *)view mouseMoved:(NSEvent *)event {
    [self view:view flagsChanged:event];
    return NO;
}

- (BOOL)view:(NIMPRView*)view flagsChanged:(NSEvent*)event {
    if (self.mouseDownEvent)
        return NO;
    
    NIMPRAnnotationInteractionToolMode mode = NIMPRAnnotationSelectionInteractionToolMode;
    
    NSPoint location = [view.window convertPointFromScreen:[NSEvent mouseLocation]];
    NIAnnotation* a = [view annotationAtLocation:[view convertPoint:location fromView:nil]];
    
    NSSet* as = [NSSet setWithObjects: a, nil];
    
    if (event.modifierFlags&NSCommandKeyMask) {
    } else if (event.modifierFlags&NSShiftKeyMask) {
    } else if ([view.selectedAnnotations intersectsSet:as]) {
        as = view.selectedAnnotations;
        mode = NIMPRAnnotationMoveInteractionToolMode;
    }
    
    [view.mutableHighlightedAnnotations set:as];
    
    self.mode = mode;
    
    return NO;
}

- (BOOL)view:(NIMPRView *)view mouseDown:(NSEvent *)event otherwise:(void (^)())otherwise confirm:(void (^)())confirm {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^() {
        if (self.mode == NIMPRAnnotationSelectionInteractionToolMode) {
            [self view:view mouseDragged:event];
        }
    }];
}

- (BOOL)view:(NIMPRView*)view mouseDragged:(NSEvent*)event {
    [super view:view mouseDragged:event];
    
    if (self.mode == NIMPRAnnotationSelectionInteractionToolMode) {
        [view.toolsLayer setNeedsDisplay];
        
        NSRect rect = NSMakeRect(self.mouseDownLocation.x, self.mouseDownLocation.y, self.currentLocation.x-self.mouseDownLocation.x, self.currentLocation.y-self.mouseDownLocation.y);
        if (rect.size.width < 0) {
            rect.size.width *= -1;
            rect.origin.x -= rect.size.width; }
        if (rect.size.height < 0) {
            rect.size.height *= -1;
            rect.origin.y -= rect.size.height; }

        NSSet* annotations = [view annotationsIntersectingWithSliceRect:NSInsetRect(rect, -NIAnnotationDistant, -NIAnnotationDistant)];
        
        [view.mutableHighlightedAnnotations set:annotations];
    } else if (self.mode == NIMPRAnnotationMoveInteractionToolMode) {
        for (NIAnnotation* a in view.selectedAnnotations)
            [a translate:NIVectorSubtract(self.currentLocationVector, self.previousLocationVector)];
    }
    
    return YES;
}

- (BOOL)view:(NIMPRView*)view mouseUp:(NSEvent*)event {
    if (self.mode == NIMPRAnnotationSelectionInteractionToolMode) {
        [view.toolsLayer setNeedsDisplay];
    
        if (self.mouseDownEvent.modifierFlags&NSShiftKeyMask) {
            if (self.mouseDownEvent.modifierFlags&NSAlternateKeyMask)
                [view.mutableSelectedAnnotations minusSet:view.highlightedAnnotations];
            else [view.mutableSelectedAnnotations unionSet:view.highlightedAnnotations];
        } else [view.mutableSelectedAnnotations set:view.highlightedAnnotations];
    }

    [self view:view flagsChanged:event];
    [super view:view mouseUp:event];
    
    return NO;
}

- (void)drawInView:(NIMPRView*)view {
    if (self.mouseDownView) {
        NSBezierPath* path = [NSBezierPath bezierPathWithRect:NSMakeRect(self.mouseDownLocation.x, self.mouseDownLocation.y, self.currentLocation.x-self.mouseDownLocation.x, self.currentLocation.y-self.mouseDownLocation.y)];
        [[NSColor.blackColor colorWithAlphaComponent:0.5] set];
        path.lineWidth = 1.5;
        [path stroke];
        [[NSColor.whiteColor colorWithAlphaComponent:0.75] set];
        path.lineWidth = 0.5;
        [path stroke];
    }
}

- (NSArray*)cursorsForView:(NIMPRView*)view {
    if (self.mode == NIMPRAnnotationMoveInteractionToolMode)
        return @[ NSCursor.openHandCursor, NSCursor.closedHandCursor ];
    
    NSMutableSet* set = [NSMutableSet setWithSet:view.highlightedAnnotations];
    [set minusSet:view.selectedAnnotations];
    
    return @[ (set.count? NSCursor.pointingHandCursor : NSCursor.crosshairCursor), NSCursor.crosshairCursor ];
}

@end
