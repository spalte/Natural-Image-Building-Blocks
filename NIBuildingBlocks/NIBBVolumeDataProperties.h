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
