//
//  MPRController.h
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#pragma once

#import <NIBuildingBlocks/NIGeneratorRequest.h>
#import "NIMPRTool.h"

@class NIVolumeData;
@class NIMPRView;
@class NIMPRQuaternion;

typedef NS_OPTIONS(NSUInteger, NIMPRFlags) {
    NIMPRSupportsRotation      = 1<<0,
    NIMPRSupportsAxisRotation  = 1<<1,
};

typedef NS_ENUM(NSInteger, NIMPRLayoutTag) {
    NIMPRLayoutClassic = 0,
    NIMPRLayoutVertical,
    NIMPRLayoutHorizontal,
};

@interface NIMPRController : NSWindowController <NSToolbarDelegate, NSMenuDelegate> {
//    NSSplitView* _leftrightSplit;
//    NSSplitView* _topbottomSplit;
    NIMPRView* _axialView;
    NIMPRView* _sagittalView;
    NIMPRView* _coronalView;
    
    NSMutableSet* _annotations;
    NSMutableSet* _highlightedAnnotations;
    NSMutableSet* _selectedAnnotations;
    
    NIVolumeData* _data;
    CGFloat _windowWidth, _windowLevel, _initialWindowLevel, _initialWindowWidth;
    BOOL _displayOverlays, _displayOrientationLabels, _displayScaleBars, _displayRims;
    NSMenu* _menu;

    NIVector _point;
    NIMPRQuaternion *_x, *_y, *_z;
    
    NIMPRFlags _flags;
    
    NIMPRToolTag _ltoolTag, _rtoolTag;
    NIMPRTool *_ltool, *_rtool;
    
    NIMPRLayoutTag _viewsLayout;
    
    BOOL _projectionFlag;
    NIProjectionMode _projectionMode;
    CGFloat _slabWidth;
    
    BOOL _spacebarDown;
}

//@property(assign) IBOutlet NSSplitView* leftrightSplit;
//@property(assign) IBOutlet NSSplitView* topbottomSplit;
@property(assign) IBOutlet NIMPRView* axialView; // top-left
@property(assign) IBOutlet NIMPRView* sagittalView; // bottom-left
@property(assign) IBOutlet NIMPRView* coronalView; // right

@property(retain) NIVolumeData* data;
@property CGFloat windowWidth, windowLevel;
@property BOOL displayOverlays, displayOrientationLabels, displayScaleBars, displayRims;
@property(retain) NSMenu* menu;

@property(retain, readonly) NIMPRQuaternion *x, *y, *z;
@property NIVector point;

@property NIMPRFlags flags;

@property NIMPRToolTag ltoolTag, rtoolTag;
@property(retain, readonly) NIMPRTool *ltool, *rtool;

@property NIMPRLayoutTag viewsLayout;

@property BOOL projectionFlag;
@property NIProjectionMode projectionMode;
@property CGFloat slabWidth;

@property(readonly,getter=spacebarIsDown) BOOL spacebarDown;

- (instancetype)initWithData:(NIVolumeData*)data window:(CGFloat)wl :(CGFloat)ww;

- (NSArray*)mprViews;
- (NSView*)mprViewsContainer;

@property(readonly, copy) NSSet* annotations;
- (NSMutableSet*)mutableAnnotations;
@property(readonly, copy) NSSet* highlightedAnnotations;
- (NSMutableSet*)mutableHighlightedAnnotations;
@property(readonly, copy) NSSet* selectedAnnotations;
- (NSMutableSet*)mutableSelectedAnnotations;

- (void)rotate:(CGFloat)rads axis:(NIVector)axis excluding:(NIMPRView*)view;
- (void)rotateToInitial;
- (void)moveToInitial;
- (void)reset;

@end
