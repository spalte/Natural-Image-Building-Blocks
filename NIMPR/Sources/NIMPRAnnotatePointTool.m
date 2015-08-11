//
//  NIMPRAnnotatePointTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/8/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotatePointTool.h"
#import "NIPointAnnotation.h"

@implementation NIMPRAnnotatePointTool

@dynamic annotation;

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^{
        [view.mutableAnnotations addObject:(self.annotation = [NIPointAnnotation pointWithVector:self.mouseDownLocationVector])];
    }];
}

- (BOOL)view:(NIMPRView*)view mouseDragged:(NSEvent *)event {
    [super view:view mouseDragged:event];
    self.annotation.vector = self.currentLocationVector;
    return YES;
}

@end
