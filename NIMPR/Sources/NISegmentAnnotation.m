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

+ (NSSet*)keyPathsForValuesAffectingNIBezierPath {
    return [NSSet setWithObjects: @"p", @"q", nil];
}

+ (id)segmentWithPoints:(NIVector)p :(NIVector)q {
    return [[[self.class alloc] initWithPoints:p:q] autorelease];
}

+ (id)segmentWithPoints:(NSPoint)p :(NSPoint)q transform:(NIAffineTransform)modelToDicomTransform {
    NIVector pv = NIVectorApplyTransform(NIVectorMakeFromNSPoint(p), modelToDicomTransform), qv = NIVectorApplyTransform(NIVectorMakeFromNSPoint(q), modelToDicomTransform);
    return [self segmentWithPoints:pv:qv];
}

- (instancetype)init {
    if ((self = [super init])) {
    }
    
    return self;
}

- (instancetype)initWithPoints:(NIVector)p :(NIVector)q {
    if ((self = [self init])) {
        self.p = p;
        self.q = q;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    if ((self = [super initWithCoder:coder])) {
        NSArray* points = [[coder decodeObjectForKey:@"points"] requireArrayOfValuesWithObjCType:@encode(NIVector)];
        self.p = [points[0] NIVectorValue];
        self.q = [points[1] NIVectorValue];
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
