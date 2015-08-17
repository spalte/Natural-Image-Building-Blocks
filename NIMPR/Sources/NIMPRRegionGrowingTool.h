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

@interface NIMPRRegionGrowingTool : NIMPRAnnotateTool <NSPopoverDelegate, NSMenuDelegate> {
    NSPopover* _popover;
    BOOL _popoverDetached;
    NSWindow* _window;
    NIMaskIndex _seedPoint;
    NSOperation* _segmentation;
    NSArrayController* _segmentationAlgorithms;
    id _segmentationAlgorithmsSelectionObserver;
    NISegmentationAlgorithm* _algorithm;
}

@property(retain) NIMaskAnnotation* annotation;
@property(readonly) BOOL popoverDetached;
@property(readonly, retain) NISegmentationAlgorithm* algorithm;
@property NIMaskIndex seedPoint;

- (NSPopover*)popover;
- (NSViewController*)popoverViewController;

- (NSOperation*)segmentationWithSeed:(NIMaskIndex)seed volume:(NIVolumeData*)data annotation:(NIMaskAnnotation*)ma;

@end