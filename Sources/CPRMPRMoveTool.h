//
//  CPRMPRMoveTool.h
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRTool.h"

//typedef NS_ENUM(NSUInteger, CPRMPRMoveMode) {
//    CPRMPRMoveAllMode = 1,
//    CPRMPRMoveOthersMode,
//};

@interface CPRMPRMoveTool : CPRMPRDeltaTool

@end

@interface CPRMPRMoveOthersTool : CPRMPRMoveTool {
    N3Vector _point;
}

@end