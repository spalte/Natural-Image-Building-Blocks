//  Created by Joël Spaltenstein on 5/27/15.
//  Copyright (c) 2016 Spaltenstein Natural Image
//  Copyright (c) 2016 volz io
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

#import "NIVolumeDataProperties.h"
#import "NIVolumeDataPropertiesPrivate.h"
#import "NIGeneratorRequestLayer.h"

@implementation NIVolumeDataProperties

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

- (void)setPreferredInterpolationMode:(NIInterpolationMode)preferredInterpolationMode
{
    _generatorRequestLayer.preferredInterpolationMode = preferredInterpolationMode;
}

- (NIInterpolationMode)preferredInterpolationMode
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

- (NIGeneratorRequestLayer *)generatorRequestLayer
{
    return _generatorRequestLayer;
}

- (void)setGeneratorRequestLayer:(NIGeneratorRequestLayer *)generatorRequestLayer
{
    _generatorRequestLayer = generatorRequestLayer;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString string];
    [description appendString:NSStringFromClass([self class])];
    [description appendString:[NSString stringWithFormat: @"\nWindow Width: %.2f\n", self.windowWidth]];
    [description appendString:[NSString stringWithFormat: @"Window Level: %.2f\n", self.windowLevel]];
    [description appendString:[NSString stringWithFormat: @"Invert: %@\n", self.invert ? @"YES" : @"NO"]];
    switch (self.preferredInterpolationMode) {
        case NIInterpolationModeLinear:
            [description appendString:[NSString stringWithFormat: @"Preferred Interpolation Mode: Linear\n"]];
            break;
        case NIInterpolationModeNearestNeighbor:
            [description appendString:[NSString stringWithFormat: @"Preferred Interpolation Mode: Nearest Neighbor\n"]];
            break;
        case NIInterpolationModeCubic:
            [description appendString:[NSString stringWithFormat: @"Preferred Interpolation Mode: Cubic\n"]];
            break;
        case NIInterpolationModeNone:
            [description appendString:[NSString stringWithFormat: @"Preferred Interpolation Mode: None\n"]];
            break;
        default:
            [description appendString:[NSString stringWithFormat: @"Preferred Interpolation Mode: Unknown\n"]];
            break;
    }
    if (self.CLUT) {
        [description appendString:[NSString stringWithFormat: @"CLUT Class: %@\n", NSStringFromClass([self.CLUT class])]];
        [description appendString:[NSString stringWithFormat: @"%@", self.CLUT]];
    } else {
        [description appendString:[NSString stringWithFormat: @"CLUT: None"]];
    }

    return description;
}

@end

