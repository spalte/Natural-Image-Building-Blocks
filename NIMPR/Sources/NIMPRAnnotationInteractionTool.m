//
//  NIMPRAnnotationSelectionTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/15/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotationInteractionTool.h"
#import "NIMPRView.h"

@implementation NIMPRAnnotationInteractionTool

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

    NSSet* annotations = [view annotationsIntersectingWithSliceRect:rect];
    
    [view.publicGlowingAnnotations intersectSet:annotations];
    [view.publicGlowingAnnotations unionSet:annotations];
    
    return YES;
}

- (BOOL)view:(NIMPRView*)view mouseUp:(NSEvent*)event {
    [super view:view mouseUp:event];
    
    [view.toolsLayer setNeedsDisplay];
    
    return YES;
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

- (NSArray*)cursors {
    return @[ NSCursor.pointingHandCursor, NSCursor.crosshairCursor ];
}

@end
