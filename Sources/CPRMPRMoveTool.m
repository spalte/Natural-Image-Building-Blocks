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

@implementation CPRMPRMoveTool

- (BOOL)view:(CPRMPRView*)view move:(NSPoint)delta vector:(N3Vector)deltaVector {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [view.window.windowController setPoint:N3VectorSubtract([view.window.windowController point], deltaVector)];
    
    [CATransaction commit];

    return YES;
}

- (NSArray*)cursors {
    return @[ NSCursor.openHandCursor, NSNull.null ];
}

@end

@interface CPRMPRMoveOthersTool ()

@property N3Vector point;

@end

@implementation CPRMPRMoveOthersTool

@synthesize point = _point;

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event or:(void(^)())or confirm:(void(^)())confirm {
    return [super view:view mouseDown:event or:or confirm:^{
        self.point = view.point;
        if (confirm)
            confirm();
    }];
}

- (BOOL)view:(CPRMPRView*)view move:(NSPoint)delta vector:(N3Vector)deltaVector {
    self.point = N3VectorAdd(self.point, deltaVector);
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    for (CPRMPRView* mprview in [view.window.windowController mprViews])
        if (mprview != view)
            [mprview setPoint:self.point];
    
    [CATransaction commit];
    
    return YES;
}

- (BOOL)view:(CPRMPRView*)view mouseUp:(NSEvent*)event {
    [view.window.windowController setPoint:self.point];
    return [super view:view mouseUp:event];
}

@end