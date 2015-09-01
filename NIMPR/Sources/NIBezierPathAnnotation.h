//
//  NIBezierPathAnnotation.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/9/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotation.h"
#import "NIAnnotationHandle.h"

@interface NIBezierPathAnnotation : NIAnnotation

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder*)coder NS_DESIGNATED_INITIALIZER;

+ (NSSet*)keyPathsForValuesAffectingNIBezierPath;
- (NIBezierPath*)NIBezierPath;
- (NIBezierPath*)NIBezierPathForSlabView:(NIAnnotatedGeneratorRequestView*)view;
- (NIBezierPath*)NIBezierPathForSlabView:(NIAnnotatedGeneratorRequestView*)view complete:(BOOL)complete;

- (BOOL)isSolid;

@end

@interface NINSBezierPathAnnotation : NIBezierPathAnnotation <NITransformAnnotation> {
    NIAffineTransform _modelToDicomTransform;
}

@property NIAffineTransform modelToDicomTransform;

- (instancetype)init NS_DESIGNATED_INITIALIZER; // inits transform to NIAffineTransformIdentity
- (instancetype)initWithCoder:(NSCoder*)coder NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithTransform:(NIAffineTransform)modelToDicomTransform;

+ (NSSet*)keyPathsForValuesAffectingNSBezierPath;
- (NSBezierPath*)NSBezierPath;

@end