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
#import "NIBBGenerator.h"
#import "NIBBVolumeData.h"
#import "NIBBGeometry.h"

@class NIBBGeneratorRequest;
@class NIBBFloatImageRep;

@interface NIBBGeneratorRequestLayer : CAOpenGLLayer <NIBBGeneratorDelegate>
{
@private
    NIBBGeneratorRequest *_presentedGeneratorRequest;
    NIBBFloatImageRep *_presentedFloatImageRep;

    NIBBVolumeData *_volumeData;
    NIBBInterpolationMode _preferredInterpolationMode;
    BOOL _invert;
    id _CLUT;

    NIBBGeneratorRequest *_generatorRequest;
    NIBBGeneratorRequest *_fromGeneratorRequest;
    NIBBGeneratorRequest *_toGeneratorRequest;

    NIBBGenerator *_cubicGenerator; // the generator used to make the _cubicFloatImageRep
    NSTimer *_updateCubicTimer; // a timer so that
    NIBBGeneratorRequest *_cubicGeneratorRequest;    // the _cubicFloatImageRep corresponds to this request. If the image that needs to be displayed
    NIBBFloatImageRep *_cubicFloatImageRep;          // cooresponds to this request, then this image rep can be drawn instead
}

@property (nonatomic, readwrite, retain) NIBBGeneratorRequest *generatorRequest; // this is an animatable property
@property (nonatomic, readwrite, assign) CGFloat windowWidth; // animatable
@property (nonatomic, readwrite, assign) CGFloat windowLevel; // animatable
@property (nonatomic, readwrite, assign) NIBBInterpolationMode preferredInterpolationMode; // not animatable
@property (nonatomic, readwrite, assign) BOOL invert; // not animatable
@property (nonatomic, readwrite, retain) id CLUT; // not animatable

@property (nonatomic, readwrite, retain) NIBBVolumeData *volumeData; //not animatable

@property (nonatomic, readonly, retain) NIBBGeneratorRequest *presentedGeneratorRequest; // observable

- (CGPoint)convertPointFromDICOMVector:(NIBBVector)vector;
- (NIBBVector)convertPointToDICOMVector:(CGPoint)point;

@end
