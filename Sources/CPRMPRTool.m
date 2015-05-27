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

@property(readwrite) NSPoint mouseDownLocation;
@property(readwrite) N3Vector mouseDownLocationVector;
@property(readwrite) N3AffineTransform mouseDownGeneratorRequestSliceToDicomTransform;

@end

@implementation CPRMPRTool

@synthesize mouseDownLocation = _mouseDownLocation;
@synthesize mouseDownLocationVector = _mouseDownLocationVector;
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

- (BOOL)view:(CPRMPRView*)view mouseDown:(NSEvent*)event {
    self.mouseDownLocation = [view convertPoint:event.locationInWindow fromView:nil];
    
    self.mouseDownLocationVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint(self.mouseDownLocation), view.generatorRequest.sliceToDicomTransform);
    self.mouseDownGeneratorRequestSliceToDicomTransform = view.generatorRequest.sliceToDicomTransform;
    
    return YES;
}

- (NSCursor*)hoverCursor {
    return NSCursor.arrowCursor;
}

@end
