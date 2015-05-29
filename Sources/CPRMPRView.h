//
//  MPRView.h
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CPRGeneratorRequestView.h"
#import "CPRMPRController.h"

@class CPRObliqueSliceGeneratorRequest;
@class CPRMPRQuaternion;
@class CPRVolumeDataProperties;

@interface CPRMPRView : CPRGeneratorRequestView {
    CPRVolumeData* _data;
    CPRVolumeDataProperties* _dataProperties;
    CGFloat _windowLevel, _windowWidth;
    N3Vector _point;
    CPRMPRQuaternion *_normal, *_xdir, *_ydir, *_reference;
    CGFloat _pixelSpacing;
    NSColor* _color;
    NSUInteger _blockGeneratorRequestUpdates;
    NSUInteger _eventModifierFlags;
    NSTrackingArea* _track;
    CPRMPRFlags _flags;
    NSMenu* _menu;
    id <CPRMPRTool> _ltool, _rtool;
    CGFloat _slabWidth;
}

@property(retain) CPRVolumeData* data;
@property CGFloat windowLevel, windowWidth;
@property CGFloat slabWidth;

@property N3Vector point;
@property(retain) CPRMPRQuaternion *normal, *xdir, *ydir, *reference;
@property CGFloat pixelSpacing;

@property(retain) NSColor* color;
@property(retain) NSMenu* menu;

@property CPRMPRFlags flags;

- (void)setNormal:(CPRMPRQuaternion*)normal :(CPRMPRQuaternion*)xdir :(CPRMPRQuaternion*)ydir reference:(CPRMPRQuaternion*)reference;

- (void)rotate:(CGFloat)rads axis:(N3Vector)axis;
- (void)rotateToInitial;

@end

@interface CPRMPRView (super)

@property (nonatomic, readwrite, retain) CPRObliqueSliceGeneratorRequest* generatorRequest;
   
@end
