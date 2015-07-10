//
//  NIEllipseAnnotation.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/9/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIBezierPathAnnotation.h"

@interface NIEllipseAnnotation : NINSBezierPathAnnotation {
    NSRect _bounds;
}

@property NSRect bounds;

+ (instancetype)annotationWithBounds:(NSRect)bounds transform:(NIAffineTransform)sliceToDicomTransform;

@end
