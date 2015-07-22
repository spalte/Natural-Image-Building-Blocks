//
//  NIMPRAnnotatePolyTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotatePolyTool.h"
#import "NIMPRAnnotationSelectionTool.h"
#import "NIMPRTool+Private.h"
#import "NIPolyAnnotation.h"

@implementation NIMPRAnnotatePolyTool

@dynamic annotation;

- (BOOL)view:(NIMPRView *)view mouseMoved:(NSEvent *)event {
    self.currentLocation = [view convertPoint:[view.window convertPointFromScreen:[NSEvent mouseLocation]] fromView:nil];
    
//    [self view:view flagsChanged:event];

    return NO;
}

- (BOOL)view:(NIMPRView *)view mouseExited:(NSEvent *)event {
    self.currentLocation = NSMakePoint(CGFLOAT_MAX, CGFLOAT_MAX);
    
//    [self view:view flagsChanged:event];
    
    return NO;
}

- (BOOL)view:(NIMPRView *)view flagsChanged:(NSEvent *)event {
    if (self.annotation) {
        [view.toolsLayer setNeedsDisplay];
    }
    
    return NO;
}

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^{
        [self view:view flagsChanged:event];
        
        if (event.clickCount > 1 || (self.annotation.vectors.count > 0 && NIVectorEqualToVector(self.mouseDownLocationVector, [self.annotation.vectors.lastObject NIVectorValue]))) {
            self.annotation = nil;
            return;
        }
        
        if (!self.annotation)
            [view.mutableAnnotations addObject:(self.annotation = [[[NIPolyAnnotation alloc] init] autorelease])];
        
        [self.annotation.mutableVectors addObject:[NSValue valueWithNIVector:self.mouseDownLocationVector]];
    }];
}

- (BOOL)view:(NIMPRView *)view mouseDragged:(NSEvent *)event {
    [super view:view mouseDragged:event];
    
    [self.annotation.mutableVectors replaceObjectAtIndex:self.annotation.vectors.count-1 withObject:[NSValue valueWithNIVector:self.currentLocationVector]];
    
    return YES;
}

- (void)view:(NIMPRView*)view handled:(NSEvent*)event {
    if (self.annotation)
        if (event.type == NSLeftMouseDown && NSEqualPoints([event locationInView:view], self.currentLocation)) {
            self.annotation = nil;
        }
    [view.toolsLayer setNeedsDisplay];
}

- (void)drawInView:(NIMPRView *)view {
    if (self.annotation.vectors.count > 0 && !NSEqualPoints(self.currentLocation, NSMakePoint(CGFLOAT_MAX, CGFLOAT_MAX))) {
        [[self.annotation.color colorWithAlphaComponent:self.annotation.color.alphaComponent/2] setStroke];
        [NSBezierPath strokeLineFromPoint:self.currentLocation toPoint:NSPointFromNIVector(NIVectorApplyTransform([self.annotation.vectors.lastObject NIVectorValue], NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform)))];
    }
}

@end
