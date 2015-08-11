//
//  NIMPRAnnotationSelectionTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/15/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotationSelectionTool.h"
#import "NIAnnotation.h"
#import "NIMPRView.h"

@interface NIMPRAnnotationSelectionTool ()

@property(retain) NSMutableSet* annotations;

@end

@implementation NIMPRAnnotationSelectionTool

@synthesize annotations = _annotations;

- (id)initWithViewer:(NIMPRWindowController*)viewer {
    if ((self = [super initWithViewer:viewer])) {
        self.annotations = [NSMutableSet set];
    }
    
    return self;
}

- (void)dealloc {
    self.annotations = nil;
    [super dealloc];
}

- (BOOL)view:(NIMPRView*)view flagsChanged:(NSEvent*)event {
    if (self.mouseDownEvent)
        return NO;
    
    [self.annotations set:view.highlightedAnnotations];
    
    return NO;
}

- (BOOL)view:(NIMPRView *)view mouseDown:(NSEvent *)event otherwise:(void (^)())otherwise confirm:(void (^)())confirm {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^{
        [self view:view mouseDragged:event];
    }];
}

- (BOOL)view:(NIMPRView*)view mouseDragged:(NSEvent*)event {
    [super view:view mouseDragged:event];
    
    [view.toolsLayer setNeedsDisplay];
    
    NSRect rect = NSMakeRect(self.mouseDownLocation.x, self.mouseDownLocation.y, self.currentLocation.x-self.mouseDownLocation.x, self.currentLocation.y-self.mouseDownLocation.y);
    if (rect.size.width < 0) {
        rect.size.width *= -1;
        rect.origin.x -= rect.size.width; }
    if (rect.size.height < 0) {
        rect.size.height *= -1;
        rect.origin.y -= rect.size.height; }

    [self.annotations set:[view annotationsIntersectingWithSliceRect:NSInsetRect(rect, -NIAnnotationDistant, -NIAnnotationDistant)]];
    
    [view.mutableHighlightedAnnotations set:self.annotations];
    
    return YES;
}

- (BOOL)view:(NIMPRView*)view mouseUp:(NSEvent*)event {
    [view.toolsLayer setNeedsDisplay];

    if (self.mouseDownEvent.modifierFlags&NSShiftKeyMask) {
        if (self.mouseDownEvent.modifierFlags&NSAlternateKeyMask)
            [view.mutableSelectedAnnotations minusSet:self.annotations];
        else [view.mutableSelectedAnnotations unionSet:self.annotations];
    } else [view.mutableSelectedAnnotations set:self.annotations];

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
    NSMutableSet* set = [NSMutableSet setWithSet:self.annotations];
    [set minusSet:view.selectedAnnotations];
    return @[ (set.count? NSCursor.pointingHandCursor : NSCursor.crosshairCursor), NSCursor.crosshairCursor ];
}

@end
