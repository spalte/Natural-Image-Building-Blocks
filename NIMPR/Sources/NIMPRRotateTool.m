//
//  NIMPRRotateTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRRotateTool.h"
#import "NIMPRQuaternion.h"
#import "NIMPRView.h"
#import <Quartz/Quartz.h>

@implementation NIMPRRotateTool

- (BOOL)view:(NIMPRView*)view mouseDragged:(NSEvent*)event {
    [super view:view mouseDragged:event];
    
    NIVector centerVector = NIVectorApplyTransform(NIVectorMake(NSWidth(view.bounds)/2, NSHeight(view.bounds)/2, 0), self.mouseDownGeneratorRequestSliceToDicomTransform);
    
    CGFloat rads = NIVectorAngleBetweenVectorsAroundVector(NIVectorSubtract(self.previousLocationVector, centerVector), NIVectorSubtract(self.currentLocationVector, centerVector), view.normal.vector);
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

- (void)view:(NIMPRView*)view rotate:(CGFloat)rads {
    [view rotate:-rads axis:view.normal.vector];
}

- (NSArray*)cursors {
    return @[ NSCursor.openHandCursor, NSCursor.closedHandCursor ];
}

@end

@implementation NIMPRRotateAxisTool

- (void)view:(NIMPRView*)view rotate:(CGFloat)rads {
    [view.window.windowController rotate:rads axis:view.normal.vector excluding:view];
}

@end

