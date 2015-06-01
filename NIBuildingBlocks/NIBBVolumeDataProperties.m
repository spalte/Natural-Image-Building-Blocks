//
//  NIBBVolumeDataProperties.m
//  SymetisTavi
//
//  Created by Joël Spaltenstein on 5/27/15.
//  Copyright (c) 2015 Spaltenstein Natural Image. All rights reserved.
//

#import "NIBBVolumeDataProperties.h"
#import "NIBBVolumeDataPropertiesPrivate.h"
#import "NIBBGeneratorRequestLayer.h"

@implementation NIBBVolumeDataProperties

- (void)setWindowWidth:(CGFloat)windowWidth
{
    _generatorRequestLayer.windowWidth = windowWidth;
}

- (CGFloat)windowWidth
{
    return _generatorRequestLayer.windowWidth;
}

- (void)setWindowLevel:(CGFloat)windowLevel
{
    _generatorRequestLayer.windowLevel = windowLevel;
}

- (CGFloat)windowLevel
{
    return _generatorRequestLayer.windowLevel;
}

- (void)setInvert:(BOOL)invert
{
    _generatorRequestLayer.invert = invert;
}

- (BOOL)invert
{
    return _generatorRequestLayer.invert;
}

- (void)setPreferredInterpolationMode:(NIBBInterpolationMode)preferredInterpolationMode
{
    _generatorRequestLayer.preferredInterpolationMode = preferredInterpolationMode;
}

- (NIBBInterpolationMode)preferredInterpolationMode
{
    return _generatorRequestLayer.preferredInterpolationMode;
}

- (void)setCLUT:(id)CLUT
{
    _generatorRequestLayer.CLUT = CLUT;
}

- (id)CLUT
{
    return _generatorRequestLayer.CLUT;
}

- (NIBBGeneratorRequestLayer *)generatorRequestLayer
{
    return _generatorRequestLayer;
}

- (void)setGeneratorRequestLayer:(NIBBGeneratorRequestLayer *)generatorRequestLayer
{
    _generatorRequestLayer = generatorRequestLayer;
}

@end

