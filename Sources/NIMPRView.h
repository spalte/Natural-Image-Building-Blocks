//
//  MPRView.h
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#pragma once

#import <NIBuildingBlocks/NIGeneratorRequestView.h>
#import "NIMPRController.h"

@class NIObliqueSliceGeneratorRequest;
@class NIMPRQuaternion;
@class NIVolumeDataProperties;

@interface NIMPRView : NIGeneratorRequestView {
    NIVolumeData* _data;
    NIVolumeDataProperties* _dataProperties;
    CGFloat _windowLevel, _windowWidth;
    NIVector _point;
    NIMPRQuaternion *_normal, *_xdir, *_ydir, *_reference;
    CGFloat _pixelSpacing;
//    NSColor* _color;
    NSUInteger _blockGeneratorRequestUpdates;
    NSUInteger _eventModifierFlags;
    NSTrackingArea* _track;
    NIMPRFlags _flags;
    NSMenu* _menu;
    id <NIMPRTool> _ltool, _rtool;
    Class _ltcAtSecondClick;
//    NSMutableArray* _latestMouseDownEvents;
    CGFloat _slabWidth;
    BOOL _mouseDown;
}

@property(retain) NIVolumeData* data;
@property CGFloat windowLevel, windowWidth;
@property CGFloat slabWidth;

@property NIVector point;
@property(retain) NIMPRQuaternion *normal, *xdir, *ydir, *reference;
@property CGFloat pixelSpacing;

//@property(retain) NSColor* color;
@property(retain) NSMenu* menu;

@property NIMPRFlags flags;

- (void)setNormal:(NIMPRQuaternion*)normal :(NIMPRQuaternion*)xdir :(NIMPRQuaternion*)ydir reference:(NIMPRQuaternion*)reference;

- (void)rotate:(CGFloat)rads axis:(NIVector)axis;
- (void)rotateToInitial;

@end

@interface NIMPRView (super)

@property (nonatomic, readwrite, retain) NIObliqueSliceGeneratorRequest* generatorRequest;
   
@end
