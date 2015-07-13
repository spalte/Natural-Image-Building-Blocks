//
//  NIRectangleAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/13/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIRectangleAnnotation.h"

@implementation NIRectangleAnnotation

@synthesize bounds = _bounds;

+ (NSSet*)keyPathsForValuesAffectingNSBezierPath {
    return [NSSet setWithObject:@"bounds"];
}

- (instancetype)initWithBounds:(NSRect)bounds transform:(NIAffineTransform)sliceToDicomTransform {
    if ((self = [super initWithTransform:sliceToDicomTransform])) {
        self.bounds = bounds;
    }
    
    return self;
}

- (NSBezierPath*)NSBezierPath {
    return [NSBezierPath bezierPathWithRect:self.bounds];
}

@end
