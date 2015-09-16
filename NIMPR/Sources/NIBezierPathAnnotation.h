//
//  NIBezierPathAnnotation.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/9/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotation.h"
#import "NIAnnotationHandle.h"

@interface NIBezierPathAnnotation : NIAnnotation {
    BOOL _fill;
}

@property BOOL fill;

+ (NSSet*)keyPathsForValuesAffectingNIBezierPath NS_REQUIRES_SUPER; // subclasses are supposed to overload this in order to declare what properties of the subclass affect the instances
- (NIBezierPath*)NIBezierPath;
- (NIBezierPath*)NIBezierPathForSlabView:(NIAnnotatedGeneratorRequestView*)view;
- (NIBezierPath*)NIBezierPathForSlabView:(NIAnnotatedGeneratorRequestView*)view complete:(BOOL)complete;

- (BOOL)isPlanar;
- (BOOL)isSolid;

@end

@interface NINSBezierPathAnnotation : NIBezierPathAnnotation <NITransformAnnotation> {
    NIAffineTransform _modelToDicomTransform;
}

@property NIAffineTransform modelToDicomTransform;

- (instancetype)initWithTransform:(NIAffineTransform)modelToDicomTransform;

+ (NSSet*)keyPathsForValuesAffectingNSBezierPath NS_REQUIRES_SUPER; // subclasses are supposed to overload this in order to declare what properties of the subclass affect the instances
- (NSBezierPath*)NSBezierPath;

@end