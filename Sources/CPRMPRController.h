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
    
    CPRVolumeData* _data;
//    N3AffineTransform _transform;
//    CPRMPRQuaternion *_x, *_y, *_z;
    
    N3Vector _point;
    CGFloat _ww, _wl;
}

@property(assign) IBOutlet NSSplitView* leftrightSplit;
@property(assign) IBOutlet NSSplitView* topbottomSplit;
@property(assign) IBOutlet CPRMPRView* topleftView;
@property(assign) IBOutlet CPRMPRView* bottomleftView;
@property(assign) IBOutlet CPRMPRView* rightView;

@property(retain) CPRVolumeData* data;

@property N3Vector point;
@property CGFloat ww, wl;

- (instancetype)initWithData:(CPRVolumeData*)data;

- (void)rotate:(CGFloat)rads axis:(N3Vector)axis excluding:(CPRMPRView*)view;

@end
