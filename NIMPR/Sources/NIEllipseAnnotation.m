//
//  NIEllipseAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/9/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIEllipseAnnotation.h"

@implementation NIEllipseAnnotation

@synthesize bounds = _bounds;

+ (instancetype)annotationWithBounds:(NSRect)bounds transform:(NIAffineTransform)sliceToDicomTransform {
    return [[[self.class alloc] initWithBounds:bounds transform:sliceToDicomTransform] autorelease];
}

- (instancetype)initWithBounds:(NSRect)bounds transform:(NIAffineTransform)sliceToDicomTransform {
    if ((self = [super initWithTransform:sliceToDicomTransform])) {
        self.bounds = bounds;
    }
    
    return self;
}

- (NSBezierPath*)NSBezierPath {
    return [NSBezierPath bezierPathWithOvalInRect:self.bounds];
}

+ (NSSet*)keyPathsForValuesAffectingNSBezierPath {
    return [NSSet setWithObject:@"bounds"];
}

@end
