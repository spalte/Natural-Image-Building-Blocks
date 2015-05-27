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

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event {
    [super view:view mouseDown:event];
    
    self.previousLocationVector = self.mouseDownLocationVector;
    
    [NSCursor hide];
    [view enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
        intersection.maskAroundMouse = NO;
    }];
    
    return YES;
}

- (BOOL)view:(CPRMPRView*)view mouseDragged:(NSEvent*)event {
    N3Vector locationVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint([view convertPoint:event.locationInWindow fromView:nil]), self.mouseDownGeneratorRequestSliceToDicomTransform);
    
    N3Vector delta = N3VectorSubtract(locationVector, self.previousLocationVector);
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [self view:view move:delta];
    
    [CATransaction commit];
    
    self.previousLocationVector = locationVector;
    
    return YES;
}

- (void)view:(CPRMPRView*)view move:(N3Vector)delta {
    [view.window.windowController setPoint:N3VectorSubtract([view.window.windowController point], delta)];
}

- (BOOL)view:(CPRMPRView*)view mouseUp:(NSEvent*)event {
    [NSCursor unhide];
    
    return YES;
}

@end

@implementation CPRMPRInvertMoveTool

- (void)view:(CPRMPRView*)view move:(N3Vector)delta {
    [view.window.windowController setPoint:N3VectorAdd([view.window.windowController point], delta)];
}

@end