//
//  CPRMPRController+Private.h
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRController.h"

@interface CPRMPRController ()

@property(retain, readwrite) CPRMPRQuaternion *x, *y, *z;
@property(retain, readwrite) CPRMPRTool *ltool, *rtool;

@end