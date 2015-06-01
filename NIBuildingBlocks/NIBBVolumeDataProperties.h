//
//  NIBBVolumeDataProperties.h
//  SymetisTavi
//
//  Created by Joël Spaltenstein on 5/27/15.
//  Copyright (c) 2015 Spaltenstein Natural Image. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NIBBVolumeData.h"

@class NIBBGeneratorRequestLayer;

@interface NIBBVolumeDataProperties : NSObject
{
    NIBBGeneratorRequestLayer *_generatorRequestLayer;
}

@property (nonatomic, readwrite, assign) CGFloat windowWidth; // animatable
@property (nonatomic, readwrite, assign) CGFloat windowLevel; // animatable
@property (nonatomic, readwrite, assign) BOOL invert;
@property (nonatomic, readwrite, assign) NIBBInterpolationMode preferredInterpolationMode;
@property (nonatomic, readwrite, retain) id CLUT; // NSColor or NSGradient

@end
