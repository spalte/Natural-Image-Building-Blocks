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
- (NIBezierPath*)NIBezierPathForSlabView:(NIAnnotatedGeneratorRequestView*)view;
- (NIBezierPath*)NIBezierPathForSlabView:(NIAnnotatedGeneratorRequestView*)view complete:(BOOL)complete;

@end

@interface NINSBezierPathAnnotation : NIBezierPathAnnotation {
    NIAffineTransform _planeToDicomTransform;
}

@property NIAffineTransform planeToDicomTransform;

- (instancetype)initWithTransform:(NIAffineTransform)sliceToDicomTransform;

- (NSBezierPath*)NSBezierPath;

@end