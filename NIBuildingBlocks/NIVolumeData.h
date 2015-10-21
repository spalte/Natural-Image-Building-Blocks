//  Copyright (c) 2015 OsiriX Foundation
//  Copyright (c) 2015 Spaltenstein Natural Image
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
#import <Accelerate/Accelerate.h>
#import "NIGeometry.h"

@class NIUnsignedInt16ImageRep;

CF_EXTERN_C_BEGIN

typedef NS_ENUM(NSInteger, NIInterpolationMode) {
    NIInterpolationModeLinear,
    NIInterpolationModeNearestNeighbor,
    NIInterpolationModeCubic,

    NIInterpolationModeNone = 0xFFFFFF,
};

typedef struct { // build one of these on the stack and then use -[NIVolumeData aquireInlineBuffer:] to initialize it.
    const float *floatBytes;

    float outOfBoundsValue;

    NSUInteger pixelsWide;
    NSUInteger pixelsHigh;
    NSUInteger pixelsDeep;

    NSUInteger pixelsWideTimesPixelsHigh; // just in the interest of not calculating this a million times...

    NIAffineTransform volumeTransform;
} NIVolumeDataInlineBuffer;

// Interface to the data
@interface NIVolumeData : NSObject <NSCopying> {
    NSData *_floatData;
    float _outOfBoundsValue;

    NSUInteger _pixelsWide;
    NSUInteger _pixelsHigh;
    NSUInteger _pixelsDeep;

    NIAffineTransform _volumeTransform; // volumeTransform is the transform from Dicom (patient) space to pixel data

    BOOL _curved;
    NIVector (^_convertVolumeVectorToDICOMVectorBlock)(NIVector);
    NIVector (^_convertVolumeVectorFromDICOMVectorBlock)(NIVector);
}

// This is a utility function to help build an NIAffineTransform that places a volume in space
+ (NIAffineTransform)volumeTransformForOrigin:(NIVector)origin directionX:(NIVector)directionX pixelSpacingX:(CGFloat)pixelSpacingX directionY:(NIVector)directionY pixelSpacingY:(CGFloat)pixelSpacingY
                                     directionZ:(NIVector)directionZ pixelSpacingZ:(CGFloat)pixelSpacingZ;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithBytesNoCopy:(const float *)floatBytes pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
                    volumeTransform:(NIAffineTransform)volumeTransform outOfBoundsValue:(float)outOfBoundsValue freeWhenDone:(BOOL)freeWhenDone; // volumeTransform is the transform from Dicom (patient) space to pixel data

- (instancetype)initWithData:(NSData *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
             volumeTransform:(NIAffineTransform)volumeTransform outOfBoundsValue:(float)outOfBoundsValue NS_DESIGNATED_INITIALIZER; // volumeTransform is the transform from Dicom (patient) space to pixel data

- (instancetype)initWithData:(NSData *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
      volumeToDicomConverter:(NIVector (^)(NIVector volumeVector))volumeToDicomConverter dicomToVolumeConverter:(NIVector (^)(NIVector dicomVector))dicomToVolumeConverter
            outOfBoundsValue:(float)outOfBoundsValue NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithVolumeData:(NIVolumeData *)volumeData NS_DESIGNATED_INITIALIZER;

@property (readonly) NSUInteger pixelsWide;
@property (readonly) NSUInteger pixelsHigh;
@property (readonly) NSUInteger pixelsDeep;

@property (readonly, getter=isRectilinear) BOOL rectilinear;

@property (readonly) CGFloat minPixelSpacing; // the smallest pixel spacing in any direction;
@property (readonly) CGFloat pixelSpacingX;// mm/pixel
@property (readonly) CGFloat pixelSpacingY;
@property (readonly) CGFloat pixelSpacingZ;

@property (readonly) NIVector origin;
@property (readonly) NIVector directionX;
@property (readonly) NIVector directionY;
@property (readonly) NIVector directionZ;

@property (readonly) float outOfBoundsValue;

@property (readonly) NIAffineTransform volumeTransform; // volumeTransform is the transform from Dicom (patient) space to pixel data

@property (readonly, getter = isCurved) BOOL curved; // if the volume is curved the volumeTransform will be bogus, but the following properties will still work
@property (readonly, copy) NIVector (^convertVolumeVectorToDICOMVectorBlock)(NIVector);
@property (readonly, copy) NIVector (^convertVolumeVectorFromDICOMVectorBlock)(NIVector);

- (NIVector)convertVolumeVectorToDICOMVector:(NIVector)vector;
- (NIVector)convertVolumeVectorFromDICOMVector:(NIVector)vector;
@property (readonly, retain) NSData *floatData;

// will copy fill length*sizeof(float) bytes, the coordinates better be within the volume!!!
// a run a is a series of pixels in the x direction
- (BOOL)getFloatRun:(float *)buffer atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z length:(NSUInteger)length;

- (vImage_Buffer)floatBufferForSliceAtIndex:(NSUInteger)z;
- (NIUnsignedInt16ImageRep *)unsignedInt16ImageRepForSliceAtIndex:(NSUInteger)z;
- (NIVolumeData *)volumeDataForSliceAtIndex:(NSUInteger)z;

- (NIVolumeData *)volumeDataByApplyingTransform:(NIAffineTransform)transform;

// the first version of this function figures out the dimensions needed to fit the whole volume. Note that with the first version of this function the passed in transform may not
// be equal to the volumeTransform of the returned volumeData because a minimum cube of data needed to fit the was calculated. Any shift in the data is guaranteed to be a multiple
// of the basis vectors of the transform though.
- (instancetype)volumeDataResampledWithVolumeTransform:(NIAffineTransform)transform interpolationMode:(NIInterpolationMode)interpolationsMode;
- (instancetype)volumeDataResampledWithVolumeTransform:(NIAffineTransform)transform pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
                                     interpolationMode:(NIInterpolationMode)interpolationsMode;

- (CGFloat)floatAtPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z;
- (CGFloat)linearInterpolatedFloatAtDicomVector:(NIVector)vector; // these are slower, use the inline buffer if you care about speed
- (CGFloat)nearestNeighborInterpolatedFloatAtDicomVector:(NIVector)vector; // these are slower, use the inline buffer if you care about speed
- (CGFloat)cubicInterpolatedFloatAtDicomVector:(NIVector)vector; // these are slower, use the inline buffer if you care about speed

- (BOOL)aquireInlineBuffer:(NIVolumeDataInlineBuffer *)inlineBuffer; // always return YES

// if you need to calculate a width to use for thick slab that covers the entire volume, calculate the minumum width for a given slice
// don't just give this likely-to-be-larger-than-needed value.
- (CGFloat)maximumDiagonal __deprecated;

// not done yet, will crash if given vectors that are outside of the volume
- (NSUInteger)tempBufferSizeForNumVectors:(NSUInteger)numVectors;
- (void)linearInterpolateVolumeVectors:(NIVectorArray)volumeVectors outputValues:(float *)outputValues numVectors:(NSUInteger)numVectors tempBuffer:(void *)tempBuffer;
// end not done

- (BOOL)isEqual:(id)object;

@end

// TODO: what should we do with the next few commented-out lines?
//@interface NIVolumeData (DCMPixAndVolume) // make a nice clean interface between the rest of of OsiriX that deals with pixlist and all their complications, and fill out our convenient data structure.
//
//- (id) initWithWithPixList:(NSArray *)pixList volume:(NSData *)volume;
//
//- (void)getOrientation:(float[6])orientation;
//- (void)getOrientationDouble:(double[6])orientation;
//
//@property (readonly) float originX;
//@property (readonly) float originY;
//@property (readonly) float originZ;
//
//@end

CF_INLINE const float* NIVolumeDataFloatBytes(NIVolumeDataInlineBuffer *inlineBuffer)
{
    return inlineBuffer->floatBytes;
}


CF_INLINE float NIVolumeDataGetFloatAtPixelCoordinate(NIVolumeDataInlineBuffer *inlineBuffer, NSInteger x, NSInteger y, NSInteger z)
{
    bool outside;

    if (inlineBuffer->floatBytes) {
        outside = false;

        outside |= x < 0;
        outside |= y < 0;
        outside |= z < 0;
        outside |= x >= inlineBuffer->pixelsWide;
        outside |= y >= inlineBuffer->pixelsHigh;
        outside |= z >= inlineBuffer->pixelsDeep;

        if (!outside) {
            return (inlineBuffer->floatBytes)[x + y*inlineBuffer->pixelsWide + z*inlineBuffer->pixelsWideTimesPixelsHigh];
        } else {
            return inlineBuffer->outOfBoundsValue;
        }
    } else {
        return 0;
    }
}

CF_INLINE NSInteger NIVolumeDataIndexAtCoordinate(NSInteger x, NSInteger y, NSInteger z, NSUInteger pixelsWide, NSInteger pixelsHigh, NSInteger pixelsDeep, NSInteger outOfBoundsIndex)
{
    if (x < 0 || x >= pixelsWide ||
        y < 0 || y >= pixelsHigh ||
        z < 0 || z >= pixelsDeep) {
        return outOfBoundsIndex;
    }
    return x + pixelsWide*(y + pixelsHigh*z);
}

CF_INLINE NSInteger NIVolumeDataUncheckedIndexAtCoordinate(NSInteger x, NSInteger y, NSInteger z, NSUInteger pixelsWide, NSInteger pixelsHigh, NSInteger pixelsDeep)
{
    return x + pixelsWide*(y + pixelsHigh*z);
}

CF_INLINE void NIVolumeDataGetLinearIndexes(NSInteger linearIndexes[8], NSInteger x, NSInteger y, NSInteger z, NSUInteger pixelsWide, NSInteger pixelsHigh, NSInteger pixelsDeep, NSInteger outOfBoundsIndex)
{
    if (x < 0 || y < 0 || z < 0 || x >= pixelsWide-1 || y >= pixelsHigh-1 || z >= pixelsDeep-1) {
        for (int i = 0; i < 2; ++i) {
            for (int j = 0; j < 2; ++j) {
                for (int k = 0; k < 2; ++k) {
                    linearIndexes[i+2*(j+2*k)] = NIVolumeDataIndexAtCoordinate(x+i, y+j, z+k, pixelsWide, pixelsHigh, pixelsDeep, outOfBoundsIndex);
                }
            }
        }
    } else {
        for (int i = 0; i < 2; ++i) {
            for (int j = 0; j < 2; ++j) {
                for (int k = 0; k < 2; ++k) {
                    linearIndexes[i+2*(j+2*k)] = NIVolumeDataUncheckedIndexAtCoordinate(x+i, y+j, z+k, pixelsWide, pixelsHigh, pixelsDeep);
                }
            }
        }
    }
}

CF_INLINE float NIVolumeDataLinearInterpolatedFloatAtVolumeCoordinate(NIVolumeDataInlineBuffer *inlineBuffer, CGFloat x, CGFloat y, CGFloat z) // coordinate in the pixel space
{

#if CGFLOAT_IS_DOUBLE
    const CGFloat x_floor = floor(x);
    const CGFloat y_floor = floor(y);
    const CGFloat z_floor = floor(z);
#else
    const CGFloat x_floor = floorf(x);
    const CGFloat y_floor = floorf(y);
    const CGFloat z_floor = floorf(z);
#endif

    // this is a horible hack, but it works
    // what I'm doing is looking at memory addresses to find an index into inlineBuffer->floatBytes that would jump out of
    // the array and instead point to inlineBuffer->outOfBoundsValue which is on the stack
    // This relies on both inlineBuffer->floatBytes and inlineBuffer->outOfBoundsValue being on a sizeof(float) boundry
    NSInteger outOfBoundsIndex = (((NSInteger)&(inlineBuffer->outOfBoundsValue)) - ((NSInteger)inlineBuffer->floatBytes)) / sizeof(float);

    NSInteger linearIndexes[8];
    NIVolumeDataGetLinearIndexes(linearIndexes, x_floor, y_floor, z_floor, inlineBuffer->pixelsWide, inlineBuffer->pixelsHigh, inlineBuffer->pixelsDeep, outOfBoundsIndex);

    const float *floatBytes = inlineBuffer->floatBytes;

    const CGFloat dx1 = x-x_floor;
    const CGFloat dy1 = y-y_floor;
    const CGFloat dz1 = z-z_floor;

    const CGFloat dx0 = 1.0 - dx1;
    const CGFloat dy0 = 1.0 - dy1;
    const CGFloat dz0 = 1.0 - dz1;

    return (dz0*(dy0*(dx0*floatBytes[linearIndexes[0+2*(0+2*0)]] + dx1*floatBytes[linearIndexes[1+2*(0+2*0)]]) +
                 dy1*(dx0*floatBytes[linearIndexes[0+2*(1+2*0)]] + dx1*floatBytes[linearIndexes[1+2*(1+2*0)]]))) +
           (dz1*(dy0*(dx0*floatBytes[linearIndexes[0+2*(0+2*1)]] + dx1*floatBytes[linearIndexes[1+2*(0+2*1)]]) +
                 dy1*(dx0*floatBytes[linearIndexes[0+2*(1+2*1)]] + dx1*floatBytes[linearIndexes[1+2*(1+2*1)]])));
}

CF_INLINE float NIVolumeDataNearestNeighborInterpolatedFloatAtVolumeCoordinate(NIVolumeDataInlineBuffer *inlineBuffer, CGFloat x, CGFloat y, CGFloat z) // coordinate in the pixel space
{
#if CGFLOAT_IS_DOUBLE
    NSInteger roundX = round(x);
    NSInteger roundY = round(y);
    NSInteger roundZ = round(z);
#else
    NSInteger roundX = roundf(x);
    NSInteger roundY = roundf(y);
    NSInteger roundZ = roundf(z);
#endif

    return NIVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, roundX, roundY, roundZ);
}

CF_INLINE void NIVolumeDataGetCubicIndexes(NSInteger cubicIndexes[64], NSInteger x, NSInteger y, NSInteger z, NSUInteger pixelsWide, NSInteger pixelsHigh, NSInteger pixelsDeep, NSInteger outOfBoundsIndex)
{
    if (x <= 0 || y <= 0 || z <= 0 || x >= pixelsWide-2 || y >= pixelsHigh-2 || z >= pixelsDeep-2) {
        for (int i = 0; i < 4; ++i) {
            for (int j = 0; j < 4; ++j) {
                for (int k = 0; k < 4; ++k) {
                    cubicIndexes[i+4*(j+4*k)] = NIVolumeDataIndexAtCoordinate(x+i-1, y+j-1, z+k-1, pixelsWide, pixelsHigh, pixelsDeep, outOfBoundsIndex);
                }
            }
        }
    } else {
        for (int i = 0; i < 4; ++i) {
            for (int j = 0; j < 4; ++j) {
                for (int k = 0; k < 4; ++k) {
                    cubicIndexes[i+4*(j+4*k)] = NIVolumeDataUncheckedIndexAtCoordinate(x+i-1, y+j-1, z+k-1, pixelsWide, pixelsHigh, pixelsDeep);
                }
            }
        }
    }
}

CF_INLINE float NIVolumeDataCubicInterpolatedFloatAtVolumeCoordinate(NIVolumeDataInlineBuffer *inlineBuffer, CGFloat x, CGFloat y, CGFloat z) // coordinate in the pixel space
{
#if CGFLOAT_IS_DOUBLE
    const CGFloat x_floor = floor(x);
    const CGFloat y_floor = floor(y);
    const CGFloat z_floor = floor(z);
#else
    const CGFloat x_floor = floorf(x);
    const CGFloat y_floor = floorf(y);
    const CGFloat z_floor = floorf(z);
#endif

    const CGFloat dx = x-x_floor;
    const CGFloat dy = y-y_floor;
    const CGFloat dz = z-z_floor;

    const CGFloat dxx = dx*dx;
    const CGFloat dxxx = dxx*dx;

    const CGFloat dyy = dy*dy;
    const CGFloat dyyy = dyy*dy;

    const CGFloat dzz = dz*dz;
    const CGFloat dzzz = dzz*dz;

    const CGFloat wx0 = 0.5 * (    - dx + 2.0*dxx -       dxxx);
    const CGFloat wx1 = 0.5 * (2.0      - 5.0*dxx + 3.0 * dxxx);
    const CGFloat wx2 = 0.5 * (      dx + 4.0*dxx - 3.0 * dxxx);
    const CGFloat wx3 = 0.5 * (         -     dxx +       dxxx);

    const CGFloat wy0 = 0.5 * (    - dy + 2.0*dyy -       dyyy);
    const CGFloat wy1 = 0.5 * (2.0      - 5.0*dyy + 3.0 * dyyy);
    const CGFloat wy2 = 0.5 * (      dy + 4.0*dyy - 3.0 * dyyy);
    const CGFloat wy3 = 0.5 * (         -     dyy +       dyyy);

    const CGFloat wz0 = 0.5 * (    - dz + 2.0*dzz -       dzzz);
    const CGFloat wz1 = 0.5 * (2.0      - 5.0*dzz + 3.0 * dzzz);
    const CGFloat wz2 = 0.5 * (      dz + 4.0*dzz - 3.0 * dzzz);
    const CGFloat wz3 = 0.5 * (         -     dzz +       dzzz);

    // this is a horible hack, but it works
    // what I'm doing is looking at memory addresses to find an index into inlineBuffer->floatBytes that would jump out of
    // the array and instead point to inlineBuffer->outOfBoundsValue which is on the stack
    // This relies on both inlineBuffer->floatBytes and inlineBuffer->outOfBoundsValue being on a sizeof(float) boundry
    NSInteger outOfBoundsIndex = (((NSInteger)&(inlineBuffer->outOfBoundsValue)) - ((NSInteger)inlineBuffer->floatBytes)) / sizeof(float);

    NSInteger cubicIndexes[64];
    NIVolumeDataGetCubicIndexes(cubicIndexes, x_floor, y_floor, z_floor, inlineBuffer->pixelsWide, inlineBuffer->pixelsHigh, inlineBuffer->pixelsDeep, outOfBoundsIndex);

    const float *floatBytes = inlineBuffer->floatBytes;

    return wz0*(
                wy0*(wx0 * floatBytes[cubicIndexes[0+4*(0+4*0)]] + wx1 * floatBytes[cubicIndexes[1+4*(0+4*0)]] +  wx2 * floatBytes[cubicIndexes[2+4*(0+4*0)]] + wx3 * floatBytes[cubicIndexes[3+4*(0+4*0)]]) +
                wy1*(wx0 * floatBytes[cubicIndexes[0+4*(1+4*0)]] + wx1 * floatBytes[cubicIndexes[1+4*(1+4*0)]] +  wx2 * floatBytes[cubicIndexes[2+4*(1+4*0)]] + wx3 * floatBytes[cubicIndexes[3+4*(1+4*0)]]) +
                wy2*(wx0 * floatBytes[cubicIndexes[0+4*(2+4*0)]] + wx1 * floatBytes[cubicIndexes[1+4*(2+4*0)]] +  wx2 * floatBytes[cubicIndexes[2+4*(2+4*0)]] + wx3 * floatBytes[cubicIndexes[3+4*(2+4*0)]]) +
                wy3*(wx0 * floatBytes[cubicIndexes[0+4*(3+4*0)]] + wx1 * floatBytes[cubicIndexes[1+4*(3+4*0)]] +  wx2 * floatBytes[cubicIndexes[2+4*(3+4*0)]] + wx3 * floatBytes[cubicIndexes[3+4*(3+4*0)]])
                ) +
    wz1*(
         wy0*(wx0 * floatBytes[cubicIndexes[0+4*(0+4*1)]] + wx1 * floatBytes[cubicIndexes[1+4*(0+4*1)]] +  wx2 * floatBytes[cubicIndexes[2+4*(0+4*1)]] + wx3 * floatBytes[cubicIndexes[3+4*(0+4*1)]]) +
         wy1*(wx0 * floatBytes[cubicIndexes[0+4*(1+4*1)]] + wx1 * floatBytes[cubicIndexes[1+4*(1+4*1)]] +  wx2 * floatBytes[cubicIndexes[2+4*(1+4*1)]] + wx3 * floatBytes[cubicIndexes[3+4*(1+4*1)]]) +
         wy2*(wx0 * floatBytes[cubicIndexes[0+4*(2+4*1)]] + wx1 * floatBytes[cubicIndexes[1+4*(2+4*1)]] +  wx2 * floatBytes[cubicIndexes[2+4*(2+4*1)]] + wx3 * floatBytes[cubicIndexes[3+4*(2+4*1)]]) +
         wy3*(wx0 * floatBytes[cubicIndexes[0+4*(3+4*1)]] + wx1 * floatBytes[cubicIndexes[1+4*(3+4*1)]] +  wx2 * floatBytes[cubicIndexes[2+4*(3+4*1)]] + wx3 * floatBytes[cubicIndexes[3+4*(3+4*1)]])
         ) +
    wz2*(
         wy0*(wx0 * floatBytes[cubicIndexes[0+4*(0+4*2)]] + wx1 * floatBytes[cubicIndexes[1+4*(0+4*2)]] +  wx2 * floatBytes[cubicIndexes[2+4*(0+4*2)]] + wx3 * floatBytes[cubicIndexes[3+4*(0+4*2)]]) +
         wy1*(wx0 * floatBytes[cubicIndexes[0+4*(1+4*2)]] + wx1 * floatBytes[cubicIndexes[1+4*(1+4*2)]] +  wx2 * floatBytes[cubicIndexes[2+4*(1+4*2)]] + wx3 * floatBytes[cubicIndexes[3+4*(1+4*2)]]) +
         wy2*(wx0 * floatBytes[cubicIndexes[0+4*(2+4*2)]] + wx1 * floatBytes[cubicIndexes[1+4*(2+4*2)]] +  wx2 * floatBytes[cubicIndexes[2+4*(2+4*2)]] + wx3 * floatBytes[cubicIndexes[3+4*(2+4*2)]]) +
         wy3*(wx0 * floatBytes[cubicIndexes[0+4*(3+4*2)]] + wx1 * floatBytes[cubicIndexes[1+4*(3+4*2)]] +  wx2 * floatBytes[cubicIndexes[2+4*(3+4*2)]] + wx3 * floatBytes[cubicIndexes[3+4*(3+4*2)]])
         ) +
    wz3*(
         wy0*(wx0 * floatBytes[cubicIndexes[0+4*(0+4*3)]] + wx1 * floatBytes[cubicIndexes[1+4*(0+4*3)]] +  wx2 * floatBytes[cubicIndexes[2+4*(0+4*3)]] + wx3 * floatBytes[cubicIndexes[3+4*(0+4*3)]]) +
         wy1*(wx0 * floatBytes[cubicIndexes[0+4*(1+4*3)]] + wx1 * floatBytes[cubicIndexes[1+4*(1+4*3)]] +  wx2 * floatBytes[cubicIndexes[2+4*(1+4*3)]] + wx3 * floatBytes[cubicIndexes[3+4*(1+4*3)]]) +
         wy2*(wx0 * floatBytes[cubicIndexes[0+4*(2+4*3)]] + wx1 * floatBytes[cubicIndexes[1+4*(2+4*3)]] +  wx2 * floatBytes[cubicIndexes[2+4*(2+4*3)]] + wx3 * floatBytes[cubicIndexes[3+4*(2+4*3)]]) +
         wy3*(wx0 * floatBytes[cubicIndexes[0+4*(3+4*3)]] + wx1 * floatBytes[cubicIndexes[1+4*(3+4*3)]] +  wx2 * floatBytes[cubicIndexes[2+4*(3+4*3)]] + wx3 * floatBytes[cubicIndexes[3+4*(3+4*3)]])
         );
}

__attribute__((deprecated("convert the vector using [-[NIVolumeData convertVolumeVectorFromDICOMVector:] first")))
CF_INLINE float NIVolumeDataLinearInterpolatedFloatAtDicomVector(NIVolumeDataInlineBuffer *inlineBuffer, NIVector vector) // coordinate in mm dicom space
{
    vector = NIVectorApplyTransform(vector, inlineBuffer->volumeTransform);
    return NIVolumeDataLinearInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

__attribute__((deprecated("convert the vector using [-[NIVolumeData convertVolumeVectorFromDICOMVector:] first")))
CF_INLINE float NIVolumeDataNearestNeighborInterpolatedFloatAtDicomVector(NIVolumeDataInlineBuffer *inlineBuffer, NIVector vector) // coordinate in mm dicom space
{
    vector = NIVectorApplyTransform(vector, inlineBuffer->volumeTransform);
    return NIVolumeDataNearestNeighborInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

__attribute__((deprecated("convert the vector using [-[NIVolumeData convertVolumeVectorFromDICOMVector:] first")))
CF_INLINE float NIVolumeDataCubicInterpolatedFloatAtDicomVector(NIVolumeDataInlineBuffer *inlineBuffer, NIVector vector) // coordinate in mm dicom space
{
    vector = NIVectorApplyTransform(vector, inlineBuffer->volumeTransform);
    return NIVolumeDataCubicInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

CF_INLINE float NIVolumeDataLinearInterpolatedFloatAtVolumeVector(NIVolumeDataInlineBuffer *inlineBuffer, NIVector vector)
{
    return NIVolumeDataLinearInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

CF_INLINE float NIVolumeDataNearestNeighborInterpolatedFloatAtVolumeVector(NIVolumeDataInlineBuffer *inlineBuffer, NIVector vector)
{
    return NIVolumeDataNearestNeighborInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

CF_INLINE float NIVolumeDataCubicInterpolatedFloatAtVolumeVector(NIVolumeDataInlineBuffer *inlineBuffer, NIVector vector)
{
    return NIVolumeDataCubicInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

CF_EXTERN_C_END

