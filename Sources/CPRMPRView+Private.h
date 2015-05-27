//
//  CPRMPRView+Private.h
//  CPRMPR
//
//  Created by Alessandro Volz on 5/27/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#include "CPRMPRView.h"

@interface CPRMPRView ()

@property NSUInteger blockGeneratorRequestUpdates;
@property(retain) NSTrackingArea* track;
@property(retain) CPRMPRTool* tool;
@property NSUInteger eventModifierFlags;

@end