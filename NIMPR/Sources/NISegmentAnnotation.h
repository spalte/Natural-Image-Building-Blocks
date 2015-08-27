//
//  NILineAnnotation.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/10/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIBezierPathAnnotation.h"

@interface NISegmentAnnotation : NIBezierPathAnnotation {
    NIVector _p, _q;
}

@property NIVector p, q;

+ (id)segmentWithPoints:(NIVector)p :(NIVector)q;
+ (id)segmentWithPoints:(NSPoint)p :(NSPoint)q transform:(NIAffineTransform)planeToDicomTransform;

- (instancetype)initWithPoints:(NIVector)p :(NIVector)q;


@end
