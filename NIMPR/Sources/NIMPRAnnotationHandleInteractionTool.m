//
//  NIMPRAnnotationHandleInteractionTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotationHandleInteractionTool.h"
#import "NIMPRView.h"
#import "NIAnnotationHandle.h"

@interface NIMPRAnnotationHandleInteractionTool ()

@property(retain) NIAnnotationHandle* handle;

@end

@implementation NIMPRAnnotationHandleInteractionTool

@synthesize handle = _handle;

- (void)dealloc {
    self.handle = nil;
    [super dealloc];
}

- (BOOL)view:(NIMPRView *)view mouseDown:(NSEvent *)event otherwise:(void (^)())otherwise confirm:(void (^)())confirm {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^(){
        self.handle = [view handleForSlicePoint:[view convertPoint:event.locationInWindow fromView:nil]];
    }];
}

- (BOOL)view:(NIMPRView*)view mouseDragged:(NSEvent*)event {
    [super view:view mouseDragged:event];
    
    [self.handle translateFromSlicePoint:self.previousLocation toSlicePoint:self.currentLocation view:view];
    
    return YES;
}


- (NSArray*)cursorsForView:(NIMPRView*)view {
    return @[ NSCursor.pointingHandCursor, NSCursor.closedHandCursor ];
}

@end
