//  Created by Joël Spaltenstein on 5/27/15.
//  Copyright (c) 2015 Spaltenstein Natural Image
//  Copyright (c) 2015 volz io
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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

