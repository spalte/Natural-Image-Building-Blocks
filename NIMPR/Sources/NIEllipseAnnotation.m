//
//  NIEllipseAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/9/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIEllipseAnnotation.h"
#import "NIJSON.h"

@implementation NIEllipseAnnotation

+ (void)load {
    [NIJSON setName:@"ellipse" forClass:NIEllipseAnnotation.class];
}

+ (id)ellipseWithBounds:(NSRect)bounds transform:(NIAffineTransform)sliceToDicomTransform {
    return [[[self.class alloc] initWithBounds:bounds transform:sliceToDicomTransform] autorelease];
}

- (NSBezierPath*)NSBezierPath {
    return [NSBezierPath bezierPathWithOvalInRect:self.bounds];
}

@end
