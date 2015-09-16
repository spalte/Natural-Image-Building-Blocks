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
    return [[super keyPathsForValuesAffectingNIBezierPath] setByAddingObjects: @"p", @"q", nil];
}

+ (id)segmentWithPoints:(NIVector)p :(NIVector)q {
    return [[[self.class alloc] initWithPoints:p:q] autorelease];
}

+ (id)segmentWithPoints:(NSPoint)p :(NSPoint)q transform:(NIAffineTransform)modelToDicomTransform {
    NIVector pv = NIVectorApplyTransform(NIVectorMakeFromNSPoint(p), modelToDicomTransform), qv = NIVectorApplyTransform(NIVectorMakeFromNSPoint(q), modelToDicomTransform);
    return [self segmentWithPoints:pv:qv];
}

- (instancetype)initWithPoints:(NIVector)p :(NIVector)q {
    if ((self = [self init])) {
        self.p = p;
        self.q = q;
    }
    
    return self;
}

- (instancetype)init {
    return [super init];
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

- (BOOL)isPlanar {
    return YES;
}

- (void)translate:(NIVector)translation {
    self.p = NIVectorAdd(self.p, translation);
    self.q = NIVectorAdd(self.q, translation);
}

- (NIMask*)maskForVolume:(NIVolumeData*)volume {
    NIVector vp = [volume convertVolumeVectorFromDICOMVector:self.p], vq = [volume convertVolumeVectorFromDICOMVector:self.q];
//    NSUInteger d = CGFloatMax(CGFloatRound(NIVectorDistance(vp, vq)), 1);
//    
//    NIVector pq = NIVectorSubtract(self.q, self.p);
//    NIVector m = NIVectorMake(1, 0, 0);
//    
//    NIAffineTransform destTransform = NIAffineTransformIdentity;
//    
//    NIVector cp = NIVectorCrossProduct(pq, m);
//    if (!NIVectorIsZero(cp)) {
//        CGFloat angle = NIVectorAngleBetweenVectorsAroundVector(m, pq, cp);
//        destTransform = NIAffineTransformMakeRotationAroundVector(angle, cp);
//    }
//    
//    destTransform = NIAffineTransformConcat(destTransform, NIAffineTransformMakeTranslationWithVector(vp));
//    
//    NIMask* mask = [NIMask maskWithBoxWidth:d height:1 depth:1];
//    mask = [mask maskByResamplingFromVolumeTransform:NIAffineTransformIdentity toVolumeTransform:destTransform interpolationMode:NIInterpolationModeCubic];
//    mask = [mask binaryMask];
//    
    NSLog(@"......................... Mask for %@... \nvolume %@ to %@", self, NSStringFromNIVector(vp), NSStringFromNIVector(vq));

    NIMask* mask = [super maskForVolume:volume];
    
//    NSLog(@"Segment mask: %@", mask);
    NSLog(@"%@", mask);
//    
    return mask;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@ 0x%lx: from %@ to %@>", self.className, (unsigned long)self, NSStringFromNIVector(self.p), NSStringFromNIVector(self.q)];
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
