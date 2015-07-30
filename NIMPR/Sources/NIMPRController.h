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
@class NIMPRLayoutRecord;

typedef NS_OPTIONS(NSUInteger, NIMPRFlags) {
    NIMPRSupportsRotation      = 1<<0,
    NIMPRSupportsAxisRotation  = 1<<1,
};

typedef NS_ENUM(NSInteger, NIMPRLayoutTag) {
    NIMPRLayoutClassic = 0,
    NIMPRLayoutVertical,
    NIMPRLayoutHorizontal,
    NIMPRLayoutsCount
};

@interface NIMPRController : NSWindowController <NSToolbarDelegate, NSMenuDelegate> {
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

@property(readonly,retain) NIMPRView* axialView; // top-left
@property(readonly,retain) NIMPRView* sagittalView; // bottom-left
@property(readonly,retain) NIMPRView* coronalView; // right

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

- (id)initWithData:(NIVolumeData*)data wl:(CGFloat)wl ww:(CGFloat)ww;
- (id)initWithData:(NIVolumeData*)data window:(NSWindow*)window wl:(CGFloat)wl ww:(CGFloat)ww;

+ (Class)mprViewClass;
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

- (IBAction)testImage:(id)sender;
- (IBAction)testMask:(id)sender;

@end
