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

@optional
- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view rightMouseDown:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view otherMouseDown:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view mouseUp:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view rightMouseUp:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view otherMouseUp:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view mouseMoved:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view mouseDragged:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view scrollWheel:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view rightMouseDragged:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view otherMouseDragged:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view mouseEntered:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view mouseExited:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view keyDown:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view keyUp:(NSEvent*)event;
- (BOOL)view:(CPRMPRView*)view flagsChanged:(NSEvent*)event;

@end

@interface CPRMPRTool : NSObject <CPRMPRTool> {
    NSPoint _mouseDownLocation;
    N3Vector _mouseDownLocationVector;
    N3AffineTransform _mouseDownGeneratorRequestSliceToDicomTransform;
}

@property(readonly) NSPoint mouseDownLocation;
@property(readonly) N3Vector mouseDownLocationVector;
@property(readonly) N3AffineTransform mouseDownGeneratorRequestSliceToDicomTransform;

+ (instancetype)toolForTag:(CPRMPRToolTag)tag;

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event NS_REQUIRES_SUPER;

- (NSCursor*)hoverCursor;

@end
