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

/*=========================================================================
 Program:   OsiriX

 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL

 See http://www.osirix-viewer.com/copyright.html for details.

 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import "NIUnsignedInt16ImageRep.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NIUnsignedInt16ImageRep

@synthesize windowWidth = _windowWidth;
@synthesize windowLevel = _windowLevel;

@synthesize offset = _offset;
@synthesize slope = _slope;
@synthesize pixelSpacingX = _pixelSpacingX;
@synthesize pixelSpacingY = _pixelSpacingY;
@synthesize sliceThickness = _sliceThickness;
@synthesize imageToModelTransform = _imageToModelTransform;

- (nullable instancetype)initWithData:(nullable uint16_t *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh
{
    if ( (self = [super init]) ) {
        if (data == NULL) {
            _unsignedInt16Data = malloc(sizeof(uint16_t) * pixelsWide * pixelsHigh);
            _freeWhenDone = YES;
            if (_unsignedInt16Data == NULL) {
                [self autorelease];
                return nil;
            }
        } else {
            _unsignedInt16Data = data;
        }
        
        [self setPixelsWide:pixelsWide];
        [self setPixelsHigh:pixelsHigh];
        [self setSize:NSMakeSize(pixelsWide, pixelsHigh)];
        _offset = 0;
        _slope = 1;
        _imageToModelTransform = NIAffineTransformIdentity;
    }
    
    return self;
}

- (void)dealloc
{
    if (_freeWhenDone) {
        free(_unsignedInt16Data);
    }
    
    [super dealloc];
}

-(BOOL)draw
{
    assert(false); // I haven't tested the next few lines yet...
    
     unsigned char* bdp[1] = {(unsigned char*)self.unsignedInt16Data};
     NSBitmapImageRep* bitmap = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:bdp pixelsWide:self.pixelsWide pixelsHigh:self.pixelsHigh bitsPerSample:sizeof(uint16)*8 samplesPerPixel:1
                                                                          hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bitmapFormat:0 bytesPerRow:sizeof(uint16)*self.pixelsWide bitsPerPixel:sizeof(uint16)*8] autorelease];
    return [bitmap draw];
}

- (uint16_t *)unsignedInt16Data
{
    return _unsignedInt16Data;
}

@end


@implementation NIUnsignedInt16ImageRep (DCMPixAndVolume)

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

@implementation NIVolumeData (NIUnsignedInt16ImageRepAdditions)

- (NIUnsignedInt16ImageRep *)unsignedInt16ImageRepForSliceAtIndex:(NSUInteger)z
{
    NIUnsignedInt16ImageRep *imageRep;
    vImage_Buffer floatBuffer = [self floatBufferForSliceAtIndex:z];
    vImage_Buffer unsignedInt16Buffer;

    imageRep = [[NIUnsignedInt16ImageRep alloc] initWithData:NULL pixelsWide:_pixelsWide pixelsHigh:_pixelsHigh];
    imageRep.pixelSpacingX = [self pixelSpacingX];
    imageRep.pixelSpacingY = [self pixelSpacingY];
    imageRep.sliceThickness = [self pixelSpacingZ];
    imageRep.imageToModelTransform = NIAffineTransformConcat(NIAffineTransformMakeTranslation(0.0, 0.0, (CGFloat)z), NIAffineTransformInvert(_modelToVoxelTransform));

    unsignedInt16Buffer.data = [imageRep unsignedInt16Data];
    unsignedInt16Buffer.height = _pixelsHigh;
    unsignedInt16Buffer.width = _pixelsWide;
    unsignedInt16Buffer.rowBytes = sizeof(uint16_t) * _pixelsWide;

    vImageConvert_FTo16U(&floatBuffer, &unsignedInt16Buffer, -1024, 1, 0);
    imageRep.slope = 1;
    imageRep.offset = -1024;

    return [imageRep autorelease];
}

@end

NS_ASSUME_NONNULL_END

