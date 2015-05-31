//
//  CPRMPRTool.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRTool.h"
#import "CPRMPRView.h"
#import <OsiriXAPI/CPRGeneratorRequest.h>
#import "CPRMPRWLWWTool.h"
#import "CPRMPRMoveTool.h"
#import "CPRMPRZoomTool.h"
#import "CPRMPRRotateTool.h"
#import "CPRMPRRotateAxisTool.h"
#import "CPRIntersection.h"

static BOOL CPRMPRToolHidingCursor = NO;

@interface CPRMPRTool ()

@property NSView* mouseDownView;
@property(retain, readwrite) NSEvent* mouseDownEvent;
@property(copy) void (^timeoutBlock)(), (^confirmBlock)();
@property(retain, readwrite) NSTimer* timeoutTimer;
@property(readwrite) NSPoint mouseDownLocation, currentLocation, previousLocation;
@property(readwrite) N3Vector mouseDownLocationVector, currentLocationVector, previousLocationVector;
@property(readwrite) N3AffineTransform mouseDownGeneratorRequestSliceToDicomTransform;

@end

@implementation CPRMPRTool

@synthesize mouseDownView = _mouseDownView, mouseDownEvent = _mouseDownEvent;
@synthesize timeoutBlock = _timeoutBlock, confirmBlock = _confirmBlock;
@synthesize timeoutTimer = _timeoutTimer;

@synthesize mouseDownLocation = _mouseDownLocation, currentLocation = _currentLocation, previousLocation = _previousLocation;
@synthesize mouseDownLocationVector = _mouseDownLocationVector, currentLocationVector = _currentLocationVector, previousLocationVector = _previousLocationVector;
@synthesize mouseDownGeneratorRequestSliceToDicomTransform = _mouseDownGeneratorRequestSliceToDicomTransform;

+ (instancetype)toolForTag:(CPRMPRToolTag)tag {
    Class tc = nil;
    
    switch (tag) {
        case CPRMPRToolWLWW: {
            tc = CPRMPRWLWWTool.class;
        } break;
        case CPRMPRToolMove: {
            tc = CPRMPRMoveTool.class;
        } break;
        case CPRMPRToolZoom: {
            tc = CPRMPRZoomTool.class;
        } break;
        case CPRMPRToolRotate: {
            tc = CPRMPRRotateTool.class;
        } break;
        case CPRMPRToolRotateAxis: {
            tc = CPRMPRRotateAxisTool.class;
        } break;
    }
    
    return [[[tc alloc] init] autorelease];
}

- (void)dealloc {
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
    self.timeoutBlock = self.confirmBlock = nil;
    self.mouseDownEvent = nil;
    self.mouseDownView = nil;
    [super dealloc];
}

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event {
    [NSException raise:NSGenericException format:@"CPRMPRTool view:mouseDown: is forbidden, overload view:mouseDown:or: in %@ instead", self.className];
    return NO;
}

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event or:(void(^)())or {
    return [self view:view mouseDown:event or:or confirm:nil];
}

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event or:(void(^)())or confirm:(void(^)())confirm {
    self.mouseDownView = view;
    self.mouseDownEvent = event;

    self.mouseDownLocation = [view convertPoint:event.locationInWindow fromView:nil];
    self.mouseDownGeneratorRequestSliceToDicomTransform = view.generatorRequest.sliceToDicomTransform;
    self.mouseDownLocationVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint(self.mouseDownLocation), self.mouseDownGeneratorRequestSliceToDicomTransform);
    
    self.previousLocation = self.currentLocation = self.mouseDownLocation;
    self.previousLocationVector = self.currentLocationVector = self.mouseDownLocationVector;

    if (or) {
        self.timeoutBlock = or;
        self.confirmBlock = confirm;
        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeout target:self selector:@selector(timeout:) userInfo:CPRMPRTool.class repeats:NO];
    } else if (confirm)
        confirm();
    
    self.class.cursor = self.cursors[1];
    
    return YES;
}

- (BOOL)view:(CPRMPRView*)view mouseDragged:(NSEvent*)event {
    BOOL r = NO;
    
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
        if ((r = (self.confirmBlock != nil)))
            self.confirmBlock();
        self.confirmBlock = self.timeoutBlock = nil;
    }

    self.previousLocation = self.currentLocation;
    self.previousLocationVector = self.currentLocationVector;
    self.currentLocation = [view convertPoint:event.locationInWindow fromView:nil];
    self.currentLocationVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint(self.currentLocation), self.mouseDownGeneratorRequestSliceToDicomTransform);
    
    return r;
}

- (BOOL)view:(CPRMPRView*)view mouseUp:(NSEvent*)event {
    BOOL r = NO;

    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
        if ((r = (self.timeoutBlock != nil)))
            self.timeoutBlock();
        self.confirmBlock = self.timeoutBlock = nil;
    }
    
    return r;
}

- (NSTimeInterval)timeout {
    return 0.25;
}

- (void)timeout:(NSTimer*)timer {
    [NSCursor.arrowCursor set];
    self.timeoutTimer = nil;
    self.timeoutBlock();
    self.timeoutBlock = self.confirmBlock = nil;
}

- (NSArray*)cursors {
    return @[ NSCursor.arrowCursor, NSCursor.arrowCursor ];
}

- (void)setHoverCursor {
    [self.class setCursor:self.cursors[0]];
}

+ (void)setCursor:(NSCursor*)cursor {
    if ([cursor isKindOfClass:NSNull.class]) {
        if (!CPRMPRToolHidingCursor) {
            [NSCursor hide];
            CPRMPRToolHidingCursor = YES;
        }
    } else {
        if (!cursor)
            cursor = NSCursor.arrowCursor;
        if (![cursor isEqual:[NSCursor currentCursor]])
            [cursor set];
        if (CPRMPRToolHidingCursor) {
            [NSCursor unhide];
            CPRMPRToolHidingCursor = NO;
        }
    }
}

@end

@implementation NSScreen (CPRMPR)

+ (NSScreen*)screenWithPoint:(NSPoint)p {
    for (NSScreen* screen in self.screens)
        if (NSPointInRect(p, screen.frame))
            return screen;
    return nil;
}

+ (NSScreen*)screenWithMenuBar {
    return [self screenWithPoint:NSZeroPoint];
}

+ (float)menuScreenHeight {
    return NSMaxY([[self screenWithMenuBar] frame]);
}

+ (CGPoint)carbonPointFrom:(NSPoint)p {
    return CGPointMake(p.x, self.menuScreenHeight - p.y);
}

+ (NSPoint)cocoaPointFrom:(CGPoint)p {
    return NSMakePoint(p.x, self.menuScreenHeight - p.y);
}

@end

//@interface CPRMPRDeltaTool ()
//
////@property NSPoint ignoreDragLocation;
//
//@end

@implementation CPRMPRDeltaTool

//@synthesize ignoreDragLocation = _ignoreDragLocation;

- (BOOL)view:(CPRMPRView *)view mouseDown:(NSEvent *)event or:(void (^)())or confirm:(void (^)())confirm {
    return [super view:view mouseDown:event or:or confirm:^{
        [view enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
            intersection.maskAroundMouse = NO;
        }];
        if (confirm)
            confirm();
    }];
}

- (BOOL)view:(CPRMPRView*)view mouseDragged:(NSEvent*)event {
    [super view:view mouseDragged:event];
    BOOL r = [self view:view move:NSMakePoint(self.currentLocation.x-self.previousLocation.x, self.currentLocation.y-self.previousLocation.y) vector:N3VectorSubtract(self.currentLocationVector, self.previousLocationVector)];
    return r;
}

- (BOOL)view:(CPRMPRView*)view mouseUp:(NSEvent*)event {
    [super view:view mouseUp:event];
    [self moveCursorToMouseDownLocation];
    return NO;
}

- (BOOL)view:(CPRMPRView*)view move:(NSPoint)delta vector:(N3Vector)deltaVector {
    return NO;
}

//- (void)moveCursorToCenter {
//    NSScreen* screen = [NSScreen screenWithPoint:[self.mouseDownView.window convertBaseToScreen:self.mouseDownEvent.locationInWindow]];
//    [self moveCursorToScreen:screen location:NSMakePoint(NSMidX(screen.frame), NSMidY(screen.frame))];
//}

- (void)moveCursorToMouseDownLocation {
    NSPoint mouseDownLocation = [self.mouseDownView.window convertBaseToScreen:self.mouseDownEvent.locationInWindow];
    NSScreen* screen = [NSScreen screenWithPoint:mouseDownLocation];
    [self moveCursorToScreen:screen location:mouseDownLocation];
}

- (void)moveCursorToScreen:(NSScreen*)screen location:(NSPoint)p {
    self.currentLocation = [self.mouseDownView convertPoint:[self.mouseDownView.window convertScreenToBase:p] fromView:nil];
    self.currentLocationVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint(self.currentLocation), self.mouseDownGeneratorRequestSliceToDicomTransform);
    
    CGPoint cp = [NSScreen carbonPointFrom:p];
    
    uint32_t dc = 1;
    CGDirectDisplayID dids[dc];
    CGGetDisplaysWithPoint(cp, 1, dids, &dc);
    if (dc >= 1) {
        CGRect db = CGDisplayBounds(dids[0]);
        CGDisplayMoveCursorToPoint(dids[0], CGPointMake(cp.x-db.origin.x, cp.y-db.origin.y));
    }
}

@end
