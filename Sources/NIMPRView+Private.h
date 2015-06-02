//
//  NIMPRView+Private.h
//  NIMPR
//
//  Created by Alessandro Volz on 5/27/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#include "NIMPRView.h"

@interface NIMPRView ()

@property(retain) NIVolumeDataProperties* dataProperties;
@property NSUInteger blockGeneratorRequestUpdates;
@property(retain) NSTrackingArea* track;
@property(retain, nonatomic) id <NIMPRTool> ltool, rtool, ltoolOnDoubleClick;
@property NSUInteger eventModifierFlags;
@property(getter=mouseIsDown) BOOL mouseDown;
//@property(retain) NSMutableArray* latestMouseDownEvents;

@end