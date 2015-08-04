//
//  NIMPRRegionGrowTool.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateTool.h"

@class NIMaskAnnotation;

@interface NIMPRRegionGrowingTool : NIMPRAnnotateTool <NSPopoverDelegate> {
    NSPopover* _popover;
}

@property(retain) NIMaskAnnotation* annotation;

- (NSPopover*)popover;
- (NSView*)popoverView;

@end
