//
//  NIMPRAnnotateEllipseTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/10/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateEllipseTool.h"
#import "NIEllipseAnnotation.h"

@implementation NIMPRAnnotateEllipseTool

@dynamic annotation;

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^{
        NIObliqueSliceGeneratorRequest* req = (id)view.presentedGeneratorRequest;
        [view.publicAnnotations addObject:(self.annotation = [NIAnnotation ellipseWithBounds:NSMakeRect(self.mouseDownLocation.x, self.mouseDownLocation.y, 0, 0) transform:req.sliceToDicomTransform])];
    }];
}

- (BOOL)view:(NIMPRView *)view mouseDragged:(NSEvent *)event {
    [super view:view mouseDragged:event];
    NSRect bounds = self.annotation.bounds;
    bounds.size = NSMakeSize(self.currentLocation.x-self.mouseDownLocation.x, self.currentLocation.y-self.mouseDownLocation.y);
    self.annotation.bounds = bounds;
    return YES;
}

@end
