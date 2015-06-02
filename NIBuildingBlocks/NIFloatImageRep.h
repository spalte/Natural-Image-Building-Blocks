//  Created by Joël Spaltenstein on 2/27/15.
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

#import <Cocoa/Cocoa.h>
#import "NIGeometry.h"
#import "NIVolumeData.h"

@class NIVolumeData;

@interface NIFloatImageRep : NSImageRep
{
    NSMutableData *_floatData;

    CGFloat _windowWidth;
    CGFloat _windowLevel;
    BOOL _invert;
    id _CLUT;

    CGFloat _sliceThickness;

    NSMutableData *_cachedWindowedData; // array of windowed and inverted unsigned chars
    NSMutableData *_cachedCLUTData; // array of bytes in premultiplied ARGB8888

    BOOL _curved;
    NSPoint (^_convertPointFromDICOMVectorBlock)(NIVector);
    NIVector (^_convertPointToDICOMVectorBlock)(NSPoint);

    NIAffineTransform _imageToDicomTransform;
}

@property (nonatomic, readwrite, assign) CGFloat windowWidth; // these will affect how this rep will draw when part of an NSImage
@property (nonatomic, readwrite, assign) CGFloat windowLevel;
@property (nonatomic, readwrite, assign) BOOL invert; // invert the intensity after applying the WW/WL
@property (nonatomic, readwrite, retain) id CLUT; // Can be an NSColor or an NSGradient;

- (instancetype)initWithData:(NSData *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh;
- (instancetype)initWithBytes:(float *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh;
- (instancetype)initWithBytesNoCopy:(float *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh freeWhenDone:(BOOL)freeWhenDone;

- (float *)floatBytes;
- (const unsigned char *)windowedBytes; // unsigned chars of intensity
- (const unsigned char *)CLUTBytes; // RGBA unsigned chars
- (NSData *)floatData;
- (NSData *)windowedData; // unsigned chars of intensity
- (NSData *)CLUTData; // RGBA unsigned chars premultiplied ARGB8888
- (NSBitmapImageRep *)bitmapImageRep; // NSBitmapImageRep of the data after windowing, inverting, and applying the CLUT.

@property (nonatomic, readwrite, assign) CGFloat sliceThickness;

@property (nonatomic, readwrite, assign) NIAffineTransform imageToDicomTransform;
@property (nonatomic, readwrite, getter = isCurved) BOOL curved;

@property (nonatomic, readwrite, copy) NSPoint (^convertPointFromDICOMVectorBlock)(NIVector);
@property (nonatomic, readwrite, copy) NIVector (^convertPointToDICOMVectorBlock)(NSPoint);

- (NSPoint)convertPointFromDICOMVector:(NIVector)vector;
- (NIVector)convertPointToDICOMVector:(NSPoint)point;

@end

@interface NIFloatImageRep (DCMPixAndVolume)

- (void)getOrientation:(float[6])orientation;
- (void)getOrientationDouble:(double[6])orientation;

@property (readonly) float originX;
@property (readonly) float originY;
@property (readonly) float originZ;

@end


@interface NIVolumeData(NIFloatImageRepAdditions)
- (NIFloatImageRep *)floatImageRepForSliceAtIndex:(NSUInteger)z;
@end


