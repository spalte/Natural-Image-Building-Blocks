//  Created by Joël Spaltenstein on 4/3/15.
//  Copyright (c) 2015 Spaltenstein Natural Image
//  Copyright (c) 2015 Michael Hilker and Andreas Holzamer
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


#import <QuartzCore/QuartzCore.h>
#import "NIGenerator.h"
#import "NIVolumeData.h"
#import "NIGeometry.h"

@class NIGeneratorRequest;
@class NIFloatImageRep;

@interface NIGeneratorRequestLayer : CAOpenGLLayer <NIGeneratorDelegate>
{
@private
    NIGeneratorRequest *_presentedGeneratorRequest;
    NIFloatImageRep *_presentedFloatImageRep;

    NIVolumeData *_volumeData;
    NIInterpolationMode _preferredInterpolationMode;
    BOOL _invert;
    id _CLUT;

    NIGeneratorRequest *_generatorRequest;
    NIGeneratorRequest *_fromGeneratorRequest;
    NIGeneratorRequest *_toGeneratorRequest;

    NIGenerator *_cubicGenerator; // the generator used to make the _cubicFloatImageRep
    NSTimer *_updateCubicTimer; // a timer so that
    NIGeneratorRequest *_cubicGeneratorRequest;    // the _cubicFloatImageRep corresponds to this request. If the image that needs to be displayed
    NIFloatImageRep *_cubicFloatImageRep;          // cooresponds to this request, then this image rep can be drawn instead
}

@property (nonatomic, readwrite, retain) NIGeneratorRequest *generatorRequest; // this is an animatable property
@property (nonatomic, readwrite, assign) CGFloat windowWidth; // animatable
@property (nonatomic, readwrite, assign) CGFloat windowLevel; // animatable
@property (nonatomic, readwrite, assign) NIInterpolationMode preferredInterpolationMode; // not animatable
@property (nonatomic, readwrite, assign) BOOL invert; // not animatable
@property (nonatomic, readwrite, retain) id CLUT; // not animatable

@property (nonatomic, readwrite, retain) NIVolumeData *volumeData; //not animatable

@property (nonatomic, readonly, retain) NIGeneratorRequest *presentedGeneratorRequest; // observable

- (CGPoint)convertPointFromDICOMVector:(NIVector)vector;
- (NIVector)convertPointToDICOMVector:(CGPoint)point;

@end
