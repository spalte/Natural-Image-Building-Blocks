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

/**
 NSImageRep subclass that can be used to render float images. FOr example, those obtained from NIVolumeData objects.
 This class can be used to render directly into Quartz, or can be used to apply window width/level, invert, and colors
 or CLUTs to the image. When drawing to Quartz, this class also knows how to add a rim, scalebar, and orientation
 labels with an API similar to NIGeneratorRequestView. When drawInRect: is called the rim, scalebar, and orientation
 labels are scaled to fit in the given rect. If draw: is called, rim, scalebar, and orientation labels are scaled as
 if 1 pixel = 1 point. Note that curved NIFloatImageRep objects can not be encoded using the NSCoder protocol.
*/

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

    NSColor *_rimColor;
    CGFloat _rimThickness;
    BOOL _displayOrientationLabels;
    BOOL _displayScaleBar;
}

- (instancetype)init NS_UNAVAILABLE;

/**
 Initializes the receiver, a newly allocated NSBitmapImageRep object, so it can render the specified image.
 @param data Data that contains an array of packed float values that represent the object. The length of the Data must be longer than sizeof(float)*pixelsWide*pixelsHigh.
 If data is nil, new memory is allocated for the image.
 @return Returns the newy initialized NSBitmapImageRep object.
*/
- (instancetype)initWithData:(nullable NSData *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithBytes:(nullable float *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh __deprecated;
- (instancetype)initWithBytesNoCopy:(float *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh freeWhenDone:(BOOL)freeWhenDone __deprecated;

/**
 The Window Width to apply to the underlying float representation of the image data.
*/
@property (nonatomic) CGFloat windowWidth; // these will affect how this rep will draw when part of an NSImage
/**
 The Window Level to apply to the underlying float representation of the image data.
 */
@property (nonatomic) CGFloat windowLevel;
/**
 A boolean value that represents whether the underlying float representation of the image data, after having been windowed, needs to be inverted.
 */
@property (nonatomic) BOOL invert; // invert the intensity after applying the WW/WL
/**
 The color to apply to the windowed, and inverted if needed, float representation. This property can be set to either an NSColor or NSGradient.
*/
@property (nullable, strong, nonatomic) id CLUT; // Can be an NSColor or an NSGradient;

/**
 A pointer to the float representation of the image data. Calling this propery invalidates the caches of the windowedBytes and the CLUTBytes.
*/
@property (nullable, readonly) float *floatBytes NS_RETURNS_INNER_POINTER __deprecated; // use the methods that return an NSData.
/**
 A pointer to the 8bit unsigned char representation of the float image representation after windowing and possibly inverting.
*/
@property (nullable, readonly) const unsigned char *windowedBytes NS_RETURNS_INNER_POINTER __deprecated; // unsigned chars of intensity
/**
 A pointer to a premultiplied ARGB8888 representation of the image after applying the CLUT.
*/
@property (nullable, readonly) const unsigned char *CLUTBytes NS_RETURNS_INNER_POINTER __deprecated; // RGBA unsigned chars
/*
 Returns a NSBitmapImageRep object that can be used to draw the receiver. If a CLUT is applied, the colorspace of the returned bitmap will be a NSDeviceRGBColorSpace.
 If there is no CLUT the colorspace will be NSDeviceWhiteColorSpace.
*/
@property (nullable, readonly, copy) NSBitmapImageRep *bitmapImageRep; // NSBitmapImageRep of the data after windowing, inverting, and applying the CLUT.

@property (nullable, readonly, copy) NSData* floatData;
@property (nullable, readonly, copy) NSData *windowedData; // unsigned chars of intensity
@property (nullable, readonly, copy) NSData *CLUTData; // RGBA unsigned chars premultiplied ARGB8888

// Draw additional items over the image.
@property (nullable, strong) NSColor *rimColor;
@property CGFloat rimThickness;
@property BOOL displayOrientationLabels;
@property BOOL displayScaleBar;

@property CGFloat sliceThickness;

@property (nonatomic) NIAffineTransform imageToModelTransform;
@property (getter = isCurved) BOOL curved;

@property (nullable, copy) NSPoint (^convertPointFromModelVectorBlock)(NIVector);
@property (nullable, copy) NIVector (^convertPointToModelVectorBlock)(NSPoint);

- (NSPoint)convertPointFromModelVector:(NIVector)vector;
- (NIVector)convertPointToModelVector:(NSPoint)point;

@end

@interface NIVolumeData(NIFloatImageRepAdditions)
- (NIFloatImageRep *)floatImageRepForSliceAtIndex:(NSUInteger)z;
@end

NS_ASSUME_NONNULL_END


