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

#import <Accelerate/Accelerate.h>

#import "NIBBVolumeData.h"
#import "NIBBUnsignedInt16ImageRep.h"
#import "NIBBGenerator.h"
#import "NIBBGeneratorRequest.h"

@interface NIBBVolumeData ()

- (BOOL)_testOrientationMatrix:(double[9])orientation; // returns YES if the orientation matrix's determinant is non-zero

@property (nonatomic, readonly, assign) float* floatBytes;

@end


@implementation NIBBVolumeData

@synthesize outOfBoundsValue = _outOfBoundsValue;
@synthesize pixelsWide = _pixelsWide;
@synthesize pixelsHigh = _pixelsHigh;
@synthesize pixelsDeep = _pixelsDeep;
@synthesize volumeTransform = _volumeTransform;
@synthesize floatData = _floatData;

+ (NIBBAffineTransform)volumeDataForOrigin:(NIBBVector)origin directionX:(NIBBVector)directionX pixelSpacingX:(CGFloat)pixelSpacingX directionY:(NIBBVector)directionY pixelSpacingY:(CGFloat)pixelSpacingY
                              directionZ:(NIBBVector)directionZ pixelSpacingZ:(CGFloat)pixelSpacingZ
{
    directionX = NIBBVectorNormalize(directionX);
    directionY = NIBBVectorNormalize(directionY);
    directionZ = NIBBVectorNormalize(directionZ);

    NIBBAffineTransform transform = NIBBAffineTransformIdentity;
    transform.m11 = directionX.x * pixelSpacingX;
    transform.m12 = directionX.y * pixelSpacingX;
    transform.m13 = directionX.z * pixelSpacingX;
    transform.m21 = directionY.x * pixelSpacingY;
    transform.m22 = directionY.y * pixelSpacingY;
    transform.m23 = directionY.z * pixelSpacingY;
    transform.m31 = directionZ.x * pixelSpacingZ;
    transform.m32 = directionZ.y * pixelSpacingZ;
    transform.m33 = directionZ.z * pixelSpacingZ;
    transform.m41 = origin.x;
    transform.m42 = origin.y;
    transform.m43 = origin.z;

    return NIBBAffineTransformInvert(transform);
}

- (instancetype)initWithBytesNoCopy:(const float *)floatBytes pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
                    volumeTransform:(NIBBAffineTransform)volumeTransform outOfBoundsValue:(float)outOfBoundsValue freeWhenDone:(BOOL)freeWhenDone // volumeTransform is the transform from Dicom (patient) space to pixel data
{
    return [self initWithData:[NSData dataWithBytesNoCopy:(void *)floatBytes length:sizeof(float) * pixelsWide * pixelsHigh * pixelsDeep freeWhenDone:freeWhenDone]
                   pixelsWide:pixelsWide pixelsHigh:pixelsHigh pixelsDeep:pixelsDeep volumeTransform:volumeTransform outOfBoundsValue:outOfBoundsValue];
}

- (instancetype)initWithData:(NSData *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
             volumeTransform:(NIBBAffineTransform)volumeTransform outOfBoundsValue:(float)outOfBoundsValue // volumeTransform is the transform from Dicom (patient) space to pixel data
{
    if ( (self = [super init]) ) {
        _floatData = [data retain];
        _outOfBoundsValue = outOfBoundsValue;
        _pixelsWide = pixelsWide;
        _pixelsHigh = pixelsHigh;
        _pixelsDeep = pixelsDeep;
        _volumeTransform = volumeTransform;
    }
    return self;
}

- (instancetype)initWithVolumeData:(NIBBVolumeData *)volumeData
{
    if ( (self = [super init]) ) {
        _floatData = [volumeData->_floatData retain];
        _outOfBoundsValue = volumeData->_outOfBoundsValue;
        _pixelsWide = volumeData->_pixelsWide;
        _pixelsHigh = volumeData->_pixelsHigh;
        _pixelsDeep = volumeData->_pixelsDeep;
        _volumeTransform = volumeData->_volumeTransform;
    }
    return self;
}

- (void)dealloc
{
    [_floatData release];
    _floatData = nil;
    [super dealloc];
}

- (BOOL)isRectilinear
{
    return NIBBAffineTransformIsRectilinear(_volumeTransform);
}

- (CGFloat)minPixelSpacing
{
    return MIN(MIN(self.pixelSpacingX, self.pixelSpacingY), self.pixelSpacingZ);
}

- (CGFloat)pixelSpacingX
{
    NIBBVector zero;
    NIBBAffineTransform inverseTransform;

    if (self.rectilinear) {
        return 1.0/_volumeTransform.m11;
    } else {
        inverseTransform = NIBBAffineTransformInvert(_volumeTransform);
        zero = NIBBVectorApplyTransform(NIBBVectorZero, inverseTransform);
        return NIBBVectorDistance(zero, NIBBVectorApplyTransform(NIBBVectorMake(1.0, 0.0, 0.0), inverseTransform));
    }
}

- (CGFloat)pixelSpacingY
{
    NIBBVector zero;
    NIBBAffineTransform inverseTransform;

    if (self.rectilinear) {
        return 1.0/_volumeTransform.m22;
    } else {
        inverseTransform = NIBBAffineTransformInvert(_volumeTransform);
        zero = NIBBVectorApplyTransform(NIBBVectorZero, inverseTransform);
        return NIBBVectorDistance(zero, NIBBVectorApplyTransform(NIBBVectorMake(0.0, 1.0, 0.0), inverseTransform));
    }
}

- (CGFloat)pixelSpacingZ
{
    NIBBVector zero;
    NIBBAffineTransform inverseTransform;

    if (self.rectilinear) {
        return 1.0/_volumeTransform.m33;
    } else {
        inverseTransform = NIBBAffineTransformInvert(_volumeTransform);
        zero = NIBBVectorApplyTransform(NIBBVectorZero, inverseTransform);
        return NIBBVectorDistance(zero, NIBBVectorApplyTransform(NIBBVectorMake(0.0, 0.0, 1.0), inverseTransform));
    }
}

- (float *)floatBytes
{
    return (float *)[_floatData bytes];
}

// will copy fill length*sizeof(float) bytes
- (BOOL)getFloatRun:(float *)buffer atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z length:(NSUInteger)length
{
    assert(x < _pixelsWide);
    assert(y < _pixelsHigh);
    assert(z < _pixelsDeep);
    assert(x + length < _pixelsWide);

    memcpy(buffer, &(self.floatBytes[x + y*_pixelsWide + z*_pixelsWide*_pixelsHigh]), length * sizeof(float));
    return YES;
}

- (BOOL)isCurved
{
    return NO;
}

- (NIBBVector (^)(NIBBVector))convertVolumeVectorToDICOMVectorBlock
{
    NIBBAffineTransform inverseVolumeTransform = NIBBAffineTransformInvert([self volumeTransform]);

    return [[^NIBBVector(NIBBVector vector) {
        return NIBBVectorApplyTransform(vector, inverseVolumeTransform);
    } copy] autorelease];
}

- (NIBBVector (^)(NIBBVector))convertVolumeVectorFromDICOMVectorBlock
{
    NIBBAffineTransform volumeTransform = [self volumeTransform];

    return [[^NIBBVector(NIBBVector vector) {
        return NIBBVectorApplyTransform(vector, volumeTransform);
    } copy] autorelease];
}

- (NIBBVector)convertVolumeVectorToDICOMVector:(NIBBVector)vector
{
    return [self convertVolumeVectorToDICOMVectorBlock](vector);
}

- (NIBBVector)convertVolumeVectorFromDICOMVector:(NIBBVector)vector
{
    return [self convertVolumeVectorFromDICOMVectorBlock](vector);
}

- (NIBBUnsignedInt16ImageRep *)unsignedInt16ImageRepForSliceAtIndex:(NSUInteger)z
{
    NIBBUnsignedInt16ImageRep *imageRep;
    uint16_t *unsignedInt16Data;
    vImage_Buffer floatBuffer;
    vImage_Buffer unsignedInt16Buffer;

    imageRep = [[NIBBUnsignedInt16ImageRep alloc] initWithData:NULL pixelsWide:_pixelsWide pixelsHigh:_pixelsHigh];
    imageRep.pixelSpacingX = [self pixelSpacingX];
    imageRep.pixelSpacingY = [self pixelSpacingY];
    imageRep.sliceThickness = [self pixelSpacingZ];
    imageRep.imageToDicomTransform = NIBBAffineTransformConcat(NIBBAffineTransformMakeTranslation(0.0, 0.0, (CGFloat)z), NIBBAffineTransformInvert(_volumeTransform));

    unsignedInt16Data = [imageRep unsignedInt16Data];

    floatBuffer.data = (void *)self.floatBytes + (_pixelsWide * _pixelsHigh * sizeof(float) * z);
    floatBuffer.height = _pixelsHigh;
    floatBuffer.width = _pixelsWide;
    floatBuffer.rowBytes = sizeof(float) * _pixelsWide;

    unsignedInt16Buffer.data = unsignedInt16Data;
    unsignedInt16Buffer.height = _pixelsHigh;
    unsignedInt16Buffer.width = _pixelsWide;
    unsignedInt16Buffer.rowBytes = sizeof(uint16_t) * _pixelsWide;

    vImageConvert_FTo16U(&floatBuffer, &unsignedInt16Buffer, -1024, 1, 0);
    imageRep.slope = 1;
    imageRep.offset = -1024;

    return [imageRep autorelease];
}

- (NIBBVolumeData *)volumeDataForSliceAtIndex:(NSUInteger)z
{
    NIBBVolumeData *sliceVolume;
    NIBBAffineTransform sliceVolumeTransform;
    NSData *sliceData;

    sliceVolumeTransform = NIBBAffineTransformConcat(_volumeTransform, NIBBAffineTransformMakeTranslation(0, 0, -z));

    sliceData = [NSData dataWithBytes:self.floatBytes + (_pixelsWide*_pixelsHigh*z) length:_pixelsWide * _pixelsHigh * sizeof(float)];
    sliceVolume = [[[self class] alloc] initWithData:sliceData pixelsWide:_pixelsWide pixelsHigh:_pixelsHigh pixelsDeep:1 volumeTransform:sliceVolumeTransform outOfBoundsValue:_outOfBoundsValue];

    return [sliceVolume autorelease];
}

- (BOOL)getFloat:(float *)floatPtr atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z
{
    NIBBVolumeDataInlineBuffer inlineBuffer;

    [self aquireInlineBuffer:&inlineBuffer];
    *floatPtr = NIBBVolumeDataGetFloatAtPixelCoordinate(&inlineBuffer, x, y, z);
    return YES;
}

- (BOOL)getLinearInterpolatedFloat:(float *)floatPtr atDicomVector:(NIBBVector)vector
{
    NIBBVolumeDataInlineBuffer inlineBuffer;
    [self aquireInlineBuffer:&inlineBuffer];
    *floatPtr = NIBBVolumeDataLinearInterpolatedFloatAtDicomVector(&inlineBuffer, vector);
    return YES;
}

- (BOOL)getNearestNeighborInterpolatedFloat:(float *)floatPtr atDicomVector:(NIBBVector)vector
{
    NIBBVolumeDataInlineBuffer inlineBuffer;

    [self aquireInlineBuffer:&inlineBuffer];
    *floatPtr = NIBBVolumeDataNearestNeighborInterpolatedFloatAtDicomVector(&inlineBuffer, vector);
    return YES;
}

- (BOOL)getCubicInterpolatedFloat:(float *)floatPtr atDicomVector:(NIBBVector)vector
{
    NIBBVolumeDataInlineBuffer inlineBuffer;

    [self aquireInlineBuffer:&inlineBuffer];
    *floatPtr = NIBBVolumeDataCubicInterpolatedFloatAtDicomVector(&inlineBuffer, vector);
    return YES;
}


- (instancetype)volumeDataByApplyingTransform:(NIBBAffineTransform)transform;
{
    return [[[NIBBVolumeData alloc] initWithData:_floatData pixelsWide:_pixelsWide pixelsHigh:_pixelsHigh pixelsDeep:_pixelsDeep
                                volumeTransform:NIBBAffineTransformConcat(_volumeTransform, transform) outOfBoundsValue:_outOfBoundsValue] autorelease];
}

- (instancetype)volumeDataResampledWithVolumeTransform:(NIBBAffineTransform)transform interpolationMode:(NIBBInterpolationMode)interpolationsMode
{
    if (NIBBAffineTransformEqualToTransform(self.volumeTransform, transform)) {
        return self;
    }

    NIBBAffineTransform oringinalVoxelToDicomTransform = NIBBAffineTransformInvert(self.volumeTransform);
    NIBBAffineTransform originalVoxelToNewVoxelTransform = NIBBAffineTransformConcat(oringinalVoxelToDicomTransform, transform);

    NIBBVector minCorner = NIBBVectorZero;
    NIBBVector maxCorner = NIBBVectorZero;

    NIBBVector corner1 = NIBBVectorApplyTransform(NIBBVectorMake(0,                   0,                   0), originalVoxelToNewVoxelTransform);
    NIBBVector corner2 = NIBBVectorApplyTransform(NIBBVectorMake(self.pixelsWide - 1, 0,                   0), originalVoxelToNewVoxelTransform);
    NIBBVector corner3 = NIBBVectorApplyTransform(NIBBVectorMake(0,                   self.pixelsHigh - 1, 0), originalVoxelToNewVoxelTransform);
    NIBBVector corner4 = NIBBVectorApplyTransform(NIBBVectorMake(self.pixelsWide - 1, self.pixelsHigh - 1, 0), originalVoxelToNewVoxelTransform);
    NIBBVector corner5 = NIBBVectorApplyTransform(NIBBVectorMake(0,                   0,                   self.pixelsDeep - 1), originalVoxelToNewVoxelTransform);
    NIBBVector corner6 = NIBBVectorApplyTransform(NIBBVectorMake(self.pixelsWide - 1, 0,                   self.pixelsDeep - 1), originalVoxelToNewVoxelTransform);
    NIBBVector corner7 = NIBBVectorApplyTransform(NIBBVectorMake(0,                   self.pixelsHigh - 1, self.pixelsDeep - 1), originalVoxelToNewVoxelTransform);
    NIBBVector corner8 = NIBBVectorApplyTransform(NIBBVectorMake(self.pixelsWide - 1, self.pixelsHigh - 1, self.pixelsDeep - 1), originalVoxelToNewVoxelTransform);

    minCorner.x = MIN(MIN(MIN(MIN(MIN(MIN(MIN(corner1.x, corner2.x), corner3.x), corner4.x), corner5.x), corner6.x), corner7.x), corner8.x);
    minCorner.y = MIN(MIN(MIN(MIN(MIN(MIN(MIN(corner1.y, corner2.y), corner3.y), corner4.y), corner5.y), corner6.y), corner7.y), corner8.y);
    minCorner.z = MIN(MIN(MIN(MIN(MIN(MIN(MIN(corner1.z, corner2.z), corner3.z), corner4.z), corner5.z), corner6.z), corner7.z), corner8.z);
    maxCorner.x = MAX(MAX(MAX(MAX(MAX(MAX(MAX(corner1.x, corner2.x), corner3.x), corner4.x), corner5.x), corner6.x), corner7.x), corner8.x);
    maxCorner.y = MAX(MAX(MAX(MAX(MAX(MAX(MAX(corner1.y, corner2.y), corner3.y), corner4.y), corner5.y), corner6.y), corner7.y), corner8.y);
    maxCorner.z = MAX(MAX(MAX(MAX(MAX(MAX(MAX(corner1.z, corner2.z), corner3.z), corner4.z), corner5.z), corner6.z), corner7.z), corner8.z);

#if CGFLOAT_IS_DOUBLE
    minCorner.x = floor(minCorner.x + 0.05);
    minCorner.y = floor(minCorner.y + 0.05);
    minCorner.z = floor(minCorner.z + 0.05);
    maxCorner.x = ceil(maxCorner.x - 0.05);
    maxCorner.y = ceil(maxCorner.y - 0.05);
    maxCorner.z = ceil(maxCorner.z - 0.05);
#else
    minCorner.x = floorf(minCorner.x + 0.05);
    minCorner.y = floorf(minCorner.y + 0.05);
    minCorner.z = floorf(minCorner.z + 0.05);
    maxCorner.x = ceilf(maxCorner.x - 0.05);
    maxCorner.y = ceilf(maxCorner.y - 0.05);
    maxCorner.z = ceilf(maxCorner.z - 0.05);
#endif

    NSUInteger width = (NSUInteger)(maxCorner.x - minCorner.x) + 1;
    NSUInteger height = (NSUInteger)(maxCorner.y - minCorner.y) + 1;
    NSUInteger depth = (NSUInteger)(maxCorner.z - minCorner.z) + 1;

    NIBBAffineTransform shiftedTransform = NIBBAffineTransformConcat(transform, NIBBAffineTransformMakeTranslation(-1.0*(CGFloat)minCorner.x, -1.0*(CGFloat)minCorner.y, -1.0*(CGFloat)minCorner.z));

    return [self volumeDataResampledWithVolumeTransform:shiftedTransform pixelsWide:width pixelsHigh:height pixelsDeep:depth interpolationMode:interpolationsMode];
}

- (instancetype)volumeDataResampledWithVolumeTransform:(NIBBAffineTransform)transform pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
                                     interpolationMode:(NIBBInterpolationMode)interpolationsMode
{
    NIBBAffineTransform newVoxelToDicomTransform = NIBBAffineTransformInvert(transform);

    NIBBObliqueSliceGeneratorRequest *request = [[[NIBBObliqueSliceGeneratorRequest alloc] init] autorelease];

    NIBBVector xBasis = NIBBVectorApplyTransformToDirectionalVector(NIBBVectorXBasis, newVoxelToDicomTransform);
    NIBBVector yBasis = NIBBVectorApplyTransformToDirectionalVector(NIBBVectorYBasis, newVoxelToDicomTransform);
    NIBBVector zBasis = NIBBVectorApplyTransformToDirectionalVector(NIBBVectorZBasis, newVoxelToDicomTransform);

    request.origin = NIBBVectorApplyTransform(NIBBVectorMake(0, 0, floor((CGFloat)pixelsDeep) / 2.0), newVoxelToDicomTransform);
    request.directionX = NIBBVectorNormalize(xBasis);
    request.directionY = NIBBVectorNormalize(yBasis);
    if ([request respondsToSelector:@selector(setDirectionZ:)]) {
        request.directionZ = NIBBVectorNormalize(zBasis);
    }

    request.pixelSpacingX = NIBBVectorLength(xBasis);
    request.pixelSpacingY = NIBBVectorLength(yBasis);
    if ([request respondsToSelector:@selector(setPixelSpacingZ:)]) {
        request.pixelSpacingZ = NIBBVectorLength(zBasis);
    } else {
        request.slabSampleDistance = NIBBVectorLength(zBasis);
    }

    request.pixelsWide = pixelsWide;
    request.pixelsHigh = pixelsHigh;
    if (pixelsDeep % 2) {
        request.slabWidth = NIBBVectorLength(zBasis) * ((CGFloat)pixelsDeep - 1); // warning, The update to osirix changes how pixelsDeep is calculated
    } else {
        request.slabWidth = NIBBVectorLength(zBasis) * (CGFloat)pixelsDeep;
    }

    request.interpolationMode = interpolationsMode;

    NIBBVolumeData *newVolumeData = [NIBBGenerator synchronousRequestVolume:request volumeData:self];

    return [[[[self class] alloc] initWithData:[newVolumeData floatData] pixelsWide:newVolumeData.pixelsWide pixelsHigh:newVolumeData.pixelsHigh pixelsDeep:pixelsDeep
                               volumeTransform:newVolumeData.volumeTransform outOfBoundsValue:newVolumeData.outOfBoundsValue] autorelease];
}

- (NSUInteger)tempBufferSizeForNumVectors:(NSUInteger)numVectors
{
    return numVectors * sizeof(float) * 11;
}

- (BOOL)isEqual:(id)object
{
    BOOL isEqual = NO;
    if ([object isKindOfClass:[NIBBVolumeData class]]) {
        NIBBVolumeDataInlineBuffer inlineBuffer1;
        NIBBVolumeDataInlineBuffer inlineBuffer2;
        NIBBVolumeData *otherVolumeData = (NIBBVolumeData *)object;

        [self aquireInlineBuffer:&inlineBuffer1];
        [otherVolumeData aquireInlineBuffer:&inlineBuffer2];

        if (inlineBuffer1.floatBytes == inlineBuffer2.floatBytes &&
            inlineBuffer1.outOfBoundsValue == inlineBuffer2.outOfBoundsValue &&
            inlineBuffer1.pixelsWide == inlineBuffer2.pixelsWide &&
            inlineBuffer1.pixelsHigh == inlineBuffer2.pixelsHigh &&
            inlineBuffer1.pixelsDeep == inlineBuffer2.pixelsDeep &&
            NIBBAffineTransformEqualToTransform(inlineBuffer1.volumeTransform, inlineBuffer2.volumeTransform)) {
            isEqual = YES;
        }
    }

    return isEqual;
}

// not done yet, will crash if given vectors that are outside of the volume
- (void)linearInterpolateVolumeVectors:(NIBBVectorArray)volumeVectors outputValues:(float *)outputValues numVectors:(NSUInteger)numVectors tempBuffer:(void *)tempBuffer
{
    float *interpolateBuffer = (float *)tempBuffer;

    float *scrap;

    float *yFloors;
    float *zFloors;
    float *yFrac;
    float *zFrac;
    float *yNegFrac;
    float *zNegFrac;
    float negOne;

    float *i1Positions;
    float *i2Positions;
    float *j1Positions;
    float *j2Positions;

    float *yFloorPosition;
    float *yCielPosition;
    float *zFloorPosition;
    float *zCielPosition;

    float width;
    float widthTimesHeight;
    float widthTimesHeightTimeDepth;

    float *i1;
    float *i2;
    float *j1;
    float *j2;

    float *w1;
    float *w2;

    negOne = -1.0;
    width = _pixelsWide;
    widthTimesHeight = _pixelsWide*_pixelsHigh;
    widthTimesHeightTimeDepth = widthTimesHeight*_pixelsDeep;

    yFrac = interpolateBuffer + (numVectors * 0);
    zFrac = interpolateBuffer + (numVectors * 1);
    yFloors = interpolateBuffer + (numVectors * 2);
    zFloors = interpolateBuffer + (numVectors * 3);

    vDSP_vfrac(((float *)volumeVectors) + 1, 3, yFrac, 1, numVectors);
    vDSP_vsub(yFrac, 1, ((float *)volumeVectors) + 1, 3, yFloors, 1, numVectors);

    vDSP_vfrac(((float *)volumeVectors) + 2, 3, zFrac, 1, numVectors);
    vDSP_vsub(zFrac, 1, ((float *)volumeVectors) + 2, 3, zFloors, 1, numVectors);

    yFloorPosition = interpolateBuffer + (numVectors * 6);
    yCielPosition = interpolateBuffer + (numVectors * 7);
    zFloorPosition = interpolateBuffer + (numVectors * 8);
    zCielPosition = interpolateBuffer + (numVectors * 9);

    vDSP_vsmul(yFloors, 1, &width, yFloorPosition, 1, numVectors);
    vDSP_vsadd(yFloorPosition, 1, &width, yCielPosition, 1, numVectors);
    vDSP_vsmul(zFloors, 1, &widthTimesHeight, zFloorPosition, 1, numVectors);
    vDSP_vsadd(zFloorPosition, 1, &widthTimesHeight, zCielPosition, 1, numVectors);

    i1Positions = interpolateBuffer + (numVectors * 2);
    i2Positions = interpolateBuffer + (numVectors * 3);
    j1Positions = interpolateBuffer + (numVectors * 4);
    j2Positions = interpolateBuffer + (numVectors * 5);

    // i1 yFloor zFloor
    // i2 yFloor zCiel
    // j1 yCiel zFloor
    // j2 yCiel zCiel

    vDSP_vadd((float *)volumeVectors, 3, yFloorPosition, 1, i1Positions, 1, numVectors);

    vDSP_vadd(i1Positions, 1, zCielPosition, 1, i2Positions, 1, numVectors);
    vDSP_vadd(i1Positions, 1, zFloorPosition, 1, i1Positions, 1, numVectors);

    vDSP_vadd((float *)volumeVectors, 3, yCielPosition, 1, j1Positions, 1, numVectors);

    vDSP_vadd(j1Positions, 1, zCielPosition, 1, j2Positions, 1, numVectors);
    vDSP_vadd(j1Positions, 1, zFloorPosition, 1, j1Positions, 1, numVectors);


    i1 = interpolateBuffer + (numVectors * 6);
    i2 = interpolateBuffer + (numVectors * 7);
    j1 = interpolateBuffer + (numVectors * 8);
    j2 = interpolateBuffer + (numVectors * 9);

    vDSP_vlint((float *)self.floatBytes, i1Positions, 1, i1, 1, numVectors * 4, widthTimesHeightTimeDepth);

    yNegFrac = interpolateBuffer + (numVectors * 2);
    zNegFrac = interpolateBuffer + (numVectors * 3);

    vDSP_vsadd(yFrac, 1, &negOne, yNegFrac, 1, numVectors);
    vDSP_vneg(yNegFrac, 1, yNegFrac, 1, numVectors);

    vDSP_vsadd(zFrac, 1, &negOne, zNegFrac, 1, numVectors);
    vDSP_vneg(zNegFrac, 1, zNegFrac, 1, numVectors);

    w1 = interpolateBuffer + (numVectors * 4);
    w2 = interpolateBuffer + (numVectors * 5);

    scrap = interpolateBuffer + (numVectors * 10);

    vDSP_vmul(i1, 1, zNegFrac, 1, w1, 1, numVectors);
    vDSP_vmul(i2, 1, zFrac, 1, scrap, 1, numVectors);
    vDSP_vadd(w1, 1, scrap, 1, w1, 1, numVectors);

    vDSP_vmul(j1, 1, zNegFrac, 1, w2, 1, numVectors);
    vDSP_vmul(j2, 1, zFrac, 1, scrap, 1, numVectors);
    vDSP_vadd(w2, 1, scrap, 1, w2, 1, numVectors);


    vDSP_vmul(w1, 1, yNegFrac, 1, outputValues, 1, numVectors);
    vDSP_vmul(w2, 1, yFrac, 1, scrap, 1, numVectors);
    vDSP_vadd(outputValues, 1, scrap, 1, outputValues, 1, numVectors);
}



- (BOOL)aquireInlineBuffer:(NIBBVolumeDataInlineBuffer *)inlineBuffer
{
    memset(inlineBuffer, 0, sizeof(NIBBVolumeDataInlineBuffer));
    inlineBuffer->floatBytes = self.floatBytes;
    inlineBuffer->outOfBoundsValue = _outOfBoundsValue;
    inlineBuffer->pixelsWide = _pixelsWide;
    inlineBuffer->pixelsHigh = _pixelsHigh;
    inlineBuffer->pixelsDeep = _pixelsDeep;
    inlineBuffer->pixelsWideTimesPixelsHigh = _pixelsWide*_pixelsHigh;
    inlineBuffer->volumeTransform = _volumeTransform;
    return YES;
}

- (void)releaseInlineBuffer:(NIBBVolumeDataInlineBuffer *)inlineBuffer __deprecated {}

- (BOOL)_testOrientationMatrix:(double[9])orientation // returns YES if the orientation matrix's determinant is non-zero
{
    NIBBAffineTransform transform;

    transform = NIBBAffineTransformIdentity;
    transform.m11 = orientation[0];
    transform.m12 = orientation[1];
    transform.m13 = orientation[2];
    transform.m21 = orientation[3];
    transform.m22 = orientation[4];
    transform.m23 = orientation[5];
    transform.m31 = orientation[6];
    transform.m32 = orientation[7];
    transform.m33 = orientation[8];

    return NIBBAffineTransformDeterminant(transform) != 0.0;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString string];
    [description appendString:NSStringFromClass([self class])];
    [description appendString:[NSString stringWithFormat: @"\nPixels Wide: %lld\n", (long long)_pixelsWide]];
    [description appendString:[NSString stringWithFormat: @"Pixels High: %lld\n", (long long)_pixelsHigh]];
    [description appendString:[NSString stringWithFormat: @"Pixels Deep: %lld\n", (long long)_pixelsDeep]];
    [description appendString:[NSString stringWithFormat: @"Out of Bounds Value: %f\n", _outOfBoundsValue]];
    [description appendString:[NSString stringWithFormat: @"Volume Transform:\n%@\n", NSStringFromNIBBAffineTransform(_volumeTransform)]];

    return description;
}

@end

//@implementation NIBBVolumeData (DCMPixAndVolume)
//
//- (id)initWithWithPixList:(NSArray *)pixList volume:(NSData *)volume
//{
//    DCMPix *firstPix;
//    float sliceThickness;
//    NIBBAffineTransform pixToDicomTransform;
//    double spacingX;
//    double spacingY;
//    double spacingZ;
//    double orientation[9];
//
//    firstPix = [pixList objectAtIndex:0];
//
//    sliceThickness = [firstPix sliceInterval];
//    if(sliceThickness == 0)
//    {
//        NSLog(@"slice interval = slice thickness!");
//        sliceThickness = [firstPix sliceThickness];
//    }
//
//    memset(orientation, 0, sizeof(double) * 9);
//    [firstPix orientationDouble:orientation];
//    spacingX = firstPix.pixelSpacingX;
//    spacingY = firstPix.pixelSpacingY;
//    if(sliceThickness == 0) { // if the slice thickness is still 0, make it the same as the average of the spacingX and spacingY
//        sliceThickness = (spacingX + spacingY)/2.0;
//    }
//    spacingZ = sliceThickness;
//
//    // test to make sure that orientation is initialized, when the volume is curved or something, it doesn't make sense to talk about orientation, and
//    // so the orientation is really bogus
//    // the test we will do is to make sure that orientation is 3 non-degenerate vectors
//    if ([self _testOrientationMatrix:orientation] == NO) {
//        memset(orientation, 0, sizeof(double)*9);
//        orientation[0] = orientation[4] = orientation[8] = 1;
//    }
//
//    // This is not really the pixToDicom because for the NIBBVolumeData uses Center rule whereas DCMPix uses Top-Left rule.
//    pixToDicomTransform = NIBBAffineTransformIdentity;
//    pixToDicomTransform.m41 = firstPix.originX;
//    pixToDicomTransform.m42 = firstPix.originY;
//    pixToDicomTransform.m43 = firstPix.originZ;
//    pixToDicomTransform.m11 = orientation[0]*spacingX;
//    pixToDicomTransform.m12 = orientation[1]*spacingX;
//    pixToDicomTransform.m13 = orientation[2]*spacingX;
//    pixToDicomTransform.m21 = orientation[3]*spacingY;
//    pixToDicomTransform.m22 = orientation[4]*spacingY;
//    pixToDicomTransform.m23 = orientation[5]*spacingY;
//    pixToDicomTransform.m31 = orientation[6]*spacingZ;
//    pixToDicomTransform.m32 = orientation[7]*spacingZ;
//    pixToDicomTransform.m33 = orientation[8]*spacingZ;
//
//    self = [self initWithData:volume pixelsWide:[firstPix pwidth] pixelsHigh:[firstPix pheight] pixelsDeep:[pixList count]
//              volumeTransform:NIBBAffineTransformInvert(pixToDicomTransform) outOfBoundsValue:-1000];
//    return self;
//}
//
//- (void)getOrientation:(float[6])orientation
//{
//    double doubleOrientation[6];
//    NSInteger i;
//
//    [self getOrientationDouble:doubleOrientation];
//
//    for (i = 0; i < 6; i++) {
//        orientation[i] = doubleOrientation[i];
//    }
//}
//
//- (void)getOrientationDouble:(double[6])orientation
//{
//    NIBBAffineTransform pixelToDicomTransform;
//    NIBBVector xBasis;
//    NIBBVector yBasis;
//
//    pixelToDicomTransform = NIBBAffineTransformInvert(_volumeTransform);
//
//    xBasis = NIBBVectorNormalize(NIBBVectorMake(pixelToDicomTransform.m11, pixelToDicomTransform.m12, pixelToDicomTransform.m13));
//    yBasis = NIBBVectorNormalize(NIBBVectorMake(pixelToDicomTransform.m21, pixelToDicomTransform.m22, pixelToDicomTransform.m23));
//
//    orientation[0] = xBasis.x; orientation[1] = xBasis.y; orientation[2] = xBasis.z;
//    orientation[3] = yBasis.x; orientation[4] = yBasis.y; orientation[5] = yBasis.z;
//}
//
//- (float)originX
//{
//    NIBBAffineTransform pixelToDicomTransform;
//
//    pixelToDicomTransform = NIBBAffineTransformInvert(_volumeTransform);
//
//    return pixelToDicomTransform.m41;
//}
//
//- (float)originY
//{
//    NIBBAffineTransform pixelToDicomTransform;
//
//    pixelToDicomTransform = NIBBAffineTransformInvert(_volumeTransform);
//
//    return pixelToDicomTransform.m42;
//}
//
//- (float)originZ
//{
//    NIBBAffineTransform pixelToDicomTransform;
//
//    pixelToDicomTransform = NIBBAffineTransformInvert(_volumeTransform);
//    
//    return pixelToDicomTransform.m43;
//}
//
//
//@end














