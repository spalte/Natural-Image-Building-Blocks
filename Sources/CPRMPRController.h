//
//  MPRController.h
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OsiriXAPI/N3Geometry.h>
#import "CPRMPRTool.h"

@class CPRVolumeData;
@class CPRMPRView;
@class CPRMPRQuaternion;

typedef NS_OPTIONS(NSUInteger, CPRMPRFlags) {
    CPRMPRSupportsRotation      = 1<<0,
    CPRMPRSupportsAxisRotation  = 1<<1,
};

@interface CPRMPRController : NSWindowController <NSSplitViewDelegate, NSToolbarDelegate> {
    NSSplitView* _leftrightSplit;
    NSSplitView* _topbottomSplit;
    CPRMPRView* _axialView;
    CPRMPRView* _sagittalView;
    CPRMPRView* _coronalView;
    
    CPRVolumeData* _volumeData;
    CGFloat _windowWidth, _windowLevel;
    BOOL _displayOrientationLabels, _displayScaleBars;
    NSMenu* _menu;

    N3Vector _point;
    CPRMPRQuaternion *_x, *_y, *_z;
    
    CPRMPRFlags _flags;
    
    CPRMPRToolTag _currentToolTag;
    CPRMPRTool* _tool;
}

@property(assign) IBOutlet NSSplitView* leftrightSplit;
@property(assign) IBOutlet NSSplitView* topbottomSplit;
@property(assign) IBOutlet CPRMPRView* axialView; // top-left
@property(assign) IBOutlet CPRMPRView* sagittalView; // bottom-left
@property(assign) IBOutlet CPRMPRView* coronalView; // right

@property(retain) CPRVolumeData* volumeData;
@property CGFloat windowWidth, windowLevel;
@property BOOL displayOrientationLabels, displayScaleBars;
@property(retain) NSMenu* menu;

@property(retain, readonly) CPRMPRQuaternion *x, *y, *z;
@property N3Vector point;

@property CPRMPRFlags flags;

@property CPRMPRToolTag currentToolTag;
@property(retain, readonly) CPRMPRTool* tool;

- (instancetype)initWithData:(CPRVolumeData*)volumeData;

- (void)rotate:(CGFloat)rads axis:(N3Vector)axis excluding:(CPRMPRView*)view;

@end
