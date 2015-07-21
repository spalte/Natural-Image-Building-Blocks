//
//  NIMPRTool.h
//  NIMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <NIBuildingBlocks/NIGeometry.h>

typedef NS_ENUM(NSInteger, NIMPRToolTag) {
    NIMPRToolWLWW = 1,
    NIMPRToolMove,
    NIMPRToolZoom,
    NIMPRToolRotate,
    NIMPRToolRotateAxis,
    NIMPRToolInteract,
    NIMPRToolAnnotatePoint,
    NIMPRToolAnnotateSegment,
    NIMPRToolAnnotateRectangle,
    NIMPRToolAnnotateEllipse,
};

@class NIMPRView;

@protocol NIMPRTool <NSObject>

- (NSEvent*)mouseDownEvent;
- (NSArray*)cursorsForView:(NIMPRView*)view;

// notice that the view redirects rightMouse* and otherMouse* events to mouse*
@optional
- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event;
- (BOOL)view:(NIMPRView*)view mouseUp:(NSEvent*)event;
- (BOOL)view:(NIMPRView*)view mouseMoved:(NSEvent*)event;
- (BOOL)view:(NIMPRView*)view mouseDragged:(NSEvent*)event;
- (BOOL)view:(NIMPRView*)view scrollWheel:(NSEvent*)event;
- (BOOL)view:(NIMPRView*)view mouseEntered:(NSEvent*)event;
- (BOOL)view:(NIMPRView*)view mouseExited:(NSEvent*)event;
- (BOOL)view:(NIMPRView*)view keyDown:(NSEvent*)event;
- (BOOL)view:(NIMPRView*)view keyUp:(NSEvent*)event;
- (BOOL)view:(NIMPRView*)view flagsChanged:(NSEvent*)event;

@end

@interface NIMPRTool : NSObject <NIMPRTool> {
    NSView* _mouseDownView;
    NSEvent* _mouseDownEvent;
    void (^_timeoutBlock)(), (^_confirmBlock)();
    NSTimer* _timeoutTimer;
    NSPoint _mouseDownLocation, _currentLocation, _previousLocation;
    NIVector _mouseDownLocationVector, _currentLocationVector, _previousLocationVector;
    NIAffineTransform _mouseDownGeneratorRequestSliceToDicomTransform;
}

@property(readonly, retain) NSEvent* mouseDownEvent;
@property(readonly, retain) NSTimer* timeoutTimer;

@property(readonly) NSPoint mouseDownLocation, currentLocation, previousLocation;
@property(readonly) NIVector mouseDownLocationVector, currentLocationVector, previousLocationVector;
@property(readonly, retain) NSView* mouseDownView;
@property(readonly) NIAffineTransform mouseDownGeneratorRequestSliceToDicomTransform;

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event UNAVAILABLE_ATTRIBUTE;
- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise confirm:(void(^)())confirm NS_REQUIRES_SUPER;
- (BOOL)view:(NIMPRView*)view mouseDragged:(NSEvent*)event NS_REQUIRES_SUPER;
- (BOOL)view:(NIMPRView*)view mouseUp:(NSEvent*)event NS_REQUIRES_SUPER;

- (void)drawInView:(NIMPRView*)view; // will only be called when current l or r tool

- (NSTimeInterval)timeout;

+ (void)setCursor:(NSCursor*)cursor;

@end

@interface NIMPRDeltaTool : NIMPRTool {
//    NSPoint _ignoreDragLocation;
    BOOL _mouseDownConfirmed;
}

- (BOOL)view:(NIMPRView*)view move:(NSPoint)delta vector:(NIVector)deltaVector;

- (BOOL)repositionsCursor;

@end
