//
//  NIRectangleAnnotation.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/13/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIBezierPathAnnotation.h"

@interface NIRectangleAnnotation : NINSBezierPathAnnotation {
    NSRect _bounds;
}

@property NSRect bounds;

+ (id)rectangleWithBounds:(NSRect)bounds transform:(NIAffineTransform)sliceToDicomTransform;
- (instancetype)initWithBounds:(NSRect)bounds transform:(NIAffineTransform)sliceToDicomTransform;

@end
