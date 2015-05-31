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

@implementation CPRMPRZoomTool

- (BOOL)view:(CPRMPRView*)view move:(NSPoint)ldelta vector:(N3Vector)deltaVector {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    view.pixelSpacing = view.pixelSpacing+ldelta.y*view.pixelSpacing/100;
    
    if ((self.mouseDownEvent.modifierFlags&NSCommandKeyMask) == 0) {
        N3Vector delta = N3VectorSubtract(N3VectorApplyTransform(N3VectorMakeFromNSPoint(self.mouseDownLocation), view.generatorRequest.sliceToDicomTransform), self.mouseDownLocationVector);
        [view.window.windowController setPoint:N3VectorSubtract([view.window.windowController point], delta)];
    }
    
    [CATransaction commit];
    
    return YES;
}

- (NSArray*)cursors {
    return @[ NSCursor.arrowCursor, NSNull.null ];
}

@end
