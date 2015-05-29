//
//  CPRMPRRotateTool.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRRotateTool.h"
#import "CPRMPRQuaternion.h"
#import "CPRMPRView.h"
#import <Quartz/Quartz.h>

@interface CPRMPRRotateTool ()

@property(readwrite) N3Vector previousLocationVector;

@end

@implementation CPRMPRRotateTool

@synthesize previousLocationVector = _previousLocationVector;

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event or:(void(^)())or {
    return [super view:view mouseDown:event or:or confirm:^{
        [NSCursor.closedHandCursor set];
        self.previousLocationVector = self.mouseDownLocationVector;
    }];
}

- (BOOL)view:(CPRMPRView*)view mouseDragged:(NSEvent*)event {
    [super view:view mouseDragged:event];
    
    N3Vector centerVector = N3VectorApplyTransform(N3VectorMake(NSWidth(view.bounds)/2, NSHeight(view.bounds)/2, 0), self.mouseDownGeneratorRequestSliceToDicomTransform);
    
    CGFloat rads = N3VectorAngleBetweenVectorsAroundVector(N3VectorSubtract(self.previousLocationVector, centerVector), N3VectorSubtract(self.currentLocationVector, centerVector), view.normal.vector);
    if (rads > M_PI)
        rads -= M_PI*2;
    
    if (rads) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        [self view:view rotate:rads];
        
        [CATransaction commit];
    }
    
    self.previousLocationVector = self.currentLocationVector;
    
    return YES;
}

- (void)view:(CPRMPRView*)view rotate:(CGFloat)rads {
    [view rotate:-rads axis:view.normal.vector];
}

- (NSCursor*)cursor {
    return NSCursor.openHandCursor;
}

@end
