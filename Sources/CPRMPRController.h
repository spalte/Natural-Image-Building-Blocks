//
//  MPRController.h
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRView.h"

@class CPRMPRQuaternion;

@interface CPRMPRController : NSWindowController <NSSplitViewDelegate> {
    NSSplitView* _leftrightSplit;
    NSSplitView* _topbottomSplit;
    CPRMPRView* _topleftView;
    CPRMPRView* _bottomleftView;
    CPRMPRView* _rightView;
    
    CPRVolumeData* _volumeData;
    CGFloat _windowWidth, _windowLevel;
    BOOL displayOrientationLabels, _displayScaleBars;
    NSMenu* _menu;

    N3Vector _point;
    CPRMPRQuaternion *_x, *_y, *_z;
    
    CPRMPRFlags _flags;
}

@property(assign) IBOutlet NSSplitView* leftrightSplit;
@property(assign) IBOutlet NSSplitView* topbottomSplit;
@property(assign) IBOutlet CPRMPRView* topleftView;
@property(assign) IBOutlet CPRMPRView* bottomleftView;
@property(assign) IBOutlet CPRMPRView* rightView;

@property(retain) CPRVolumeData* volumeData;
@property CGFloat windowWidth, windowLevel;
@property BOOL displayOrientationLabels, displayScaleBars;
@property(retain) NSMenu* menu;

@property(retain, readonly) CPRMPRQuaternion *x, *y, *z;
@property N3Vector point;

@property CPRMPRFlags flags;

- (instancetype)initWithData:(CPRVolumeData*)volumeData;

- (void)rotate:(CGFloat)rads axis:(N3Vector)axis excluding:(CPRMPRView*)view;

@end
