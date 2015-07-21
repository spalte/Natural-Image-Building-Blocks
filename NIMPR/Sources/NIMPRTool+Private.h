//
//  NIMPRTool+Private.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#include "NIMPRTool.h"

@interface NIMPRTool ()

@property(readwrite, retain) NSView* mouseDownView;
@property(retain, readwrite) NSEvent* mouseDownEvent;
@property(copy) void (^timeoutBlock)(), (^confirmBlock)();
@property(retain, readwrite) NSTimer* timeoutTimer;
@property(readwrite) NSPoint mouseDownLocation, currentLocation, previousLocation;
@property(readwrite) NIVector mouseDownLocationVector, currentLocationVector, previousLocationVector;
@property(readwrite) NIAffineTransform mouseDownGeneratorRequestSliceToDicomTransform;

@end

