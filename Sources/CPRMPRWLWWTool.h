//
//  CPRMPRWLWWTool.h
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRTool.h"

@interface CPRMPRWLWWTool : CPRMPRTool {
    CGFloat _mouseDownWindowLevel, _mouseDownWindowWidth;
    NSPoint _previousLocation;
}

@end
