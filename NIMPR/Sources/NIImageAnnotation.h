//
//  NIImageAnnotation.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/13/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIRectangleAnnotation.h"

@interface NIImageAnnotation : NIRectangleAnnotation {
    NSImage* _image;
}

@property(retain) NSImage* image;

- (instancetype)initWithBounds:(NSRect)bounds image:(NSImage*)image transform:(NIAffineTransform)sliceToDicomTransform;

@end
