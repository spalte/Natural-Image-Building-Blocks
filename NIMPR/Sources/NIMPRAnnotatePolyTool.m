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

@interface NIMPRAnnotatePolyTool ()

@property BOOL closedPreview;

@end

@implementation NIMPRAnnotatePolyTool

@dynamic annotation;
@synthesize closedPreview = _closedPreview;

- (BOOL)view:(NIMPRView *)view mouseMoved:(NSEvent *)event {
    self.currentLocation = [view convertPoint:[view.window convertPointFromScreen:[NSEvent mouseLocation]] fromView:nil];
    self.currentLocationVector = NIVectorApplyTransform(NIVectorMakeFromNSPoint(self.currentLocation), view.presentedGeneratorRequest.sliceToDicomTransform);
    
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
    self.closedPreview = NO;
    
    [self view:view mouseMoved:event];
    
    if (self.annotation) {
        NSBezierPath* h;
        if (event.type == NSLeftMouseDown) {
            h = [view.class NSBezierPathForHandle:[view handleForSlicePoint:NSPointFromNIVector(NIVectorApplyTransform([self.annotation.vectors.lastObject NIVectorValue], NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform)))]];
            if ([h containsPoint:[event locationInView:view]])
                self.annotation = nil;
            h = [view.class NSBezierPathForHandle:[view handleForSlicePoint:NSPointFromNIVector(NIVectorApplyTransform([self.annotation.vectors[0] NIVectorValue], NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform)))]];
            if ([h containsPoint:[event locationInView:view]]) {
                self.annotation.closed = YES;
                self.annotation = nil;
            }
        } else if (event.type == NSMouseMoved) {
            h = [view.class NSBezierPathForHandle:[view handleForSlicePoint:NSPointFromNIVector(NIVectorApplyTransform([self.annotation.vectors[0] NIVectorValue], NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform)))]];
            if ([h containsPoint:[event locationInView:view]]) {
                self.closedPreview = YES;
            }
        }
    }
    
    [view.toolsLayer setNeedsDisplay];
}

- (void)drawInView:(NIMPRView *)view {
    NSBezierPath* hl = [view.class NSBezierPathForHandle:[view handleForSlicePoint:NSPointFromNIVector(NIVectorApplyTransform([self.annotation.vectors.lastObject NIVectorValue], NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform)))]];
    
    if (self.annotation.vectors.count > 0 && !self.mouseDownEvent && !NSEqualPoints(self.currentLocation, NSMakePoint(CGFLOAT_MAX, CGFLOAT_MAX))) {
        NIPolyAnnotation* stroke = [[[NIPolyAnnotation alloc] init] autorelease];
        [stroke.mutableVectors addObjectsFromArray:self.annotation.vectors];
        
        if (!self.closedPreview && ![hl containsPoint:self.currentLocation])
            [stroke.mutableVectors addObject:[NSValue valueWithNIVector:self.currentLocationVector]];
        if (self.annotation.smooth)
            stroke.smooth = YES;
        if (self.annotation.closed || self.closedPreview)
            stroke.closed = self.closedPreview;
        
        stroke.color = [self.annotation.color colorWithAlphaComponent:self.annotation.color.alphaComponent/2];
        [stroke drawInView:view cache:nil];
    }
}

@end
