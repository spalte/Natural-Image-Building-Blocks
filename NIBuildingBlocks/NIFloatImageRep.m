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


#include <Accelerate/Accelerate.h>

#import "NIFloatImageRep.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIFloatImageRep ()

- (void)_buildCachedData;

@end

@implementation NIFloatImageRep

@synthesize windowWidth = _windowWidth;
@synthesize windowLevel = _windowLevel;
@synthesize invert = _invert;
@synthesize CLUT = _CLUT;

@synthesize sliceThickness = _sliceThickness;
@synthesize imageToModelTransform = _imageToModelTransform;

@synthesize curved = _curved;
@synthesize convertPointFromModelVectorBlock = _convertPointFromModelVectorBlock;
@synthesize convertPointToModelVectorBlock = _convertPointToModelVectorBlock;

- (instancetype)initWithData:(NSData *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh
{
    if ( (self = [super init]) ) {
        [self setColorSpaceName:NSCustomColorSpace];

        if (data == NULL) {
            _floatData = [NSMutableData dataWithLength:pixelsWide * pixelsHigh * sizeof(float)];
            memset([_floatData mutableBytes], 0, pixelsWide * pixelsHigh * sizeof(float));
        } else {
            _floatData = (NSMutableData *)[data retain];
        }

        [self setPixelsWide:pixelsWide];
        [self setPixelsHigh:pixelsHigh];
        [self setSize:NSMakeSize(pixelsWide, pixelsHigh)];
        _imageToModelTransform = NIAffineTransformIdentity;

        self.convertPointFromModelVectorBlock = ^NSPoint(NIVector vector){return NSPointFromNIVector(NIVectorApplyTransform(vector, NIAffineTransformInvert(NIAffineTransformIdentity)));};
        self.convertPointToModelVectorBlock = ^NIVector(NSPoint point){return NIVectorApplyTransform(NIVectorMakeFromNSPoint(point), NIAffineTransformIdentity);};
    }

    return self;
}

- (instancetype)initWithBytes:(float *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh;
{
    if ( (self = [super init]) ) {
        [self setColorSpaceName:NSCustomColorSpace];

        if (data == NULL) {
            _floatData = [NSMutableData dataWithLength:pixelsWide * pixelsHigh * sizeof(float)];
            memset([_floatData mutableBytes], 0, pixelsWide * pixelsHigh * sizeof(float));
        } else {
            _floatData = [NSMutableData dataWithBytes:data length:pixelsWide * pixelsHigh * sizeof(float)];
        }
        [self setPixelsWide:pixelsWide];
        [self setPixelsHigh:pixelsHigh];
        [self setSize:NSMakeSize(pixelsWide, pixelsHigh)];
        _imageToModelTransform = NIAffineTransformIdentity;

        self.convertPointFromModelVectorBlock = ^NSPoint(NIVector vector){return NSPointFromNIVector(NIVectorApplyTransform(vector, NIAffineTransformInvert(NIAffineTransformIdentity)));};
        self.convertPointToModelVectorBlock = ^NIVector(NSPoint point){return NIVectorApplyTransform(NIVectorMakeFromNSPoint(point), NIAffineTransformIdentity);};
    }

    return self;
}

- (instancetype)initWithBytesNoCopy:(float *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh freeWhenDone:(BOOL)freeWhenDone;
{
    if ( (self = [super init]) ) {
        [self setColorSpaceName:NSCustomColorSpace];

        if (data == NULL) {
            _floatData = [NSMutableData dataWithLength:pixelsWide * pixelsHigh * sizeof(float)];
            memset([_floatData mutableBytes], 0, pixelsWide * pixelsHigh * sizeof(float));
        } else {
            _floatData = [NSMutableData dataWithBytesNoCopy:data length:pixelsWide * pixelsHigh * sizeof(float) freeWhenDone:freeWhenDone];
        }
        [self setPixelsWide:pixelsWide];
        [self setPixelsHigh:pixelsHigh];
        [self setSize:NSMakeSize(pixelsWide, pixelsHigh)];
        _imageToModelTransform = NIAffineTransformIdentity;


        self.convertPointFromModelVectorBlock = ^NSPoint(NIVector vector){return NSPointFromNIVector(NIVectorApplyTransform(vector, NIAffineTransformInvert(NIAffineTransformIdentity)));};
        self.convertPointToModelVectorBlock = ^NIVector(NSPoint point){return NIVectorApplyTransform(NIVectorMakeFromNSPoint(point), NIAffineTransformIdentity);};
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if ([coder allowsKeyedCoding]) {
        if ( (self = [super initWithCoder:coder]) ) {
            _floatData = [[coder decodeObjectOfClass:[NSData class] forKey:@"floatData"] retain];

            _windowLevel = [coder decodeDoubleForKey:@"windowLevel"];
            _windowWidth = [coder decodeDoubleForKey:@"windowWidth"];

            _invert = [coder decodeBoolForKey:@"invert"];
            _CLUT = [coder decodeObjectOfClasses:[NSSet setWithObjects:[NSColor class], [NSGradient class], nil] forKey:@"CLUT"];

            _sliceThickness = [coder decodeDoubleForKey:@"sliceThickness"];

            _curved = NO; // we can't encode curved planes
            _convertPointFromModelVectorBlock = NULL;
            _convertPointToModelVectorBlock = NULL;

            _imageToModelTransform = [coder decodeNIAffineTransformForKey:@"imageToModelTransform"];
        }
    } else {
        [NSException raise:NSInvalidUnarchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder allowsKeyedCoding]) {
        if (_curved) {
            [NSException raise:NSInvalidArchiveOperationException format:@"*** %s: can't archive curved images", __PRETTY_FUNCTION__];
        }

        [aCoder encodeObject:_floatData forKey:@"floatData"];

        [aCoder encodeDouble:_windowLevel forKey:@"windowLevel"];
        [aCoder encodeDouble:_windowWidth forKey:@"windowWidth"];

        [aCoder encodeBool:_invert forKey:@"invert"];
        [aCoder encodeObject:_CLUT forKey:@"CLUT"];

        [aCoder encodeDouble:_sliceThickness forKey:@"sliceThickness"];

        [aCoder encodeNIAffineTransform:_imageToModelTransform forKey:@"imageToModelTransform"];
    } else {
        [NSException raise:NSInvalidArchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }
}

- (void)dealloc
{
    [_floatData release];
    _floatData = nil;
    [_cachedWindowedData release];
    _cachedWindowedData = nil;
    [_cachedCLUTData release];
    _cachedCLUTData = nil;
    [_CLUT release];
    _CLUT = nil;

    [_convertPointFromModelVectorBlock release];
    _convertPointFromModelVectorBlock = nil;
    [_convertPointToModelVectorBlock release];
    _convertPointToModelVectorBlock = nil;

    [super dealloc];
}

-(BOOL)draw
{
    return [[self bitmapImageRep] draw];
}

- (void)setImageToModelTransform:(NIAffineTransform)imageToModelTransform
{
    _imageToModelTransform = imageToModelTransform;

    self.convertPointFromModelVectorBlock = ^NSPoint(NIVector vector){return NSPointFromNIVector(NIVectorApplyTransform(vector, NIAffineTransformInvert(imageToModelTransform)));};
    self.convertPointToModelVectorBlock = ^NIVector(NSPoint point){return NIVectorApplyTransform(NIVectorMakeFromNSPoint(point), imageToModelTransform);};
}

- (void)setWindowLevel:(CGFloat)windowLevel
{
    if (windowLevel != _windowLevel) {
        _windowLevel = windowLevel;

        [_cachedWindowedData release];
        _cachedWindowedData = nil;
        [_cachedCLUTData release];
        _cachedCLUTData = nil;
    }
}

- (void)setWindowWidth:(CGFloat)windowWidth
{
    if (windowWidth != _windowWidth) {
        _windowWidth = windowWidth;

        [_cachedWindowedData release];
        _cachedWindowedData = nil;
        [_cachedCLUTData release];
        _cachedCLUTData = nil;
    }
}

- (void)setInvert:(BOOL)invert
{
    if (_invert != invert) {
        _invert = invert;

        [_cachedWindowedData release];
        _cachedWindowedData = nil;
        [_cachedCLUTData release];
        _cachedCLUTData = nil;
    }
}

- (void)setCLUT:(nullable id)CLUT
{
    if (CLUT != nil && [CLUT isKindOfClass:[NSColor class]] == NO &&  [CLUT isKindOfClass:[NSGradient class]] == NO) {
        NSAssert(NO, @"CLUT is not an NSColor or NSGradient");
        return;
    }

    if ([_CLUT isEqual:CLUT] == NO) {
        [_CLUT release];
        _CLUT = [CLUT retain];

        [_cachedWindowedData release];
        _cachedWindowedData = nil;
        [_cachedCLUTData release];
        _cachedCLUTData = nil;
    }
}

- (float *)floatBytes;
{
    [_cachedWindowedData release];  // if we grab the bytes, expect that we did it to modify the bytes
    _cachedWindowedData = nil;
    [_cachedCLUTData release];
    _cachedCLUTData = nil;

    return (float *)[_floatData bytes];
}

- (const unsigned char *)windowedBytes
{
    [self _buildCachedData];

    return [_cachedWindowedData bytes];
}

- (const unsigned char *)CLUTBytes;
{
    [self _buildCachedData];

    return [_cachedCLUTData bytes];
}


- (NSData *)floatData
{
    return _floatData;
}

- (NSData *)windowedData
{
    [self _buildCachedData];

    return _cachedWindowedData;
}

- (nullable NSData *)CLUTData
{
    [self _buildCachedData];

    return _cachedWindowedData;
}

- (NSBitmapImageRep *)bitmapImageRep // NSBitmapImageRep of the data after windowing, inverting, and applying the CLUT.
{
    [self _buildCachedData];

    if (_CLUT == nil) { // no CLUT to apply make a grayscale image
        NSBitmapImageRep *windowedBitmapImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:[self pixelsWide] pixelsHigh:[self pixelsHigh]
                                                                                        bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:YES colorSpaceName:NSDeviceWhiteColorSpace
                                                                                          bytesPerRow:[self pixelsWide] bitsPerPixel:8];
        memcpy([windowedBitmapImageRep bitmapData], [_cachedWindowedData bytes], [self pixelsWide] * [self pixelsHigh]);
        return [windowedBitmapImageRep autorelease];
    } else {
        NSBitmapImageRep *clutBitmapImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:[self pixelsWide] pixelsHigh:[self pixelsHigh]
                                                                                    bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace
                                                                                     bitmapFormat:NSAlphaNonpremultipliedBitmapFormat bytesPerRow:[self pixelsWide] * 4 bitsPerPixel:32];
        memcpy([clutBitmapImageRep bitmapData], [_cachedCLUTData bytes], [self pixelsWide] * [self pixelsHigh] * 4);
        return [clutBitmapImageRep autorelease];
    }
}

- (void)_buildCachedData
{
    float *workingFloats = nil;

    if (_cachedWindowedData == nil) {
        NSUInteger pixelCount = [self pixelsHigh] * [self pixelsWide];
        _cachedWindowedData = [[NSMutableData alloc] initWithLength:pixelCount];

        float *floatBytes = (float *)[_floatData bytes];
        unsigned char *grayBytes = [_cachedWindowedData mutableBytes];
        workingFloats = malloc(pixelCount * sizeof(float));

        float twoFiftyFive = 255.0;
        float negOne = -1.0;

        // adjust the window level and width according to the DICOM docs (Part 3 C.11.2.1.2)
        if (_windowWidth > 1) { // regular case
            float float1 = 255.0/(_windowWidth - 1.0);
            float float2 = 127.5 - (((255.0 * _windowLevel) - 127.5) / (_windowWidth - 1.0));

            vDSP_vsmsa(floatBytes, 1, &float1, &float2, workingFloats, 1, pixelCount);

            float lowClip = 0;
            float highClip = 255;
            vDSP_vclip(workingFloats, 1, &lowClip, &highClip, workingFloats, 1, pixelCount);

            if (_invert) {
                vDSP_vsmsa(workingFloats, 1, &negOne, &twoFiftyFive, workingFloats, 1, pixelCount);
            }

            vDSP_vfixru8(workingFloats, 1, grayBytes, 1, pixelCount);

            if (_CLUT) {
                float oneOverTwoFiftyFive = 1.0/255.0;
                vDSP_vsmul(workingFloats, 1, &oneOverTwoFiftyFive, workingFloats, 1, pixelCount);
            }
        } else { // just do a binary threshold
            float thres = 0.5 - _windowLevel;
            float c = -127.5;
            float add = 127.5;
            vDSP_vsmul(floatBytes, 1, &negOne, workingFloats, 1, pixelCount);
            vDSP_vthrsc(workingFloats, 1, &thres, &c, workingFloats, 1, pixelCount);
            vDSP_vsadd(workingFloats, 1, &add, workingFloats, 1, pixelCount);

            if (_invert) {
                vDSP_vsmsa(workingFloats, 1, &negOne, &twoFiftyFive, workingFloats, 1, pixelCount);
            }

            vDSP_vfixu8(workingFloats, 1, grayBytes, 1, pixelCount);

            if (_CLUT) {
                float oneOverTwoFiftyFive = 1.0/255.0;
                vDSP_vsmul(workingFloats, 1, &oneOverTwoFiftyFive, workingFloats, 1, pixelCount);
            }
        }
    }

    if (_CLUT && _cachedCLUTData == nil) {
        NSUInteger pixelCount = [self pixelsHigh] * [self pixelsWide];
        _cachedCLUTData = [[NSMutableData alloc] initWithLength:pixelCount * 4];

        if ([_CLUT isKindOfClass:[NSColor class]]) {
            NSColor *clutColor = [(NSColor *)_CLUT colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            float redComponent = [clutColor redComponent] * [clutColor alphaComponent] * 255.0;
            float greenComponent = [clutColor greenComponent] * [clutColor alphaComponent] * 255.0;
            float blueComponent = [clutColor blueComponent] * [clutColor alphaComponent] * 255.0;
            float alphaComponent = [clutColor alphaComponent] * 255.0;
            float *scaledFloat = malloc(pixelCount * sizeof(float));

            vDSP_vsmul(workingFloats, 1, &redComponent, scaledFloat, 1, pixelCount);
            vDSP_vfixu8(scaledFloat, 1, [_cachedCLUTData mutableBytes] + 0, 4, pixelCount);

            vDSP_vsmul(workingFloats, 1, &greenComponent, scaledFloat, 1, pixelCount);
            vDSP_vfixu8(scaledFloat, 1, [_cachedCLUTData mutableBytes] + 1, 4, pixelCount);

            vDSP_vsmul(workingFloats, 1, &blueComponent, scaledFloat, 1, pixelCount);
            vDSP_vfixu8(scaledFloat, 1, [_cachedCLUTData mutableBytes] + 2, 4, pixelCount);

            vDSP_vsmul(workingFloats, 1, &alphaComponent, scaledFloat, 1, pixelCount);
            vDSP_vfixu8(scaledFloat, 1, [_cachedCLUTData mutableBytes] + 3, 4, pixelCount);
            
            free(scaledFloat);
        } else if ([_CLUT isKindOfClass:[NSGradient class]]) {
            NSGradient *gradient = (NSGradient *)_CLUT;

            NSBitmapImageRep *lookupTableBitmapImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:4096 pixelsHigh:1
                                                                                                bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace
                                                                                                  bytesPerRow:4096 * 4 bitsPerPixel:32];
            NSGraphicsContext *lookupTableGraphicsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:lookupTableBitmapImageRep];

            [NSGraphicsContext saveGraphicsState];
            [NSGraphicsContext setCurrentContext:lookupTableGraphicsContext];
            [lookupTableGraphicsContext setCompositingOperation:NSCompositeCopy];
            [gradient drawInRect:NSMakeRect(0, 0, 4096, 1) angle:0];
            [lookupTableGraphicsContext flushGraphics];
            [NSGraphicsContext restoreGraphicsState];

            vImage_Buffer lookup;
            lookup.data = [lookupTableBitmapImageRep bitmapData];
            lookup.height = 1;
            lookup.width = 4096;
            lookup.rowBytes = 4096 * 4;
            vImage_Buffer lookup_red;
            lookup_red.data = malloc(4096);
            lookup_red.height = 1;
            lookup_red.width = 4096;
            lookup_red.rowBytes = 4096;
            vImage_Buffer lookup_green;
            lookup_green.data = malloc(4096);
            lookup_green.height = 1;
            lookup_green.width = 4096;
            lookup_green.rowBytes = 4096;
            vImage_Buffer lookup_blue;
            lookup_blue.data = malloc(4096);
            lookup_blue.height = 1;
            lookup_blue.width = 4096;
            lookup_blue.rowBytes = 4096;
            vImage_Buffer lookup_alpha;
            lookup_alpha.data = malloc(4096);
            lookup_alpha.height = 1;
            lookup_alpha.width = 4096;
            lookup_alpha.rowBytes = 4096;

            // extract the planes of the lookup table
            vImage_Error error = kvImageNoError;

            error = vImageConvert_ARGB8888toPlanar8(&lookup, &lookup_red, &lookup_green, &lookup_blue, &lookup_alpha, 0);
            if (error != kvImageNoError) {
                NSLog(@"vImageConvert_ARGB8888toPlanar8 error %d", (int)error);
            }

            vImage_Buffer windowed;
            windowed.data = workingFloats;
            windowed.height = [self pixelsHigh];
            windowed.width = [self pixelsWide];
            windowed.rowBytes = [self pixelsWide] * 4;
            vImage_Buffer clut;
            clut.data = [_cachedCLUTData mutableBytes];
            clut.height = [self pixelsHigh];
            clut.width = [self pixelsWide];
            clut.rowBytes = [self pixelsWide] * 4;
            vImage_Buffer clut_red;
            clut_red.data = malloc(pixelCount);
            clut_red.height = [self pixelsHigh];
            clut_red.width = [self pixelsWide];
            clut_red.rowBytes = [self pixelsWide];
            vImage_Buffer clut_green;
            clut_green.data = malloc(pixelCount);
            clut_green.height = [self pixelsHigh];
            clut_green.width = [self pixelsWide];
            clut_green.rowBytes = [self pixelsWide];
            vImage_Buffer clut_blue;
            clut_blue.data = malloc(pixelCount);
            clut_blue.height = [self pixelsHigh];
            clut_blue.width = [self pixelsWide];
            clut_blue.rowBytes = [self pixelsWide];
            vImage_Buffer clut_alpha;
            clut_alpha.data = malloc(pixelCount);
            clut_alpha.height = [self pixelsHigh];
            clut_alpha.width = [self pixelsWide];
            clut_alpha.rowBytes = [self pixelsWide];

            error = vImageLookupTable_PlanarFtoPlanar8(&windowed, &clut_red, lookup_red.data, 0);
            if (error != kvImageNoError) {
                NSLog(@"vImageLookupTable_PlanarFtoPlanar8 error %d", (int)error);
            }
            error = vImageLookupTable_PlanarFtoPlanar8(&windowed, &clut_green, lookup_green.data, 0);
            if (error != kvImageNoError) {
                NSLog(@"vImageLookupTable_PlanarFtoPlanar8 error %d", (int)error);
            }
            error = vImageLookupTable_PlanarFtoPlanar8(&windowed, &clut_blue, lookup_blue.data, 0);
            if (error != kvImageNoError) {
                NSLog(@"vImageLookupTable_PlanarFtoPlanar8 error %d", (int)error);
            }
            error = vImageLookupTable_PlanarFtoPlanar8(&windowed, &clut_alpha, lookup_alpha.data, 0);
            if (error != kvImageNoError) {
                NSLog(@"vImageLookupTable_PlanarFtoPlanar8 error %d", (int)error);
            }
            
            error = vImageConvert_Planar8toARGB8888(&clut_red, &clut_green, &clut_blue, &clut_alpha, &clut, 0);
            if (error != kvImageNoError) {
                NSLog(@"vImageConvert_Planar8toARGB8888 error %d", (int)error);
            }

            [lookupTableBitmapImageRep release];

            free(lookup_red.data);
            free(lookup_green.data);
            free(lookup_blue.data);
            free(lookup_alpha.data);
            free(clut_red.data);
            free(clut_green.data);
            free(clut_blue.data);
            free(clut_alpha.data);
        }
    }

    free(workingFloats);
}

- (NSPoint)convertPointFromModelVector:(NIVector)vector
{
    return self.convertPointFromModelVectorBlock(vector);
}

- (NIVector)convertPointToModelVector:(NSPoint)point
{
    return self.convertPointToModelVectorBlock(point);
}


@end


@implementation NIFloatImageRep (DCMPixAndVolume)

- (void)getOrientation:(float[6])orientation
{
    double doubleOrientation[6];
    NSInteger i;

    [self getOrientationDouble:doubleOrientation];

    for (i = 0; i < 6; i++) {
        orientation[i] = doubleOrientation[i];
    }
}

- (void)getOrientationDouble:(double[6])orientation
{
    NIVector xBasis;
    NIVector yBasis;

    xBasis = NIVectorNormalize(NIVectorMake(_imageToModelTransform.m11, _imageToModelTransform.m12, _imageToModelTransform.m13));
    yBasis = NIVectorNormalize(NIVectorMake(_imageToModelTransform.m21, _imageToModelTransform.m22, _imageToModelTransform.m23));

    orientation[0] = xBasis.x; orientation[1] = xBasis.y; orientation[2] = xBasis.z;
    orientation[3] = yBasis.x; orientation[4] = yBasis.y; orientation[5] = yBasis.z;
}

- (float)originX
{
    return _imageToModelTransform.m41;
}

- (float)originY
{
    return _imageToModelTransform.m42;
}

- (float)originZ
{
    return _imageToModelTransform.m43;
}

@end

@implementation NIVolumeData(NIFloatImageRepAdditions)
- (NIFloatImageRep *)floatImageRepForSliceAtIndex:(NSUInteger)z
{
    NIFloatImageRep *sliceImageRep;
    NSData *sliceData;

    if (z >= _pixelsDeep) {
        [NSException raise:@"NIVolumeData Out Of Bounds" format:@"z is out of bounds"];
    }

    NIVolumeDataInlineBuffer inlineBuffer;

    [self acquireInlineBuffer:&inlineBuffer];
    const float *floatPtr = NIVolumeDataFloatBytes(&inlineBuffer);

    if (z == 0 && _pixelsDeep == 1) {
        sliceData = [self floatData];
    } else {
        sliceData = [NSData dataWithBytes:floatPtr + (self.pixelsWide*self.pixelsHigh*z) length:self.pixelsWide * self.pixelsHigh * sizeof(float)];
    }
    sliceImageRep = [[NIFloatImageRep alloc] initWithData:sliceData pixelsWide:self.pixelsWide pixelsHigh:self.pixelsHigh];
    sliceImageRep.sliceThickness = self.pixelSpacingZ;
    sliceImageRep.imageToModelTransform = NIAffineTransformConcat(NIAffineTransformMakeTranslation(0.0, 0.0, (CGFloat)z), NIAffineTransformInvert(_modelToVoxelTransform));

    if (self.curved) {
        NIVector (^convertVolumeVectorFromModelVectorBlock)(NIVector) = self.convertVolumeVectorFromModelVectorBlock;
        NIVector (^convertVolumeVectorToModelVectorBlock)(NIVector) = self.convertVolumeVectorToModelVectorBlock;

        sliceImageRep.convertPointFromModelVectorBlock = ^NSPoint(NIVector vector) {return NSPointFromNIVector(convertVolumeVectorFromModelVectorBlock(vector));};
        sliceImageRep.convertPointToModelVectorBlock = ^NIVector(NSPoint point) {return convertVolumeVectorToModelVectorBlock(NIVectorMake(point.x, point.y, z));};
        sliceImageRep.curved = YES;
    }

    return [sliceImageRep autorelease];
}

@end

NS_ASSUME_NONNULL_END


