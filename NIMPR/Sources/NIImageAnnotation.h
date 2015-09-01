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
    NSData* _data;
    BOOL _colorify;
}

@property(retain) NSImage* image;
@property(retain) NSData* data;
@property BOOL colorify;

//- (instancetype)initWithImage:(NSImage*)image transform:(NIAffineTransform)sliceToDicomTransform __deprecated; // for storage reasons: we can't safely obtain the original data off an NSImage instance

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder*)coder NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithData:(NSData*)data;
- (instancetype)initWithData:(NSData*)data transform:(NIAffineTransform)modelToDicomTransform;

@end
