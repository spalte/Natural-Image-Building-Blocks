//
//  NIMPRZoomTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRZoomTool.h"
#import "NIMPRView.h"
#import <NIBuildingBlocks/NIIntersection.h>
#import <NIBuildingBlocks/NIGeneratorRequest.h>

@implementation NIMPRZoomTool

- (BOOL)view:(NIMPRView*)view move:(NSPoint)ldelta vector:(NIVector)deltaVector {
    return [self view:view move:ldelta recenter:((self.mouseDownEvent.modifierFlags&NSCommandKeyMask) == 0)];
}

- (BOOL)view:(NIMPRView*)view move:(NSPoint)ldelta recenter:(BOOL)recenter {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    view.pixelSpacing = view.pixelSpacing+ldelta.y*view.pixelSpacing/100;
    
    if (recenter) {
        NIVector delta = NIVectorSubtract(NIVectorApplyTransform(NIVectorMakeFromNSPoint(self.mouseDownLocation), view.generatorRequest.sliceToDicomTransform), self.mouseDownLocationVector);
        [view.window.windowController setPoint:NIVectorSubtract([view.window.windowController point], delta)];
    }
    
    [CATransaction commit];
    
    return YES;
}

- (NSArray*)cursors {
    return @[ NSCursor.arrowCursor, NSNull.null ];
}

@end

@implementation NIMPRCenterZoomTool

- (BOOL)view:(NIMPRView*)view move:(NSPoint)ldelta vector:(NIVector)deltaVector {
    return [self view:view move:ldelta recenter:NO];
}

@end