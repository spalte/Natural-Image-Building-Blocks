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

@end
