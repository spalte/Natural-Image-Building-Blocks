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

//@implementation CPRMPRInvertMoveTool
//
//- (void)view:(CPRMPRView*)view move:(N3Vector)delta {
//    [view.window.windowController setPoint:N3VectorAdd([view.window.windowController point], deltaVector)];
//}
//
//@end