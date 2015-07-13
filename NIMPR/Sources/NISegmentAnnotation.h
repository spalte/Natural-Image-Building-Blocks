//
//  NILineAnnotation.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/10/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIBezierPathAnnotation.h"

@interface NISegmentAnnotation : NINSBezierPathAnnotation {
    NSPoint _p, _q;
}

@property NSPoint p, q;

- (instancetype)initWithPoints:(NSPoint)p :(NSPoint)q transform:(NIAffineTransform)sliceToDicomTransform;

@end
