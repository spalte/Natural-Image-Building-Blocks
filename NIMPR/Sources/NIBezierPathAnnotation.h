//
//  NIBezierPathAnnotation.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/9/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotation.h"

@interface NIBezierPathAnnotation : NIAnnotation

- (NIBezierPath*)NIBezierPath;

- (BOOL)fill;

@end

@interface NINSBezierPathAnnotation : NIBezierPathAnnotation {
    NIAffineTransform _sliceToDicomTransform;
}

@property NIAffineTransform sliceToDicomTransform;

- (instancetype)initWithTransform:(NIAffineTransform)sliceToDicomTransform;

- (NSBezierPath*)NSBezierPath;

@end