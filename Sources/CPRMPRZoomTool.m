//
//  CPRMPRZoomTool.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRZoomTool.h"
#import "CPRMPRView.h"
#import "CPRIntersection.h"
#import <OsiriXAPI/CPRGeneratorRequest.h>

@interface CPRMPRZoomTool ()

@property NSPoint previousLocation;

@end

@implementation CPRMPRZoomTool

@synthesize previousLocation = _previousLocation;

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event or:(void(^)())or {
    return [super view:view mouseDown:event or:or confirm:^{
        self.previousLocation = self.mouseDownLocation;
        
        [NSCursor hide];
        [view enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
            intersection.maskAroundMouse = NO;
        }];
    }];
}

- (BOOL)view:(CPRMPRView*)view mouseDragged:(NSEvent*)event {
    [super view:view mouseDragged:event];
    
    NSPoint ldelta = NSMakePoint(self.currentLocation.x-self.previousLocation.x, self.currentLocation.y-self.previousLocation.y);

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    view.pixelSpacing = view.pixelSpacing+ldelta.y*view.pixelSpacing/100;
    
    if ((self.mouseDownEvent.modifierFlags&NSCommandKeyMask) == 0) {
        N3Vector delta = N3VectorSubtract(N3VectorApplyTransform(N3VectorMakeFromNSPoint(self.mouseDownLocation), view.generatorRequest.sliceToDicomTransform), self.mouseDownLocationVector);
        [view.window.windowController setPoint:N3VectorSubtract([view.window.windowController point], delta)];
    }
    
    [CATransaction commit];
    
    self.previousLocation = self.currentLocation;
    
    return YES;
}

- (BOOL)view:(CPRMPRView*)view mouseUp:(NSEvent*)event {
    if (![super view:view mouseUp:event]) {
        [NSCursor unhide];
    }
    
    return YES;
}

//- (NSCursor*)cursor {
//    return nil;
//}

@end
