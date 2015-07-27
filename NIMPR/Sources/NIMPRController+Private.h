//
//  NIMPRController+Private.h
//  NIMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRController.h"

@interface NIMPRController ()

@property(readwrite,retain) NIMPRView* axialView; // top-left
@property(readwrite,retain) NIMPRView* sagittalView; // bottom-left
@property(readwrite,retain) NIMPRView* coronalView; // right

@property CGFloat initialWindowLevel, initialWindowWidth;
@property(retain, readwrite) NIMPRQuaternion *x, *y, *z;
@property(retain, readwrite) NIMPRTool *ltool, *rtool;

@property(readwrite,getter=spacebarIsDown) BOOL spacebarDown;

@end