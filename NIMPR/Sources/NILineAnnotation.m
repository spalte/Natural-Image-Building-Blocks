//
//  NILineAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/10/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NILineAnnotation.h"

@implementation NILineAnnotation

@synthesize p = _p, q = _q;

+ (instancetype)annotationWithPoints:(NSPoint)p :(NSPoint)q transform:(NIAffineTransform)sliceToDicomTransform {
    return [[[self.class alloc] initWithPoints:p:q transform:sliceToDicomTransform] autorelease];
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

+ (NSSet*)keyPathsForValuesAffectingNSBezierPath {
    return [NSSet setWithObjects: @"p", @"q", nil];
}

@end
