//
//  CPRMPRTool.h
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <OsiriXAPI/N3Geometry.h>

typedef NS_ENUM(NSInteger, CPRMPRToolTag) {
    CPRMPRToolWLWW = 1,
    CPRMPRToolMove,
    CPRMPRToolZoom,
    CPRMPRToolRotate,
    CPRMPRToolRotateAxis,
//    CPRMPRToolROI,
};

@class CPRMPRView;

@protocol CPRMPRTool <NSObject>

// notice that the view redirects rightMouse* and otherMouse* events to mouse*
@optional
- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view mouseUp:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view mouseMoved:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view mouseDragged:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view scrollWheel:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view mouseEntered:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view mouseExited:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view keyDown:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view keyUp:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view flagsChanged:(NSEvent*)event;

@end

@interface CPRMPRTool : NSObject <CPRMPRTool> {
    NSView* _mouseDownView;
    NSEvent* _mouseDownEvent;
    void (^_timeoutBlock)(), (^_confirmBlock)();
    NSTimer* _timeoutTimer;
    NSPoint _mouseDownLocation, _currentLocation;
    N3Vector _mouseDownLocationVector, _currentLocationVector;
    N3AffineTransform _mouseDownGeneratorRequestSliceToDicomTransform;
}

@property(readonly, retain) NSEvent* mouseDownEvent;
@property(readonly, retain) NSTimer* timeoutTimer;

@property(readonly) NSPoint mouseDownLocation, currentLocation;
@property(readonly) N3Vector mouseDownLocationVector, currentLocationVector;
@property(readonly) N3AffineTransform mouseDownGeneratorRequestSliceToDicomTransform;

+ (instancetype)toolForTag:(CPRMPRToolTag)tag;

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event UNAVAILABLE_ATTRIBUTE;
- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event or:(void(^)())or confirm:(void(^)())confirm NS_REQUIRES_SUPER;
- (BOOL)view:(CPRMPRView*)view mouseDragged:(NSEvent*)event NS_REQUIRES_SUPER;
- (BOOL)view:(CPRMPRView*)view mouseUp:(NSEvent*)event NS_REQUIRES_SUPER;

- (NSTimeInterval)timeout;
- (NSCursor*)cursor;

- (void)moveCursorToMouseDownLocation;

@end
