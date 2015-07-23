//
//  NILineAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/10/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NISegmentAnnotation.h"

@implementation NISegmentAnnotation

@synthesize p = _p, q = _q;

+ (NSSet*)keyPathsForValuesAffectingNSBezierPath {
    return [NSSet setWithObjects: @"p", @"q", nil];
}

- (instancetype)initWithPoints:(NSPoint)p :(NSPoint)q transform:(NIAffineTransform)sliceToDicomTransform {
    if ((self = [super initWithTransform:sliceToDicomTransform])) {
        self.p = p;
        self.q = q;
    }
    
    return self;
}

- (NSBezierPath*)NSBezierPath {
    NSBezierPath* path = [NSBezierPath bezierPath];
    
    [path moveToPoint:self.p];
    [path lineToPoint:self.q];
    
    return path;
}

- (NSSet*)handlesInView:(NIAnnotatedGeneratorRequestView*)view {
    NIAffineTransform planeToSliceTransform = NIAffineTransformConcat(self.planeToDicomTransform, NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform));
    return [NSSet setWithObjects:
            [NIHandlerPlaneAnnotationHandle handleAtSliceVector:NIVectorApplyTransform(NIVectorMakeFromNSPoint(self.p), planeToSliceTransform) annotation:self
                                                        handler:^(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector d) {
                                                            self.p = NSMakePoint(self.p.x+d.x, self.p.y+d.y);
                                                        }],
            [NIHandlerPlaneAnnotationHandle handleAtSliceVector:NIVectorApplyTransform(NIVectorMakeFromNSPoint(self.q), planeToSliceTransform) annotation:self
                                                        handler:^(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector d) {
                                                            self.q = NSMakePoint(self.q.x+d.x, self.q.y+d.y);
                                                        }], nil];
}

@end
