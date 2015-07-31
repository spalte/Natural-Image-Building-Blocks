//
//  NIRectangleAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/13/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIRectangleAnnotation.h"
#import "NIAnnotationHandle.h"

@implementation NIRectangleAnnotation

@synthesize bounds = _bounds;

+ (NSSet*)keyPathsForValuesAffectingNSBezierPath {
    return [NSSet setWithObject:@"bounds"];
}

- (instancetype)initWithBounds:(NSRect)bounds transform:(NIAffineTransform)sliceToDicomTransform {
    if ((self = [super initWithTransform:sliceToDicomTransform])) {
        self.bounds = bounds;
    }
    
    return self;
}

- (NSBezierPath*)NSBezierPath {
    return [NSBezierPath bezierPathWithRect:self.bounds];
}

- (NSSet*)handlesInView:(NIAnnotatedGeneratorRequestView*)view {
    NIAffineTransform planeToSliceTransform = NIAffineTransformConcat(self.modelToDicomTransform, NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform));
    NSRect b = self.bounds;
    return [NSSet setWithObjects:
            [NITransformAnnotationBlockHandle handleAtSliceVector:NIVectorApplyTransform(NIVectorMakeFromNSPoint(b.origin), planeToSliceTransform) annotation:self
                                                        block:^(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector pd) {
                                                            NSRect b = self.bounds;
                                                            b.origin.x += pd.x;
                                                            b.size.width -= pd.x;
                                                            b.origin.y += pd.y;
                                                            b.size.height -= pd.y;
                                                            self.bounds = b;
                                                        }],
            [NITransformAnnotationBlockHandle handleAtSliceVector:NIVectorApplyTransform(NIVectorMake(b.origin.x+b.size.width, b.origin.y, 0), planeToSliceTransform) annotation:self
                                                        block:^(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector pd) {
                                                            NSRect b = self.bounds;
                                                            b.size.width += pd.x;
                                                            b.origin.y += pd.y;
                                                            b.size.height -= pd.y;
                                                            self.bounds = b;
                                                        }],
            [NITransformAnnotationBlockHandle handleAtSliceVector:NIVectorApplyTransform(NIVectorMake(b.origin.x+b.size.width, b.origin.y+b.size.height, 0), planeToSliceTransform) annotation:self
                                                        block:^(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector pd) {
                                                            NSRect b = self.bounds;
                                                            b.size.width += pd.x;
                                                            b.size.height += pd.y;
                                                            self.bounds = b;
                                                        }],
            [NITransformAnnotationBlockHandle handleAtSliceVector:NIVectorApplyTransform(NIVectorMake(b.origin.x, b.origin.y+b.size.height, 0), planeToSliceTransform) annotation:self
                                                        block:^(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector pd) {
                                                            NSRect b = self.bounds;
                                                            b.origin.x += pd.x;
                                                            b.size.width -= pd.x;
                                                            b.size.height += pd.y;
                                                            self.bounds = b;
                                                        }], nil];
}

@end
