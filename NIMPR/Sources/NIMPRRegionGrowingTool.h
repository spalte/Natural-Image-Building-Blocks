//
//  NIMPRRegionGrowTool.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateTool.h"
#import "NISegmentationAlgorithm.h"

@class NIMaskAnnotation;

@interface NIMPRRegionGrowingTool : NIMPRAnnotateTool <NSPopoverDelegate> {
    NSPopover* _popover;
    BOOL _popoverDetached;
    id <NISegmentationAlgorithm> _segmentationAlgorithm;
}

@property(retain) NIMaskAnnotation* annotation;
@property(readonly) BOOL popoverDetached;
@property(readonly, retain) id <NISegmentationAlgorithm> segmentationAlgorithm;

- (NSPopover*)popover;
- (NSView*)popoverView;

@end
