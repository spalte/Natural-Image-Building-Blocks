//
//  NIMPRRegionGrowTool.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateTool.h"

@class NIMaskAnnotation;
@class NIMPRRegionGrowToolWindowController;

@interface NIMPRRegionGrowTool : NIMPRAnnotateTool {
    NIMPRRegionGrowToolWindowController* _controller;
}

@property(retain) NIMaskAnnotation* annotation;
@property(readonly, retain) NIMPRRegionGrowToolWindowController* controller;

@end
