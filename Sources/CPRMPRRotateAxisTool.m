//
//  CPRMPRRotateAxisTool.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRRotateAxisTool.h"
#import "CPRMPRView.h"
#import "CPRMPRQuaternion.h"

@implementation CPRMPRRotateAxisTool

- (void)view:(CPRMPRView*)view mouseDraggedRadiants:(CGFloat)rads {
    [view.window.windowController rotate:rads axis:view.normal.vector excluding:view];
}

@end
