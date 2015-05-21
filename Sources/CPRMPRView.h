//
//  MPRView.h
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CPRGeneratorRequestView.h"

@class CPRObliqueSliceGeneratorRequest;
@class CPRMPRQuaternion;

typedef NS_OPTIONS(NSUInteger, CPRMPRFlags) {
    CPRMPRSupportsRotation      = 1<<0,
    CPRMPRSupportsAxisRotation  = 1<<1,
};

@interface CPRMPRView : CPRGeneratorRequestView {
    N3Vector _point;
    CPRMPRQuaternion *_normal, *_xdir, *_ydir, *_reference;
    CGFloat _pixelSpacing;
    NSColor* _color;
    NSUInteger _blockGeneratorRequestUpdates;
    N3Vector _mouseDownLocation;
    NSUInteger _mouseDownModifierFlags;
    N3AffineTransform _mouseDownGeneratorRequestSliceToDicomTransform;
    NSTrackingArea* _track;
    CPRMPRFlags _flags;
    NSMenu* _menu;
}

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
