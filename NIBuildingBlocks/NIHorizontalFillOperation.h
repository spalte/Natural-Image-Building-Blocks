//  Copyright (c) 2016 OsiriX Foundation
//  Copyright (c) 2016 Spaltenstein Natural Image
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

#import <Cocoa/Cocoa.h>
#import "NIGeometry.h"
#import "NIVolumeData.h"

@class NIVolumeData;

// This operation will fill out floatBytes from the given data. FloatBytes is assumed to be tightly packed float image of width "width" and height "height"
// float bytes will be filled in with values at vectors and each successive scan line will be filled with with values at vector+normal*scanlineNumber
@interface NIHorizontalFillOperation : NSOperation {
    NIVolumeData *_volumeData;

    float *_floatBytes;
    NSUInteger _width;
    NSUInteger _height;

    NIVectorArray _vectors;
    NIVectorArray _normals;

    NIInterpolationMode _interpolationMode;
}

// vectors and normals need to be arrays of length width
- (id)initWithVolumeData:(NIVolumeData *)volumeData interpolationMode:(NIInterpolationMode)interpolationMode floatBytes:(float *)floatBytes width:(NSUInteger)width height:(NSUInteger)height vectors:(NIVectorArray)vectors normals:(NIVectorArray)normals;

@property (readonly, retain) NIVolumeData *volumeData;

@property (readonly, assign) float *floatBytes;
@property (readonly, assign) NSUInteger width;
@property (readonly, assign) NSUInteger height;

@property (readonly, assign) NIVectorArray vectors;
@property (readonly, assign) NIVectorArray normals;

@property (readonly, assign) NIInterpolationMode interpolationMode; // YES by default

@end
