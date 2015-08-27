//
//  NIMPRAnnotateLineTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/10/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateSegmentTool.h"
#import "NISegmentAnnotation.h"

@implementation NIMPRAnnotateSegmentTool

@dynamic annotation;

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^{
        [view.mutableAnnotations addObject:(self.annotation = [NISegmentAnnotation segmentWithPoints:self.mouseDownLocationVector:self.mouseDownLocationVector])];
    }];
}

- (BOOL)view:(NIMPRView *)view mouseDragged:(NSEvent *)event {
    [super view:view mouseDragged:event];
    
    self.annotation.q = self.currentLocationVector;
    
    return YES;
}

@end
