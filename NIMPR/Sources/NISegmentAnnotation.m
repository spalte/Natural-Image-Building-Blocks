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

+ (id)segmentWithPoints:(NIVector)p :(NIVector)q {
    return [[[self.class alloc] initWithPoints:p:q] autorelease];
}

+ (id)segmentWithPoints:(NSPoint)p :(NSPoint)q transform:(NIAffineTransform)planeToDicomTransform {
    NIVector pv = NIVectorApplyTransform(NIVectorMakeFromNSPoint(p), planeToDicomTransform), qv = NIVectorApplyTransform(NIVectorMakeFromNSPoint(q), planeToDicomTransform);
    return [self segmentWithPoints:pv:qv];
}

- (instancetype)initWithPoints:(NIVector)p :(NIVector)q {
    if ((self = [super init])) {
        self.p = p;
        self.q = q;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:@[ [NSValue valueWithNIVector:self.p], [NSValue valueWithNIVector:self.q] ] forKey:@"points"];
}

- (NIBezierPath*)NIBezierPath {
    NIMutableBezierPath* path = [NIMutableBezierPath bezierPath];
    
    [path moveToVector:self.p];
    [path lineToVector:self.q];
    
    return path;
}

- (NSSet*)handlesInView:(NIAnnotatedGeneratorRequestView*)view {
    NIAffineTransform dicomToSliceTransform = NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform);
    return [NSSet setWithObjects:
            [NIAnnotationBlockHandle handleAtSliceVector:NIVectorApplyTransform(self.p, dicomToSliceTransform)
                                                   block:^(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector d) {
                                                       self.p = NIVectorAdd(self.p, d);
                                                   }],
            [NIAnnotationBlockHandle handleAtSliceVector:NIVectorApplyTransform(self.q, dicomToSliceTransform)
                                                   block:^(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector d) {
                                                       self.q = NIVectorAdd(self.q, d);
                                                   }], nil];
}

@end
