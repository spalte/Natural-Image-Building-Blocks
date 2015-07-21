//
//  NIMPRTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRTool+Private.h"
#import "NIMPRView.h"
#import <NIBuildingBlocks/NIIntersection.h>
#import <NIBuildingBlocks/NIGeneratorRequest.h>

static BOOL NIMPRToolHidingCursor = NO;

@implementation NIMPRTool

@synthesize mouseDownView = _mouseDownView, mouseDownEvent = _mouseDownEvent;
@synthesize timeoutBlock = _timeoutBlock, confirmBlock = _confirmBlock;
@synthesize timeoutTimer = _timeoutTimer;

@synthesize mouseDownLocation = _mouseDownLocation, currentLocation = _currentLocation, previousLocation = _previousLocation;
@synthesize mouseDownLocationVector = _mouseDownLocationVector, currentLocationVector = _currentLocationVector, previousLocationVector = _previousLocationVector;
@synthesize mouseDownGeneratorRequestSliceToDicomTransform = _mouseDownGeneratorRequestSliceToDicomTransform;

- (void)dealloc {
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
    self.timeoutBlock = self.confirmBlock = nil;
    self.mouseDownEvent = nil;
    self.mouseDownView = nil;
    [super dealloc];
}

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event {
    [NSException raise:NSGenericException format:@"NIMPRTool view:mouseDown: is forbidden, overload view:mouseDown:otherwise: in %@ instead", self.className];
    return NO;
}

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise {
    return [self view:view mouseDown:event otherwise:otherwise confirm:nil];
}

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise confirm:(void(^)())confirm {
    self.mouseDownView = view;
    self.mouseDownEvent = event;

    self.mouseDownLocation = [view convertPoint:event.locationInWindow fromView:nil];
    self.mouseDownGeneratorRequestSliceToDicomTransform = view.generatorRequest.sliceToDicomTransform;
    self.mouseDownLocationVector = NIVectorApplyTransform(NIVectorMakeFromNSPoint(self.mouseDownLocation), self.mouseDownGeneratorRequestSliceToDicomTransform);
    
    self.previousLocation = self.currentLocation = self.mouseDownLocation;
    self.previousLocationVector = self.currentLocationVector = self.mouseDownLocationVector;

    if (otherwise) {
        self.timeoutBlock = otherwise;
        self.confirmBlock = confirm;
        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeout target:self selector:@selector(timeout:) userInfo:NIMPRTool.class repeats:NO];
    } else if (confirm)
        confirm();
    
    self.class.cursor = [self cursorsForView:view][1];
    
    return YES;
}

- (BOOL)view:(NIMPRView*)view mouseDragged:(NSEvent*)event {
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
    self.currentLocationVector = NIVectorApplyTransform(NIVectorMakeFromNSPoint(self.currentLocation), self.mouseDownGeneratorRequestSliceToDicomTransform);
    
    return r;
}

- (BOOL)view:(NIMPRView*)view mouseUp:(NSEvent*)event {
    BOOL r = NO;

    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
        if ((r = (self.timeoutBlock != nil)))
            self.timeoutBlock();
        self.confirmBlock = self.timeoutBlock = nil;
    }
    
    self.mouseDownView = nil;
    self.mouseDownEvent = nil;
    
    return r;
}

- (void)drawInView:(NIMPRView*)view {
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

- (NSArray*)cursorsForView:(NIMPRView*)view {
    return @[ NSCursor.arrowCursor, NSCursor.arrowCursor ];
}

+ (void)setCursor:(NSCursor*)cursor {
    if ([cursor isKindOfClass:NSNull.class]) {
        if (!NIMPRToolHidingCursor) {
            [NSCursor hide];
            NIMPRToolHidingCursor = YES;
        }
    } else {
        if (!cursor)
            cursor = NSCursor.arrowCursor;
        if (![cursor isEqual:[NSCursor currentCursor]])
            [cursor set];
        if (NIMPRToolHidingCursor) {
            [NSCursor unhide];
            NIMPRToolHidingCursor = NO;
        }
    }
}

@end

@implementation NSScreen (NIMPR)

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

@interface NIMPRDeltaTool ()

//@property NSPoint ignoreDragLocation;
@property BOOL mouseDownConfirmed;

@end

@implementation NIMPRDeltaTool

//@synthesize ignoreDragLocation = _ignoreDragLocation;
@synthesize mouseDownConfirmed = _mouseDownConfirmed;

- (BOOL)view:(NIMPRView *)view mouseDown:(NSEvent *)event otherwise:(void (^)())or confirm:(void (^)())confirm {
    self.mouseDownConfirmed = NO;
    return [super view:view mouseDown:event otherwise:or confirm:^{
        self.mouseDownConfirmed = YES;
        [view enumerateIntersectionsWithBlock:^(NSString* key, NIIntersection* intersection, BOOL* stop) {
            intersection.maskAroundMouse = NO;
        }];
        if (confirm)
            confirm();
    }];
}

- (BOOL)view:(NIMPRView*)view mouseDragged:(NSEvent*)event {
    [super view:view mouseDragged:event];
    BOOL r = [self view:view move:NSMakePoint(self.currentLocation.x-self.previousLocation.x, self.currentLocation.y-self.previousLocation.y) vector:NIVectorSubtract(self.currentLocationVector, self.previousLocationVector)];
    return r;
}

- (BOOL)view:(NIMPRView*)view mouseUp:(NSEvent*)event {
    [super view:view mouseUp:event];
    if (self.mouseDownConfirmed && self.repositionsCursor)
        [self moveCursorToMouseDownLocation];
    return NO;
}

- (BOOL)view:(NIMPRView*)view move:(NSPoint)delta vector:(NIVector)deltaVector {
    return NO;
}

- (BOOL)repositionsCursor {
    return YES;
}

//- (void)moveCursorToCenter {
//    NSScreen* screen = [NSScreen screenWithPoint:[self.mouseDownView.window convertBaseToScreen:self.mouseDownEvent.locationInWindow]];
//    [self moveCursorToScreen:screen location:NSMakePoint(NSMidX(screen.frame), NSMidY(screen.frame))];
//}

- (void)moveCursorToMouseDownLocation {
    NSPoint mouseDownLocation = [self.mouseDownView.window convertPointToScreen:self.mouseDownEvent.locationInWindow];
    NSScreen* screen = [NSScreen screenWithPoint:mouseDownLocation];
    [self moveCursorToScreen:screen location:mouseDownLocation];
}

- (void)moveCursorToScreen:(NSScreen*)screen location:(NSPoint)p {
    self.currentLocation = [self.mouseDownView convertPoint:[self.mouseDownView.window convertPointFromScreen:p] fromView:nil];
    self.currentLocationVector = NIVectorApplyTransform(NIVectorMakeFromNSPoint(self.currentLocation), self.mouseDownGeneratorRequestSliceToDicomTransform);
    
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
