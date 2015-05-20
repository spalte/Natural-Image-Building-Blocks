//
//  MPRView.h
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CPRGeneratorRequestView.h"

@interface CPRMPRView : CPRGeneratorRequestView {
    N3Vector _point, _normal, _xdir, _ydir;
    CGFloat _pixelSpacing;
    NSColor* _color;
    NSUInteger _blockGeneratorRequestUpdates;
    NSPoint _mouseDownLocation;
//    NSArray* _storedVectors;
//    CGFloat _rotation;
}

@property N3Vector point, normal, xdir, ydir;
@property CGFloat pixelSpacing;//, rotation;

@property(retain) NSColor* color;

- (void)setNormal:(N3Vector)normal :(N3Vector)xdir :(N3Vector)ydir;

@end
