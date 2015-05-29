//
//  CPRMPRMoveTool.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRMoveTool.h"
#import "CPRMPRView.h"
#import "CPRIntersection.h"

@interface CPRMPRMoveTool ()

@property N3Vector previousLocationVector;

@end

@implementation CPRMPRMoveTool

@synthesize previousLocationVector = _previousLocationVector;

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event or:(void(^)())or {
    return [super view:view mouseDown:event or:or confirm:^{
        self.previousLocationVector = self.mouseDownLocationVector;
        
        [NSCursor hide];
        [view enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
            intersection.maskAroundMouse = NO;
        }];
    }];
}

- (BOOL)view:(CPRMPRView*)view mouseDragged:(NSEvent*)event {
    [super view:view mouseDragged:event];
    
    N3Vector delta = N3VectorSubtract(self.currentLocationVector, self.previousLocationVector);
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [self view:view move:delta];
    
    [CATransaction commit];
    
    self.previousLocationVector = self.currentLocationVector;
    
    return YES;
}

- (void)view:(CPRMPRView*)view move:(N3Vector)delta {
    [view.window.windowController setPoint:N3VectorSubtract([view.window.windowController point], delta)];
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

//@implementation CPRMPRInvertMoveTool
//
//- (void)view:(CPRMPRView*)view move:(N3Vector)delta {
//    [view.window.windowController setPoint:N3VectorAdd([view.window.windowController point], delta)];
//}
//
//@end