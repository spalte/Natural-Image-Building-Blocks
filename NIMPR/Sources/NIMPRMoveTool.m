//
//  NIMPRMoveTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRMoveTool.h"
#import "NIMPRView.h"
#import <NIBuildingBlocks/NIIntersection.h>

@implementation NIMPRMoveTool

- (BOOL)view:(NIMPRView*)view move:(NSPoint)delta vector:(NIVector)deltaVector {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [view.window.windowController setPoint:NIVectorSubtract([view.window.windowController point], deltaVector)];
    
    [CATransaction commit];

    return YES;
}

- (BOOL)repositionsCursor {
    return NO;
}

- (NSArray*)cursors {
    return @[ NSCursor.openHandCursor, NSNull.null ];
}

@end

@interface NIMPRMoveOthersTool ()

@property NIVector point;

@end

@implementation NIMPRMoveOthersTool

@synthesize point = _point;

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise confirm:(void(^)())confirm {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^{
        self.point = view.point;
        if (confirm)
            confirm();
    }];
}

- (BOOL)view:(NIMPRView*)view move:(NSPoint)delta vector:(NIVector)deltaVector {
    self.point = NIVectorAdd(self.point, deltaVector);
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    for (NIMPRView* mprview in [view.window.windowController mprViews])
        if (mprview != view)
            [mprview setPoint:self.point];
    
    [CATransaction commit];
    
    return YES;
}

- (BOOL)view:(NIMPRView*)view mouseUp:(NSEvent*)event {
    [view.window.windowController setPoint:self.point];
    return [super view:view mouseUp:event];
}

@end