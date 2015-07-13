//
//  NIEllipseAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/9/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIEllipseAnnotation.h"

@implementation NIEllipseAnnotation

- (NSBezierPath*)NSBezierPath {
    return [NSBezierPath bezierPathWithOvalInRect:self.bounds];
}

@end
