//
//  NIRectangleAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/13/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIRectangleAnnotation.h"
#import "NIAnnotationHandle.h"
#import "NIJSON.h"

static NSString* const NIRectangleAnnotationBounds = @"bounds";

@implementation NIRectangleAnnotation

+ (void)load {
    [NIJSON setName:@"rectangle" forClass:NIRectangleAnnotation.class];
}

@synthesize bounds = _bounds;

+ (NSSet*)keyPathsForValuesAffectingNSBezierPath {
    return [NSSet setWithObject:@"bounds"];
}

+ (id)rectangleWithBounds:(NSRect)bounds transform:(NIAffineTransform)sliceToDicomTransform {
    return [[[self.class alloc] initWithBounds:bounds transform:sliceToDicomTransform] autorelease];
}

- (instancetype)initWithBounds:(NSRect)bounds transform:(NIAffineTransform)sliceToDicomTransform {
    if ((self = [super initWithTransform:sliceToDicomTransform])) {
        self.bounds = bounds;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:[NSValue valueWithRect:self.bounds] forKey:NIRectangleAnnotationBounds];
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
