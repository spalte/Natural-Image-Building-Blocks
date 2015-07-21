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
        NIObliqueSliceGeneratorRequest* req = view.presentedGeneratorRequest;
        [view.mutableAnnotations addObject:(self.annotation = [NIAnnotation ellipseWithBounds:NSMakeRect(self.mouseDownLocation.x, self.mouseDownLocation.y, 0, 0) transform:req.sliceToDicomTransform])];
    }];
}

- (BOOL)view:(NIMPRView *)view mouseDragged:(NSEvent *)event {
    [super view:view mouseDragged:event];
    
    NSRect bounds = self.annotation.bounds;
    bounds.size = NSMakeSize(self.currentLocation.x-self.mouseDownLocation.x, self.currentLocation.y-self.mouseDownLocation.y);
    if (self.mouseDownEvent.modifierFlags&NSShiftKeyMask) {
        CGFloat m = CGFloatMax(CGFloatAbs(bounds.size.width), CGFloatAbs(bounds.size.height));
        bounds.size = NSMakeSize(m*CGFloatSign(bounds.size.width), m*CGFloatSign(bounds.size.height));
    }
    
    self.annotation.bounds = bounds;
    
    return YES;
}

@end
