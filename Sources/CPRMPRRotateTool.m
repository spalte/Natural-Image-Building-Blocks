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

@implementation CPRMPRRotateTool

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
    
    return YES;
}

- (void)view:(CPRMPRView*)view rotate:(CGFloat)rads {
    [view rotate:-rads axis:view.normal.vector];
}

- (NSArray*)cursors {
    return @[ NSCursor.openHandCursor, NSCursor.closedHandCursor ];
}

@end
