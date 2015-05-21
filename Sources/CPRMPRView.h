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

@interface CPRMPRView : CPRGeneratorRequestView {
    N3Vector _point;
    CPRMPRQuaternion *_normal, *_xdir, *_ydir;
    CGFloat _pixelSpacing;
    NSColor* _color;
    NSUInteger _blockGeneratorRequestUpdates;
    N3Vector _mouseDownLocation;
    NSUInteger _mouseDownModifierFlags;
    N3AffineTransform _mouseDownGeneratorRequestSliceToDicomTransform;
    NSTrackingArea* _track;
}

@property N3Vector point;
@property(retain) CPRMPRQuaternion *normal, *xdir, *ydir;
@property CGFloat pixelSpacing;

@property(retain) NSColor* color;

- (void)setNormal:(CPRMPRQuaternion*)normal :(CPRMPRQuaternion*)xdir :(CPRMPRQuaternion*)ydir;

- (void)rotate:(CGFloat)rads axis:(N3Vector)axis;

@end

@interface CPRMPRView (super)

@property (nonatomic, readwrite, retain) CPRObliqueSliceGeneratorRequest* generatorRequest;
   
@end
