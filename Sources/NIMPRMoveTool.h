//
//  NIMPRMoveTool.h
//  NIMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRTool.h"

//typedef NS_ENUM(NSUInteger, NIMPRMoveMode) {
//    NIMPRMoveAllMode = 1,
//    NIMPRMoveOthersMode,
//};

@interface NIMPRMoveTool : NIMPRDeltaTool

@end

@interface NIMPRMoveOthersTool : NIMPRMoveTool {
    NIVector _point;
}

@end