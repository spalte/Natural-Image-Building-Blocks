//
//  NIMPRAnnotateLineTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/10/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateLineTool.h"
#import "NILineAnnotation.h"
#import "NIMPRView.h"

@implementation NIMPRAnnotateLineTool

@dynamic annotation;

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^{
        NIObliqueSliceGeneratorRequest* req = (id)view.presentedGeneratorRequest;
        [view.publicAnnotations addObject:(self.annotation = [NILineAnnotation annotationWithPoints:self.mouseDownLocation :self.mouseDownLocation transform:req.sliceToDicomTransform])];
    }];
}

- (BOOL)view:(NIMPRView *)view mouseDragged:(NSEvent *)event {
    [super view:view mouseDragged:event];
    self.annotation.q = self.currentLocation;
    return YES;
}

@end
