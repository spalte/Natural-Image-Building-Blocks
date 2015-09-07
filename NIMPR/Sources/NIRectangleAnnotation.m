//
//  NIRectangleAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/13/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIRectangleAnnotation.h"
#import "NIAnnotationHandle.h"

static NSString* const NIRectangleAnnotationBounds = @"bounds";

@implementation NIRectangleAnnotation

@synthesize bounds = _bounds;

+ (NSSet*)keyPathsForValuesAffectingNSBezierPath {
    return [[super keyPathsForValuesAffectingNSBezierPath] setByAddingObject:@"bounds"];
}

+ (id)rectangleWithBounds:(NSRect)bounds transform:(NIAffineTransform)modelToDicomTransform {
    return [[[self.class alloc] initWithBounds:bounds transform:modelToDicomTransform] autorelease];
}

- (instancetype)init {
    if ((self = [super init])) {
    }
    
    return self;
}

- (instancetype)initWithBounds:(NSRect)bounds transform:(NIAffineTransform)modelToDicomTransform {
    if ((self = [self init])) {
        self.modelToDicomTransform = modelToDicomTransform;
        self.bounds = bounds;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    if ((self = [super initWithCoder:coder])) {
        self.bounds = [[[coder decodeObjectForKey:NIRectangleAnnotationBounds] requireValueWithObjCType:@encode(NSRect)] rectValue];
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
    NIAffineTransform modelToSliceTransform = NIAffineTransformConcat(self.modelToDicomTransform, NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform));
    NSRect b = self.bounds;
    return [NSSet setWithObjects:
            [NITransformAnnotationBlockHandle handleAtSliceVector:NIVectorApplyTransform(NIVectorMakeFromNSPoint(b.origin), modelToSliceTransform) annotation:self
                                                        block:^(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector pd) {
                                                            NSRect b = self.bounds;
                                                            b.origin.x += pd.x;
                                                            b.size.width -= pd.x;
                                                            b.origin.y += pd.y;
                                                            b.size.height -= pd.y;
                                                            self.bounds = b;
                                                        }],
            [NITransformAnnotationBlockHandle handleAtSliceVector:NIVectorApplyTransform(NIVectorMake(b.origin.x+b.size.width, b.origin.y, 0), modelToSliceTransform) annotation:self
                                                        block:^(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector pd) {
                                                            NSRect b = self.bounds;
                                                            b.size.width += pd.x;
                                                            b.origin.y += pd.y;
                                                            b.size.height -= pd.y;
                                                            self.bounds = b;
                                                        }],
            [NITransformAnnotationBlockHandle handleAtSliceVector:NIVectorApplyTransform(NIVectorMake(b.origin.x+b.size.width, b.origin.y+b.size.height, 0), modelToSliceTransform) annotation:self
                                                        block:^(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector pd) {
                                                            NSRect b = self.bounds;
                                                            b.size.width += pd.x;
                                                            b.size.height += pd.y;
                                                            self.bounds = b;
                                                        }],
            [NITransformAnnotationBlockHandle handleAtSliceVector:NIVectorApplyTransform(NIVectorMake(b.origin.x, b.origin.y+b.size.height, 0), modelToSliceTransform) annotation:self
                                                        block:^(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector pd) {
                                                            NSRect b = self.bounds;
                                                            b.origin.x += pd.x;
                                                            b.size.width -= pd.x;
                                                            b.size.height += pd.y;
                                                            self.bounds = b;
                                                        }], nil];
}

@end
