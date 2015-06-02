//
//  NIMPRRotateAxisTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRRotateAxisTool.h"
#import "NIMPRView.h"
#import "NIMPRQuaternion.h"

@implementation NIMPRRotateAxisTool

- (void)view:(NIMPRView*)view rotate:(CGFloat)rads {
    [view.window.windowController rotate:rads axis:view.normal.vector excluding:view];
}

@end
