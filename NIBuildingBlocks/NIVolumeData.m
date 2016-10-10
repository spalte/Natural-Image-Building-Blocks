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

#import "NIVolumeData.h"
#import "NIGenerator.h"
#import "NIGeneratorRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIVolumeData ()

@property (nonatomic, readonly, assign) float* floatBytes;

@end


@implementation NIVolumeData

@synthesize outOfBoundsValue = _outOfBoundsValue;
@synthesize pixelsWide = _pixelsWide;
@synthesize pixelsHigh = _pixelsHigh;
@synthesize pixelsDeep = _pixelsDeep;
@synthesize modelToVoxelTransform = _modelToVoxelTransform;
@synthesize floatData = _floatData;
@synthesize curved = _curved;

+ (NIAffineTransform)modelToVoxelTransformForOrigin:(NIVector)origin directionX:(NIVector)directionX pixelSpacingX:(CGFloat)pixelSpacingX directionY:(NIVector)directionY pixelSpacingY:(CGFloat)pixelSpacingY
                                     directionZ:(NIVector)directionZ pixelSpacingZ:(CGFloat)pixelSpacingZ
{
    directionX = NIVectorNormalize(directionX);
    directionY = NIVectorNormalize(directionY);
    directionZ = NIVectorNormalize(directionZ);

    NIAffineTransform transform = NIAffineTransformIdentity;
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

    return NIAffineTransformInvert(transform);
}

- (instancetype)initWithBytesNoCopy:(const float *)floatBytes pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
                    modelToVoxelTransform:(NIAffineTransform)modelToVoxelTransform outOfBoundsValue:(float)outOfBoundsValue freeWhenDone:(BOOL)freeWhenDone // modelToVoxelTransform is the transform from Model (patient) space to pixel data
{
    return [self initWithData:[NSData dataWithBytesNoCopy:(void *)floatBytes length:sizeof(float) * pixelsWide * pixelsHigh * pixelsDeep freeWhenDone:freeWhenDone]
                   pixelsWide:pixelsWide pixelsHigh:pixelsHigh pixelsDeep:pixelsDeep modelToVoxelTransform:modelToVoxelTransform outOfBoundsValue:outOfBoundsValue];
}

- (instancetype)initWithData:(NSData *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
             modelToVoxelTransform:(NIAffineTransform)modelToVoxelTransform outOfBoundsValue:(float)outOfBoundsValue // modelToVoxelTransform is the transform from Model (patient) space to pixel data
{
    if ([data length] < sizeof(float)*pixelsWide*pixelsHigh*pixelsDeep) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: data is not big enough (length:%lld) to hold a volume of size %lldx%lldx%lld", __PRETTY_FUNCTION__, (long long)[data length], (long long)pixelsWide, (long long)pixelsHigh, (long long)pixelsDeep] userInfo:nil];
    }

    if ( (self = [super init]) ) {
        _floatData = [data retain];
        _outOfBoundsValue = outOfBoundsValue;
        _pixelsWide = pixelsWide;
        _pixelsHigh = pixelsHigh;
        _pixelsDeep = pixelsDeep;
        _modelToVoxelTransform = modelToVoxelTransform;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
      volumeToModelConverter:(NIVector (^)(NIVector volumeVector))volumeToModelConverter modelToVolumeConverter:(NIVector (^)(NIVector modelVector))modelToVolumeConverter
            outOfBoundsValue:(float)outOfBoundsValue
{
    if ( (self = [super init]) ) {
        _floatData = [data retain];
        _outOfBoundsValue = outOfBoundsValue;
        _pixelsWide = pixelsWide;
        _pixelsHigh = pixelsHigh;
        _pixelsDeep = pixelsDeep;
        _modelToVoxelTransform = NIAffineTransformIdentity;
        _curved = YES;
        _convertVolumeVectorToModelVectorBlock = [volumeToModelConverter copy];
        _convertVolumeVectorFromModelVectorBlock = [modelToVolumeConverter copy];
    }
    return self;
}

- (instancetype)initWithVolumeData:(NIVolumeData *)volumeData
{
    if (volumeData.curved) {
        return [self initWithData:volumeData.floatData pixelsWide:volumeData.pixelsWide pixelsHigh:volumeData.pixelsHigh pixelsDeep:volumeData.pixelsDeep modelToVoxelTransform:volumeData.modelToVoxelTransform outOfBoundsValue:volumeData.outOfBoundsValue];
    } else {
        return [self initWithData:volumeData.floatData pixelsWide:volumeData.pixelsWide pixelsHigh:volumeData.pixelsHigh pixelsDeep:volumeData.pixelsDeep
           volumeToModelConverter:volumeData.convertVolumeVectorToModelVectorBlock modelToVolumeConverter:volumeData.convertVolumeVectorFromModelVectorBlock outOfBoundsValue:volumeData.outOfBoundsValue];
    }
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (nullable id)replacementObjectForPortCoder:(NSPortCoder *)encoder
{
    if ([encoder isBycopy]) return self;
    return [super replacementObjectForPortCoder:encoder];
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder
{
    if ([decoder allowsKeyedCoding]) {
        if ( (self = [self initWithData:[NSData data] pixelsWide:0 pixelsHigh:0 pixelsDeep:0 modelToVoxelTransform:NIAffineTransformIdentity outOfBoundsValue:0]) ) {
            _floatData = [[decoder decodeObjectOfClass:[NSData class] forKey:@"floatData"] retain];
            _outOfBoundsValue = [decoder decodeFloatForKey:@"outOfBoundsValue"];

            _pixelsWide = [decoder decodeIntegerForKey:@"pixelsWide"];
            _pixelsHigh = [decoder decodeIntegerForKey:@"pixelsHigh"];
            _pixelsDeep = [decoder decodeIntegerForKey:@"pixelsDeep"];

            if ([_floatData length] < (_pixelsWide * _pixelsHigh * _pixelsDeep * sizeof(float))) {
                [NSException raise:NSInvalidUnarchiveOperationException format:@"*** %s: floatData (%lld bytes) is not large enough for the size parameters. (pixelsWide: %lld, pixelsHigh: %lld, pixelsDeep: %lld)",
                 __PRETTY_FUNCTION__, (long long)[_floatData length], (long long)_pixelsWide, (long long)_pixelsHigh, (long long)_pixelsDeep];
            }

            _modelToVoxelTransform = [decoder decodeNIAffineTransformForKey:@"modelToVoxelTransform"];
        }
    } else {
        [NSException raise:NSInvalidUnarchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }
    return self;
}


- (instancetype)copyWithZone:(nullable NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithVolumeData:self];
}

- (void)dealloc
{
    [_floatData release];
    _floatData = nil;
    [_convertVolumeVectorToModelVectorBlock release];
    _convertVolumeVectorToModelVectorBlock = nil;
    [_convertVolumeVectorFromModelVectorBlock release];
    _convertVolumeVectorFromModelVectorBlock = nil;

    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder allowsKeyedCoding]) {
        if (_curved) {
            [NSException raise:NSInvalidArchiveOperationException format:@"*** %s: can't archive curved volumes", __PRETTY_FUNCTION__];
        }

        [aCoder encodeObject:_floatData forKey:@"floatData"];
        [aCoder encodeFloat:_outOfBoundsValue forKey:@"outOfBoundsValue"];

        [aCoder encodeInteger:_pixelsWide forKey:@"pixelsWide"];
        [aCoder encodeInteger:_pixelsHigh forKey:@"pixelsHigh"];
        [aCoder encodeInteger:_pixelsDeep forKey:@"pixelsDeep"];


        [aCoder encodeNIAffineTransform:_modelToVoxelTransform forKey:@"modelToVoxelTransform"];
    } else {
        [NSException raise:NSInvalidArchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }
}

- (BOOL)isRectilinear
{
    return self.curved == NO && NIAffineTransformIsRectilinear(_modelToVoxelTransform);
}

- (CGFloat)minPixelSpacing
{
    return MIN(MIN(self.pixelSpacingX, self.pixelSpacingY), self.pixelSpacingZ);
}

- (CGFloat)pixelSpacingX
{
    NIVector zero;
    NIAffineTransform inverseTransform;

    if (self.rectilinear) {
        return 1.0/_modelToVoxelTransform.m11;
    } else {
        inverseTransform = NIAffineTransformInvert(_modelToVoxelTransform);
        zero = NIVectorApplyTransform(NIVectorZero, inverseTransform);
        return NIVectorDistance(zero, NIVectorApplyTransform(NIVectorMake(1.0, 0.0, 0.0), inverseTransform));
    }
}

- (CGFloat)pixelSpacingY
{
    NIVector zero;
    NIAffineTransform inverseTransform;

    if (self.rectilinear) {
        return 1.0/_modelToVoxelTransform.m22;
    } else {
        inverseTransform = NIAffineTransformInvert(_modelToVoxelTransform);
        zero = NIVectorApplyTransform(NIVectorZero, inverseTransform);
        return NIVectorDistance(zero, NIVectorApplyTransform(NIVectorMake(0.0, 1.0, 0.0), inverseTransform));
    }
}

- (CGFloat)pixelSpacingZ
{
    NIVector zero;
    NIAffineTransform inverseTransform;

    if (self.rectilinear) {
        return 1.0/_modelToVoxelTransform.m33;
    } else {
        inverseTransform = NIAffineTransformInvert(_modelToVoxelTransform);
        zero = NIVectorApplyTransform(NIVectorZero, inverseTransform);
        return NIVectorDistance(zero, NIVectorApplyTransform(NIVectorMake(0.0, 0.0, 1.0), inverseTransform));
    }
}

- (NIVector)origin
{
    NIAffineTransform inverseTransform = NIAffineTransformInvert(_modelToVoxelTransform);
    return NIVectorMake(inverseTransform.m41, inverseTransform.m42, inverseTransform.m43);
}

- (NIVector)center
{
    NIAffineTransform inverseTransform = NIAffineTransformInvert(_modelToVoxelTransform);
    return NIVectorApplyTransform(NIVectorMake((CGFloat)_pixelsWide/2.0, (CGFloat)_pixelsHigh/2.0, (CGFloat)_pixelsDeep/2.0), inverseTransform);
}

- (NIVector)directionX
{
    NIAffineTransform inverseTransform;

    if (self.rectilinear) {
        return NIVectorXBasis;
    } else {
        inverseTransform = NIAffineTransformInvert(_modelToVoxelTransform);
        return NIVectorNormalize(NIVectorMake(inverseTransform.m11, inverseTransform.m12, inverseTransform.m13));
    }
}

- (NIVector)directionY
{
    NIAffineTransform inverseTransform;

    if (self.rectilinear) {
        return NIVectorYBasis;
    } else {
        inverseTransform = NIAffineTransformInvert(_modelToVoxelTransform);
        return NIVectorNormalize(NIVectorMake(inverseTransform.m21, inverseTransform.m22, inverseTransform.m23));
    }
}

- (NIVector)directionZ
{
    NIAffineTransform inverseTransform;

    if (self.rectilinear) {
        return NIVectorZBasis;
    } else {
        inverseTransform = NIAffineTransformInvert(_modelToVoxelTransform);
        return NIVectorNormalize(NIVectorMake(inverseTransform.m31, inverseTransform.m32, inverseTransform.m33));
    }
}

- (float *)floatBytes
{
    return (float *)[_floatData bytes];
}

// will copy fill length*sizeof(float) bytes
- (NSUInteger)getFloatRun:(float *)buffer atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z length:(NSUInteger)length
{
    NSUInteger copyLength = length;
    if (x >= _pixelsWide || y >= _pixelsHigh || z >= _pixelsDeep) {
        return 0;
    }
    copyLength = MIN(length, _pixelsWide - x);
    memcpy(buffer, &(self.floatBytes[x + _pixelsWide*(y + z*_pixelsHigh)]), copyLength * sizeof(float));
    return copyLength;
}

- (nullable NIVector (^)(NIVector))convertVolumeVectorToModelVectorBlock
{
    if (_curved == NO) {
        NIAffineTransform voxelToModelTransform = NIAffineTransformInvert([self modelToVoxelTransform]);

        return [[^NIVector(NIVector vector) {
            return NIVectorApplyTransform(vector, voxelToModelTransform);
        } copy] autorelease];
    } else {
        return _convertVolumeVectorToModelVectorBlock;
    }
}

- (nullable NIVector (^)(NIVector))convertVolumeVectorFromModelVectorBlock
{
    if (_curved == NO) {
        NIAffineTransform modelToVoxelTransform = [self modelToVoxelTransform];

        return [[^NIVector(NIVector vector) {
            return NIVectorApplyTransform(vector, modelToVoxelTransform);
        } copy] autorelease];
    } else {
        return _convertVolumeVectorFromModelVectorBlock;
    }
}

- (NIVector)convertVolumeVectorToModelVector:(NIVector)vector
{
    if (_curved) {
        return _convertVolumeVectorToModelVectorBlock(vector);
    }
    else {
        return NIVectorApplyTransform(vector, NIAffineTransformInvert([self modelToVoxelTransform]));
    }
}

- (NIVector)convertVolumeVectorFromModelVector:(NIVector)vector
{
    if (_curved) {
        return _convertVolumeVectorFromModelVectorBlock(vector);
    }
    else {
        return NIVectorApplyTransform(vector, [self modelToVoxelTransform]);
    }
}

- (vImage_Buffer)floatBufferForSliceAtIndex:(NSUInteger)z {
    vImage_Buffer floatBuffer;
    floatBuffer.data = (void *)self.floatBytes + (_pixelsWide * _pixelsHigh * sizeof(float) * z);
    floatBuffer.height = _pixelsHigh;
    floatBuffer.width = _pixelsWide;
    floatBuffer.rowBytes = sizeof(float) * _pixelsWide;
    return floatBuffer;
}

- (NIVolumeData *)volumeDataForSliceAtIndex:(NSUInteger)z
{
    if (z >= _pixelsDeep) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: z index outside of the volume", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NIVolumeData *sliceVolume;

    NSData *sliceData = [NSData dataWithBytes:self.floatBytes + (_pixelsWide*_pixelsHigh*z) length:_pixelsWide * _pixelsHigh * sizeof(float)];

    if (self.curved) {
        NIVector (^volumeVectorToModelVectorBlock)(NIVector) = ^(NIVector volumeVector){
            NIVector translatedVolumeVector = NIVectorSubtract(volumeVector, NIVectorMake(0, 0, z));
            return _convertVolumeVectorToModelVectorBlock(translatedVolumeVector);
        };
        NIVector (^volumeVectorFromModelVectorBlock)(NIVector) = ^(NIVector modelVector){
            NIVector volumeVector = _convertVolumeVectorFromModelVectorBlock(modelVector);
            return NIVectorAdd(volumeVector, NIVectorMake(0, 0, z));
        };

        sliceVolume = [[[self class] alloc] initWithData:sliceData pixelsWide:_pixelsWide pixelsHigh:_pixelsHigh pixelsDeep:1
                                  volumeToModelConverter:volumeVectorToModelVectorBlock modelToVolumeConverter:volumeVectorFromModelVectorBlock outOfBoundsValue:_outOfBoundsValue];
    } else {
        NIAffineTransform sliceTransform = NIAffineTransformConcat(_modelToVoxelTransform, NIAffineTransformMakeTranslation(0, 0, -z));
        sliceVolume = [[[self class] alloc] initWithData:sliceData pixelsWide:_pixelsWide pixelsHigh:_pixelsHigh pixelsDeep:1 modelToVoxelTransform:sliceTransform outOfBoundsValue:_outOfBoundsValue];
    }

    return [sliceVolume autorelease];
}

- (NIVolumeData *)volumeDataWithIndexRangesX:(NSRange)xr y:(NSRange)yr z:(NSRange)zr {
    if (NSMaxRange(xr) > _pixelsWide ||  NSMaxRange(yr) > _pixelsHigh ||  NSMaxRange(zr) > _pixelsDeep) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: index range outside of the volume", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NIVolumeData *data = nil;
    NIVector origin = NIVectorMake(xr.location, yr.location, zr.location);
    if (self.curved) {
        NIVector (^volumeVectorToModelVectorBlock)(NIVector) = ^(NIVector volumeVector){
            NIVector translatedVolumeVector = NIVectorSubtract(volumeVector, origin);
            return _convertVolumeVectorToModelVectorBlock(translatedVolumeVector);
        };
        NIVector (^volumeVectorFromModelVectorBlock)(NIVector) = ^(NIVector modelVector){
            NIVector volumeVector = _convertVolumeVectorFromModelVectorBlock(modelVector);
            return NIVectorAdd(volumeVector, origin);
        };

        data = [[[self class] alloc] initWithData:[NSMutableData dataWithLength:xr.length*yr.length*zr.length*sizeof(float)] pixelsWide:xr.length pixelsHigh:yr.length pixelsDeep:zr.length
                           volumeToModelConverter:volumeVectorToModelVectorBlock modelToVolumeConverter:volumeVectorFromModelVectorBlock outOfBoundsValue:self.outOfBoundsValue];
    } else {
        data = [[[self class] alloc] initWithData:[NSMutableData dataWithLength:xr.length*yr.length*zr.length*sizeof(float)] pixelsWide:xr.length pixelsHigh:yr.length pixelsDeep:zr.length
                            modelToVoxelTransform:NIAffineTransformConcat(self.modelToVoxelTransform, NIAffineTransformMakeTranslation(-1.*xr.location, -1.*yr.location, -1.*zr.location)) outOfBoundsValue:self.outOfBoundsValue];
    }
    NIVolumeDataInlineBuffer sib, dib; [self acquireInlineBuffer:&sib]; [data acquireInlineBuffer:&dib];
    for (NSUInteger z = 0; z < zr.length; ++z)
        for (NSUInteger y = 0; y < yr.length; ++y)
            memcpy((void *)&dib.floatBytes[NIVolumeDataUncheckedIndexAtCoordinate(&dib, 0,y,z)], &sib.floatBytes[NIVolumeDataUncheckedIndexAtCoordinate(&sib, xr.location,yr.location+y,zr.location+z)], xr.length*sizeof(float));
    
    return [data autorelease];
}

- (CGFloat)floatAtPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z
{
    NIVolumeDataInlineBuffer inlineBuffer;

    [self acquireInlineBuffer:&inlineBuffer];
    return NIVolumeDataGetFloatAtPixelCoordinate(&inlineBuffer, x, y, z);
}

- (CGFloat)linearInterpolatedFloatAtModelVector:(NIVector)vector
{
    NIVector volumeVector = [self convertVolumeVectorFromModelVector:vector];
    NIVolumeDataInlineBuffer inlineBuffer;

    [self acquireInlineBuffer:&inlineBuffer];
    return NIVolumeDataLinearInterpolatedFloatAtVolumeVector(&inlineBuffer, volumeVector);
}

- (CGFloat)nearestNeighborInterpolatedFloatAtModelVector:(NIVector)vector
{
    NIVector volumeVector = [self convertVolumeVectorFromModelVector:vector];
    NIVolumeDataInlineBuffer inlineBuffer;

    [self acquireInlineBuffer:&inlineBuffer];
    return NIVolumeDataNearestNeighborInterpolatedFloatAtVolumeVector(&inlineBuffer, volumeVector);
}

- (CGFloat)cubicInterpolatedFloatAtModelVector:(NIVector)vector
{
    NIVector volumeVector = [self convertVolumeVectorFromModelVector:vector];
    NIVolumeDataInlineBuffer inlineBuffer;

    [self acquireInlineBuffer:&inlineBuffer];
    return NIVolumeDataCubicInterpolatedFloatAtVolumeVector(&inlineBuffer, volumeVector);
}

- (instancetype)volumeDataWithModelToVoxelTransform:(NIAffineTransform)modelToVoxelTransform
{
    return [[[[self class] alloc] initWithData:_floatData pixelsWide:_pixelsWide pixelsHigh:_pixelsHigh pixelsDeep:_pixelsDeep
                         modelToVoxelTransform:modelToVoxelTransform outOfBoundsValue:_outOfBoundsValue] autorelease];
}

- (instancetype)volumeDataResampledWithModelToVoxelTransform:(NIAffineTransform)modelToVoxelTransform interpolationMode:(NIInterpolationMode)interpolationsMode
{
    if (self.curved) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: can not be called on a curved volume", __PRETTY_FUNCTION__] userInfo:nil];
    }

    if (NIAffineTransformEqualToTransform(self.modelToVoxelTransform, modelToVoxelTransform)) {
        return self;
    }

    NIAffineTransform oringinalVoxelToModelTransform = NIAffineTransformInvert(self.modelToVoxelTransform);
    NIAffineTransform originalVoxelToNewVoxelTransform = NIAffineTransformConcat(oringinalVoxelToModelTransform, modelToVoxelTransform);

    NIVector minCorner = NIVectorZero;
    NIVector maxCorner = NIVectorZero;

    NIVector corner1 = NIVectorApplyTransform(NIVectorMake(0,                   0,                   0), originalVoxelToNewVoxelTransform);
    NIVector corner2 = NIVectorApplyTransform(NIVectorMake(self.pixelsWide - 1, 0,                   0), originalVoxelToNewVoxelTransform);
    NIVector corner3 = NIVectorApplyTransform(NIVectorMake(0,                   self.pixelsHigh - 1, 0), originalVoxelToNewVoxelTransform);
    NIVector corner4 = NIVectorApplyTransform(NIVectorMake(self.pixelsWide - 1, self.pixelsHigh - 1, 0), originalVoxelToNewVoxelTransform);
    NIVector corner5 = NIVectorApplyTransform(NIVectorMake(0,                   0,                   self.pixelsDeep - 1), originalVoxelToNewVoxelTransform);
    NIVector corner6 = NIVectorApplyTransform(NIVectorMake(self.pixelsWide - 1, 0,                   self.pixelsDeep - 1), originalVoxelToNewVoxelTransform);
    NIVector corner7 = NIVectorApplyTransform(NIVectorMake(0,                   self.pixelsHigh - 1, self.pixelsDeep - 1), originalVoxelToNewVoxelTransform);
    NIVector corner8 = NIVectorApplyTransform(NIVectorMake(self.pixelsWide - 1, self.pixelsHigh - 1, self.pixelsDeep - 1), originalVoxelToNewVoxelTransform);

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

    NIAffineTransform shiftedTransform = NIAffineTransformConcat(modelToVoxelTransform, NIAffineTransformMakeTranslation(-1.0*(CGFloat)minCorner.x, -1.0*(CGFloat)minCorner.y, -1.0*(CGFloat)minCorner.z));

    return [self volumeDataResampledWithModelToVoxelTransform:shiftedTransform pixelsWide:width pixelsHigh:height pixelsDeep:depth interpolationMode:interpolationsMode];
}

- (instancetype)volumeDataResampledWithModelToVoxelTransform:(NIAffineTransform)transform pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
                                     interpolationMode:(NIInterpolationMode)interpolationsMode
{
    if (self.curved) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: can not be called on a curved volume", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NIAffineTransform newVoxelToModelTransform = NIAffineTransformInvert(transform);

    NIObliqueSliceGeneratorRequest *request = [[[NIObliqueSliceGeneratorRequest alloc] init] autorelease];

    NIVector xBasis = NIVectorApplyTransformToDirectionalVector(NIVectorXBasis, newVoxelToModelTransform);
    NIVector yBasis = NIVectorApplyTransformToDirectionalVector(NIVectorYBasis, newVoxelToModelTransform);
    NIVector zBasis = NIVectorApplyTransformToDirectionalVector(NIVectorZBasis, newVoxelToModelTransform);

    request.origin = NIVectorApplyTransform(NIVectorMake(0, 0, floor(((CGFloat)pixelsDeep) / 2.0)), newVoxelToModelTransform);
    request.directionX = NIVectorNormalize(xBasis);
    request.directionY = NIVectorNormalize(yBasis);
    request.directionZ = NIVectorNormalize(zBasis);

    request.pixelSpacingX = NIVectorLength(xBasis);
    request.pixelSpacingY = NIVectorLength(yBasis);
    request.pixelSpacingZ = NIVectorLength(zBasis);

    request.pixelsWide = pixelsWide;
    request.pixelsHigh = pixelsHigh;

    if (pixelsDeep % 2) {
        request.slabWidth = NIVectorLength(zBasis) * ((CGFloat)pixelsDeep - 1);
    } else {
        request.slabWidth = NIVectorLength(zBasis) * (CGFloat)pixelsDeep;
    }

    request.interpolationMode = interpolationsMode;

    NIVolumeData *newVolumeData = [NIGenerator synchronousRequestVolume:request volumeData:self];

    return [[[[self class] alloc] initWithData:[newVolumeData floatData] pixelsWide:newVolumeData.pixelsWide pixelsHigh:newVolumeData.pixelsHigh pixelsDeep:pixelsDeep
                               modelToVoxelTransform:newVolumeData.modelToVoxelTransform outOfBoundsValue:newVolumeData.outOfBoundsValue] autorelease];
}

- (NSUInteger)tempBufferSizeForNumVectors:(NSUInteger)numVectors
{
    return numVectors * sizeof(float) * 11;
}

- (BOOL)isEqual:(id)object
{
    BOOL isEqual = NO;
    if ([object isKindOfClass:[NIVolumeData class]]) {
        NIVolumeDataInlineBuffer inlineBuffer1;
        NIVolumeDataInlineBuffer inlineBuffer2;
        NIVolumeData *otherVolumeData = (NIVolumeData *)object;

        [self acquireInlineBuffer:&inlineBuffer1];
        [otherVolumeData acquireInlineBuffer:&inlineBuffer2];

        if (inlineBuffer1.outOfBoundsValue == inlineBuffer2.outOfBoundsValue &&
            inlineBuffer1.pixelsWide == inlineBuffer2.pixelsWide &&
            inlineBuffer1.pixelsHigh == inlineBuffer2.pixelsHigh &&
            inlineBuffer1.pixelsDeep == inlineBuffer2.pixelsDeep &&
            NIAffineTransformEqualToTransform(inlineBuffer1.modelToVoxelTransform, inlineBuffer2.modelToVoxelTransform)) {

            if (inlineBuffer1.floatBytes == inlineBuffer2.floatBytes) {
                return YES;
            } else {
                return memcmp(inlineBuffer1.floatBytes, inlineBuffer2.floatBytes, sizeof(float) * inlineBuffer1.pixelsWide * inlineBuffer1.pixelsHigh * inlineBuffer1.pixelsDeep) == 0;
            }
        }
    }

    return isEqual;
}

// not done yet, will crash if given vectors that are outside of the volume
- (void)linearInterpolateVolumeVectors:(NIVectorArray)volumeVectors outputValues:(float *)outputValues numVectors:(NSUInteger)numVectors tempBuffer:(void *)tempBuffer
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



- (void)acquireInlineBuffer:(NIVolumeDataInlineBuffer *)inlineBuffer
{
    memset(inlineBuffer, 0, sizeof(NIVolumeDataInlineBuffer));
    inlineBuffer->floatBytes = self.floatBytes;
    inlineBuffer->outOfBoundsValue = _outOfBoundsValue;
    inlineBuffer->pixelsWide = _pixelsWide;
    inlineBuffer->pixelsHigh = _pixelsHigh;
    inlineBuffer->pixelsDeep = _pixelsDeep;
    inlineBuffer->modelToVoxelTransform = _modelToVoxelTransform;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString string];
    [description appendString:NSStringFromClass([self class])];
    [description appendString:[NSString stringWithFormat: @"\nPixels Wide: %lld\n", (long long)_pixelsWide]];
    [description appendString:[NSString stringWithFormat: @"Pixels High: %lld\n", (long long)_pixelsHigh]];
    [description appendString:[NSString stringWithFormat: @"Pixels Deep: %lld\n", (long long)_pixelsDeep]];
    [description appendString:[NSString stringWithFormat: @"Out of Bounds Value: %f\n", _outOfBoundsValue]];
    [description appendString:[NSString stringWithFormat: @"Volume Transform:\n%@\n", NSStringFromNIAffineTransform(_modelToVoxelTransform)]];

    return description;
}

@end

NS_ASSUME_NONNULL_END
