//  Created by Joël Spaltenstein on 2/27/15.
//  Copyright (c) 2016 Spaltenstein Natural Image
//  Copyright (c) 2016 Michael Hilker and Andreas Holzamer
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

#import <Cocoa/Cocoa.h>
#import "NIGeometry.h"
#import "NIVolumeData.h"

NS_ASSUME_NONNULL_BEGIN

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
    NSPoint (^_convertPointFromModelVectorBlock)(NIVector);
    NIVector (^_convertPointToModelVectorBlock)(NSPoint);

    NIAffineTransform _imageToModelTransform;
}

@property (nonatomic, readwrite, assign) CGFloat windowWidth; // these will affect how this rep will draw when part of an NSImage
@property (nonatomic, readwrite, assign) CGFloat windowLevel;
@property (nonatomic, readwrite, assign) BOOL invert; // invert the intensity after applying the WW/WL
@property (nullable, nonatomic, readwrite, retain) id CLUT; // Can be an NSColor or an NSGradient;

- (instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithData:(NSData *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithBytes:(nullable float *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh;
- (nullable instancetype)initWithBytesNoCopy:(float *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh freeWhenDone:(BOOL)freeWhenDone;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

- (float *)floatBytes;
- (const unsigned char *)windowedBytes; // unsigned chars of intensity
- (const unsigned char *)CLUTBytes; // RGBA unsigned chars
- (NSData *)floatData;
- (NSData *)windowedData; // unsigned chars of intensity
- (nullable NSData *)CLUTData; // RGBA unsigned chars premultiplied ARGB8888
- (NSBitmapImageRep *)bitmapImageRep; // NSBitmapImageRep of the data after windowing, inverting, and applying the CLUT.

@property (nonatomic, readwrite, assign) CGFloat sliceThickness;

@property (nonatomic, readwrite, assign) NIAffineTransform imageToModelTransform;
@property (nonatomic, readwrite, getter = isCurved) BOOL curved;

@property (nullable, nonatomic, readwrite, copy) NSPoint (^convertPointFromModelVectorBlock)(NIVector);
@property (nullable, nonatomic, readwrite, copy) NIVector (^convertPointToModelVectorBlock)(NSPoint);

- (NSPoint)convertPointFromModelVector:(NIVector)vector;
- (NIVector)convertPointToModelVector:(NSPoint)point;

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

NS_ASSUME_NONNULL_END


