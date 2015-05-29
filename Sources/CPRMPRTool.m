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

@interface CPRMPRTool ()

@property NSView* mouseDownView;
@property(retain, readwrite) NSEvent* mouseDownEvent;
@property(copy) void (^timeoutBlock)(), (^confirmBlock)();
@property(retain, readwrite) NSTimer* timeoutTimer;
@property(readwrite) NSPoint mouseDownLocation, currentLocation;
@property(readwrite) N3Vector mouseDownLocationVector, currentLocationVector;
@property(readwrite) N3AffineTransform mouseDownGeneratorRequestSliceToDicomTransform;

@end

@implementation CPRMPRTool

@synthesize mouseDownView = _mouseDownView, mouseDownEvent = _mouseDownEvent;
@synthesize timeoutBlock = _timeoutBlock, confirmBlock = _confirmBlock;
@synthesize timeoutTimer = _timeoutTimer;

@synthesize mouseDownLocation = _mouseDownLocation, currentLocation = _currentLocation;
@synthesize mouseDownLocationVector = _mouseDownLocationVector, currentLocationVector = _currentLocationVector;
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
    [NSException raise:NSGenericException format:@"CPRMPRTool view:mouseDown: is forbidden, overload view:mouseDown:or: instead"];
    return NO;
}

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event or:(void(^)())or confirm:(void(^)())confirm {
    self.mouseDownView = view;
    self.mouseDownEvent = event;

    self.mouseDownLocation = [view convertPoint:event.locationInWindow fromView:nil];
    self.mouseDownGeneratorRequestSliceToDicomTransform = view.generatorRequest.sliceToDicomTransform;
    self.mouseDownLocationVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint(self.mouseDownLocation), self.mouseDownGeneratorRequestSliceToDicomTransform);
    
    if (or) {
        self.timeoutBlock = or;
        self.confirmBlock = confirm;
        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeout target:self selector:@selector(timeout:) userInfo:CPRMPRTool.class repeats:NO];
        [self.cursor set];
    } else if (confirm)
        confirm();
    
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

- (NSCursor*)cursor {
    return NSCursor.arrowCursor;
}

- (void)moveCursorToMouseDownLocation {
    NSPoint p = [self.mouseDownView.window convertBaseToScreen:self.mouseDownEvent.locationInWindow];
    CGPoint cgp = CGPointMake(p.x, p.y);
    uint32_t dc = 1;
    CGDirectDisplayID dids[dc];
    CGGetDisplaysWithPoint (cgp, 1, dids, &dc);
    if (dc >= 1) {
        CGRect db = CGDisplayBounds(dids[0]);
        cgp.x -= db.origin.x; cgp.y -= db.origin.y;
        cgp.y = db.size.height-cgp.y;
        CGDisplayMoveCursorToPoint(dids[0], cgp);
    }
}

@end
