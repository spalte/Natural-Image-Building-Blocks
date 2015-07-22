//
//  NIMPRAnnotateRectangleTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/13/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateRectangleTool.h"
#import "NIRectangleAnnotation.h"

@implementation NIMPRAnnotateRectangleTool

@dynamic annotation;

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^{
        NIObliqueSliceGeneratorRequest* req = view.presentedGeneratorRequest;
        [view.mutableAnnotations addObject:(self.annotation = [NIAnnotation rectangleWithBounds:NSMakeRect(self.mouseDownLocation.x, self.mouseDownLocation.y, 0, 0) transform:req.sliceToDicomTransform])];
    }];
}

- (BOOL)view:(NIMPRView *)view flagsChanged:(NSEvent *)event {
    [self view:view mouseDragged:event];
    return NO;
}

- (BOOL)view:(NIMPRView *)view mouseDragged:(NSEvent *)event {
    [super view:view mouseDragged:event];
    
    NSRect bounds = self.annotation.bounds;
    bounds.size = NSMakeSize(self.currentLocation.x-self.mouseDownLocation.x, self.currentLocation.y-self.mouseDownLocation.y);
    if (event.modifierFlags&NSShiftKeyMask) {
        CGFloat m = CGFloatMax(CGFloatAbs(bounds.size.width), CGFloatAbs(bounds.size.height));
        bounds.size = NSMakeSize(m*CGFloatSign(bounds.size.width), m*CGFloatSign(bounds.size.height));
    }
    
    self.annotation.bounds = bounds;
    
    return YES;
}

@end
