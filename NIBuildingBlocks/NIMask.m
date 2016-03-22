
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

#import "NIMask.h"
#import "NIMaskRunStack.h"
#include <Accelerate/Accelerate.h>

const NIMaskIndex NIMaskIndexInvalid = {NSUIntegerMax,NSUIntegerMax,NSUIntegerMax};

BOOL NIMaskIndexEqualToMaskIndex(NIMaskIndex mi1, NIMaskIndex mi2) {
    return mi1.x == mi2.x && mi1.y == mi2.y && mi1.z == mi2.z;
}

NIMaskRun NIMaskRunMake(NSRange widthRange, NSUInteger heightIndex, NSUInteger depthIndex, float intensity)
{
    NIMaskRun maskRun = {widthRange, heightIndex, depthIndex, intensity, 0};
    return maskRun;
}

NSUInteger NIMaskRunFirstWidthIndex(NIMaskRun maskRun)
{
    return maskRun.widthRange.location;
}

NSUInteger NIMaskRunLastWidthIndex(NIMaskRun maskRun)
{
    return NSMaxRange(maskRun.widthRange) - 1;
}

const NIMaskRun NIMaskRunZero = {{0.0, 0.0}, 0, 0, 1.0, 0.0};

@interface NIMaskIndexPredicateStandIn : NSObject
{
    float intensity;
    float maskIntensity;
    NSUInteger maskIndexX;
    NSUInteger maskIndexY;
    NSUInteger maskIndexZ;
}
@property (nonatomic, readwrite, assign) float intensity;
@property (nonatomic, readwrite, assign) float maskIntensity;
@property (nonatomic, readwrite, assign) NSUInteger maskIndexX;
@property (nonatomic, readwrite, assign) NSUInteger maskIndexY;
@property (nonatomic, readwrite, assign) NSUInteger maskIndexZ;
@end
@implementation NIMaskIndexPredicateStandIn
@synthesize intensity;
@synthesize maskIntensity;
@synthesize maskIndexX;
@synthesize maskIndexY;
@synthesize maskIndexZ;
@end


NSComparisonResult NIMaskCompareRunValues(NSValue *maskRun1Value, NSValue *maskRun2Value, void *context)
{
    NIMaskRun maskRun1 = [maskRun1Value NIMaskRunValue];
    NIMaskRun maskRun2 = [maskRun2Value NIMaskRunValue];
    
    return NIMaskCompareRun(maskRun1, maskRun2);
}


NSComparisonResult NIMaskCompareRun(NIMaskRun maskRun1, NIMaskRun maskRun2)
{
    if (maskRun1.depthIndex < maskRun2.depthIndex) {
        return NSOrderedAscending;
    } else if (maskRun1.depthIndex > maskRun2.depthIndex) {
        return NSOrderedDescending;
    }
    
    if (maskRun1.heightIndex < maskRun2.heightIndex) {
        return NSOrderedAscending;
    } else if (maskRun1.heightIndex > maskRun2.heightIndex) {
        return NSOrderedDescending;
    }
    
    if (maskRun1.widthRange.location < maskRun2.widthRange.location) {
        return NSOrderedAscending;
    } else if (maskRun1.widthRange.location > maskRun2.widthRange.location) {
        return NSOrderedDescending;
    }
    
    return NSOrderedSame;
}

int NIMaskQSortCompareRun(const void *voidMaskRun1, const void *voidMaskRun2)
{
    const NIMaskRun* maskRun1 = voidMaskRun1;
    const NIMaskRun* maskRun2 = voidMaskRun2;
    
    if (maskRun1->depthIndex < maskRun2->depthIndex) {
        return NSOrderedAscending;
    } else if (maskRun1->depthIndex > maskRun2->depthIndex) {
        return NSOrderedDescending;
    }
    
    if (maskRun1->heightIndex < maskRun2->heightIndex) {
        return NSOrderedAscending;
    } else if (maskRun1->heightIndex > maskRun2->heightIndex) {
        return NSOrderedDescending;
    }
    
    if (maskRun1->widthRange.location < maskRun2->widthRange.location) {
        return NSOrderedAscending;
    } else if (maskRun1->widthRange.location > maskRun2->widthRange.location) {
        return NSOrderedDescending;
    }
    
    return NSOrderedSame;
    
}

BOOL NIMaskRunsOverlap(NIMaskRun maskRun1, NIMaskRun maskRun2)
{
    if (maskRun1.depthIndex == maskRun2.depthIndex && maskRun1.heightIndex == maskRun2.heightIndex) {
        return NSIntersectionRange(maskRun1.widthRange, maskRun2.widthRange).length != 0;
    }
    
    return NO;
}

BOOL NIMaskRunsAbut(NIMaskRun maskRun1, NIMaskRun maskRun2)
{
    if (maskRun1.depthIndex == maskRun2.depthIndex && maskRun1.heightIndex == maskRun2.heightIndex) {
        if (NSMaxRange(maskRun1.widthRange) == maskRun2.widthRange.location ||
            NSMaxRange(maskRun2.widthRange) == maskRun1.widthRange.location) {
            return YES;
        }
    }
    return NO;
}

NIVector NIMaskIndexApplyTransform(NIMaskIndex maskIndex, NIAffineTransform transform)
{
    return NIVectorApplyTransform(NIVectorMake(maskIndex.x, maskIndex.y, maskIndex.z), transform);
}

BOOL NIMaskIndexInRun(NIMaskIndex maskIndex, NIMaskRun maskRun)
{
    if (maskIndex.y != maskRun.heightIndex || maskIndex.z != maskRun.depthIndex) {
        return NO;
    }
    if (NSLocationInRange(maskIndex.x, maskRun.widthRange)) {
        return YES;
    } else {
        return NO;
    }
}

NSArray *NIMaskIndexesInRun(NIMaskRun maskRun)
{
    NSMutableArray *indexes;
    NSUInteger i;
    NIMaskIndex index;
    
    indexes = [NSMutableArray array];
    index.y = maskRun.heightIndex;
    index.z = maskRun.depthIndex;
    
    for (i = maskRun.widthRange.location; i < NSMaxRange(maskRun.widthRange); i++) {
        index.x = i;
        [indexes addObject:[NSValue valueWithNIMaskIndex:index]];
    }
    return indexes;
}

@interface NIMask ()
- (void)checkdebug;
+ (NSData *)storageDataFromMaskRunData:(NSData *)maskRunsData;
+ (NSData *)maskRunsDataFromStorageData:(NSData *)storageData;
@end

@implementation NIMask

+ (instancetype)mask
{
    return [[[[self class] alloc] init] autorelease];
}


+ (instancetype)maskWithSphereDiameter:(NSUInteger)diameter
{
    return [self maskWithEllipsoidWidth:diameter height:diameter depth:diameter];
}

+ (instancetype)maskWithCubeSize:(NSUInteger)size
{
    return [[self class] maskWithBoxWidth:size height:size depth:size];
}

+ (instancetype)maskWithBoxWidth:(NSUInteger)width height:(NSUInteger)height depth:(NSUInteger)depth;
{
    NSUInteger i = 0;
    NSUInteger j = 0;
    
    NIMaskRun *maskRuns = malloc(depth * height * sizeof(NIMaskRun));
    memset(maskRuns, 0, depth * height * sizeof(NIMaskRun));
    
    for (j = 0; j < height; j++) {
        for (i = 0; i < depth; i++) {
            maskRuns[(i*depth)+j] = NIMaskRunMake(NSMakeRange(0, width), i, j, 1);
        }
    }
    
    return [[[NIMask alloc] initWithSortedMaskRunData:[NSData dataWithBytesNoCopy:maskRuns length:depth * height * sizeof(NIMaskRun) freeWhenDone:YES]] autorelease];
}

+ (instancetype)maskWithEllipsoidWidth:(NSUInteger)width height:(NSUInteger)height depth:(NSUInteger)depth
{
    NSUInteger i = 0;
    NSUInteger j = 0;
    NSUInteger k = 0;
    
    NIMaskRun *maskRuns = malloc(height * depth * sizeof(NIMaskRun));
    memset(maskRuns, 0, height * depth * sizeof(NIMaskRun));
    
    CGFloat widthRadius = 0.5*(CGFloat)width;
    CGFloat heightRadius = 0.5*(CGFloat)height;
    CGFloat depthRadius = 0.5*(CGFloat)depth;
    NSInteger whiteSpace = 0;
    
    for (j = 0; j < depth; j++) {
        for (i = 0; i < height; i++) {
#if CGFLOAT_IS_DOUBLE
            CGFloat x = fabs(((CGFloat)i)+.5-heightRadius);
            CGFloat y = fabs(((CGFloat)j)+.5-depthRadius);
            if (widthRadius*widthRadius < x*x + y*y) {
                whiteSpace = -1;
            } else {
                whiteSpace = round(widthRadius - sqrt(widthRadius*widthRadius - x*x - y*y));
            }
#else
            CGFloat x = fabsf(((CGFloat)i)+.5f-heightRadius);
            CGFloat y = fabsf(((CGFloat)j)+.5f-depthRadius);
            if (widthRadius*widthRadius < x*x + y*y) {
                whiteSpace = -1;
            } else {
                whiteSpace = round(widthRadius - sqrt(widthRadius*widthRadius - x*x - y*y));
            }
#endif
            if (whiteSpace >= 0) {
                maskRuns[k] = NIMaskRunMake(NSMakeRange(whiteSpace, width - (2 * whiteSpace)), i, j, 1);
                k++;
            }
        }
    }
    
    return [[[NIMask alloc] initWithSortedMaskRunData:[NSData dataWithBytesNoCopy:maskRuns length:k * sizeof(NIMaskRun) freeWhenDone:YES]] autorelease];
}

+ (instancetype)maskFromVolumeData:(NIVolumeData *)volumeData __deprecated
{
    return [self maskFromVolumeData:volumeData modelToVoxelTransform:NULL];
}


+ (id)maskFromVolumeData:(NIVolumeData *)volumeData modelToVoxelTransform:(NIAffineTransformPointer)modelToVoxelTransformPtr
{
    NSInteger i;
    NSInteger j;
    NSInteger k;
    float intensity;
    NSMutableArray *maskRuns;
    NIMaskRun maskRun;
    NIVolumeDataInlineBuffer inlineBuffer;
    
    maskRuns = [NSMutableArray array];
    maskRun = NIMaskRunZero;
    maskRun.intensity = 0.0;
    
    [volumeData acquireInlineBuffer:&inlineBuffer];
    for (k = 0; k < inlineBuffer.pixelsDeep; k++) {
        for (j = 0; j < inlineBuffer.pixelsHigh; j++) {
            for (i = 0; i < inlineBuffer.pixelsWide; i++) {
                intensity = NIVolumeDataGetFloatAtPixelCoordinate(&inlineBuffer, i, j, k);
                intensity = roundf(intensity*255.0f)/255.0f;
                
                if (intensity != maskRun.intensity) { // maybe start a run, maybe close a run
                    if (maskRun.intensity != 0) { // we need to end the previous run
                        [maskRuns addObject:[NSValue valueWithNIMaskRun:maskRun]];
                        maskRun = NIMaskRunZero;
                        maskRun.intensity = 0.0;
                    }
                    
                    if (intensity != 0) { // we need to start a new mask run
                        maskRun.depthIndex = k;
                        maskRun.heightIndex = j;
                        maskRun.widthRange = NSMakeRange(i, 1);
                        maskRun.intensity = intensity;
                    }
                } else  { // maybe extend a run // maybe do nothing
                    if (intensity != 0) { // we need to extend the run
                        maskRun.widthRange.length += 1;
                    }
                }
            }
            // after each run scan line we need to close out any open mask run
            if (maskRun.intensity != 0) {
                [maskRuns addObject:[NSValue valueWithNIMaskRun:maskRun]];
                maskRun = NIMaskRunZero;
                maskRun.intensity = 0.0;
            }
        }
    }
    
    if (modelToVoxelTransformPtr) {
        *modelToVoxelTransformPtr = volumeData.modelToVoxelTransform;
    }
    
    return [[[[self class] alloc] initWithMaskRuns:maskRuns] autorelease];
}

+ (instancetype)maskWithLineFrom:(NIVector)start to:(NIVector)end
{
    // return points on a line inspired by Bresenham's line algorithm
    // This function needs to be optimized and not mak tons and tons of NSValue objects

    NIVector direction;
    NIVector absDirection;
    NIVector principleDirection;
    NIVector secondaryDirection;
    NIVector tertiaryDirection;

    direction = NIVectorSubtract(end, start);
    absDirection.x = ABS(direction.x);
    absDirection.y = ABS(direction.y);
    absDirection.z = ABS(direction.z);

    principleDirection = NIVectorZero;
    secondaryDirection = NIVectorZero;
    tertiaryDirection = NIVectorZero;

    if (absDirection.x > absDirection.y && absDirection.x > absDirection.z) {
        principleDirection.x = 1;
        secondaryDirection.y = 1;
        tertiaryDirection.z = 1;
    } else if (absDirection.y > absDirection.x && absDirection.y > absDirection.z) {
        principleDirection.y = 1;
        secondaryDirection.x = 1;
        tertiaryDirection.z = 1;
    } else {
        principleDirection.z = 1;
        secondaryDirection.x = 1;
        tertiaryDirection.y = 1;
    }

    if (NIVectorComponentsSum(NIVectorMultiply(direction, principleDirection)) == 0) {
        if (start.x >= 0 && start.y >= 0 && start.z >= 0) {
            NIMaskIndex maskIndex;
            maskIndex.x = round((double)start.x);
            maskIndex.y = round((double)start.y);
            maskIndex.z = round((double)start.z);

            return [[[NIMask alloc] initWithIndexes:[NSArray arrayWithObject:[NSValue valueWithNIMaskIndex:maskIndex]]] autorelease];
        } else {
            return [NIMask mask];
        }
    }

    NIVector secondarySlope = NIVectorScalarMultiply(secondaryDirection, NIVectorComponentsSum(NIVectorMultiply(direction, secondaryDirection)) /
                                                     ABS(NIVectorComponentsSum(NIVectorMultiply(direction, principleDirection))));
    NIVector tertiarySlope = NIVectorScalarMultiply(tertiaryDirection, NIVectorComponentsSum(NIVectorMultiply(direction, tertiaryDirection)) /
                                                    ABS(NIVectorComponentsSum(NIVectorMultiply(direction, principleDirection))));

    NSInteger endIndex = round((double)NIVectorComponentsSum(NIVectorMultiply(end, principleDirection)));
    NSInteger currentIndex = round((double)NIVectorComponentsSum(NIVectorMultiply(start, principleDirection)));
    BOOL goingForward = (NIVectorComponentsSum(NIVectorMultiply(direction, principleDirection)) > 0);

    NSUInteger i;
    NSMutableArray *maskIndexArray = [NSMutableArray array];
    for (i = 0; goingForward ? currentIndex < endIndex : currentIndex > endIndex; i++) {
        NIVector maskVector = start;
        if (goingForward) {
            maskVector = NIVectorAdd(maskVector, NIVectorScalarMultiply(principleDirection, (CGFloat)i));
        } else {
            maskVector = NIVectorAdd(maskVector, NIVectorScalarMultiply(principleDirection, -(CGFloat)i));
        }
        maskVector = NIVectorAdd(maskVector, NIVectorScalarMultiply(secondarySlope, (CGFloat)i));
        maskVector = NIVectorAdd(maskVector, NIVectorScalarMultiply(tertiarySlope, (CGFloat)i));

        maskVector.x = round((double)maskVector.x);
        maskVector.y = round((double)maskVector.y);
        maskVector.z = round((double)maskVector.z);

        currentIndex = round((double)NIVectorComponentsSum(NIVectorMultiply(maskVector, principleDirection)));

        if (maskVector.x >= 0 && maskVector.y >= 0 && maskVector.z >= 0) {
            NIMaskIndex maskIndex;
            maskIndex.x = maskVector.x;
            maskIndex.y = maskVector.y;
            maskIndex.z = maskVector.z;

            [maskIndexArray addObject:[NSValue valueWithNIMaskIndex:maskIndex]];
        }
    }

    return [[[NIMask alloc] initWithIndexes:maskIndexArray] autorelease];
}

- (instancetype)init
{
    if ( (self = [super init]) ) {
        _maskRuns = [[NSArray alloc] init];
    }
    return self;
}

- (instancetype)initWithMaskRuns:(NSArray *)maskRuns
{
    if ( (self = [super init]) ) {
        _maskRuns = [[maskRuns sortedArrayUsingFunction:NIMaskCompareRunValues context:NULL] retain];
        [self checkdebug];
    }
    return self;
}

- (instancetype)initWithMaskRunData:(NSData *)maskRunData
{
    NSMutableData *mutableMaskRunData = [maskRunData mutableCopy];
    
    qsort([mutableMaskRunData mutableBytes], [mutableMaskRunData length]/sizeof(NIMaskRun), sizeof(NIMaskRun), NIMaskQSortCompareRun);
    
    id maskRun = [self initWithSortedMaskRunData:mutableMaskRunData];
    [mutableMaskRunData release];
    return maskRun;
}

- (instancetype)initWithSortedMaskRunData:(NSData *)maskRunData
{
    if ( (self = [super init]) ) {
        _maskRunsData = [maskRunData retain];
        [self checkdebug];
    }
    return self;
}

- (instancetype)initWithSortedMaskRuns:(NSArray *)maskRuns
{
    if ( (self = [super init]) ) {
        _maskRuns = [maskRuns retain];
        [self checkdebug];
    }
    return self;
}

- (instancetype)initWithIndexes:(NSArray *)maskIndexes
{
    NSMutableData *maskData = [NSMutableData dataWithLength:[maskIndexes count] * sizeof(NIMaskIndex)];
    NIMaskIndex *maskIndexArray = [maskData mutableBytes];
    NSUInteger i;
    for (i = 0; i < [maskIndexes count]; i++) {
        maskIndexArray[i] = [[maskIndexes objectAtIndex:i] NIMaskIndexValue];
    }
    
    return [self initWithIndexData:maskData];
}

- (instancetype)initWithIndexData:(NSData *)indexData
{
    if ( (self = [super init]) ) {
        NIMaskIndex *indexes = (NIMaskIndex *)[indexData bytes];
        NSUInteger indexCount = [indexData length] / sizeof(NIMaskIndex);
        NSUInteger i;
        NSMutableArray *maskRuns = [NSMutableArray array];
        NIMaskRun maskRun = NIMaskRunZero;
        
        if (indexCount == 0) {
            _maskRuns = [[NSArray alloc] init];
            return self;
        }
        
        for (i = 0; i < indexCount; i++) {
            maskRun.widthRange.location = indexes[i].x;
            maskRun.widthRange.length = 1;
            maskRun.heightIndex = indexes[i].y;
            maskRun.depthIndex = indexes[i].z;
            [maskRuns addObject:[NSValue valueWithNIMaskRun:maskRun]];
        }
        
        
        NSArray *sortedMaskRuns = [maskRuns sortedArrayUsingFunction:NIMaskCompareRunValues context:NULL];
        NSMutableArray *newSortedRuns = [NSMutableArray array];
        
        maskRun = [[sortedMaskRuns objectAtIndex:0] NIMaskRunValue];
        
        for (i = 1; i < indexCount; i++) {
            NIMaskRun sortedRun = [[sortedMaskRuns objectAtIndex:i] NIMaskRunValue];
            
            if (NSMaxRange(maskRun.widthRange) == sortedRun.widthRange.location &&
                maskRun.heightIndex == sortedRun.heightIndex &&
                maskRun.depthIndex == sortedRun.depthIndex) {
                maskRun.widthRange.length++;
            } else if (NIMaskRunsOverlap(maskRun, sortedRun)) {
                NSLog(@"overlap?");
            } else {
                [newSortedRuns addObject:[NSValue valueWithNIMaskRun:maskRun]];
                maskRun = sortedRun;
            }
        }
        
        [newSortedRuns addObject:[NSValue valueWithNIMaskRun:maskRun]];
        _maskRuns = [newSortedRuns retain];
        [self checkdebug];
    }
    return self;
}

- (instancetype)initWithSortedIndexes:(NSArray *)maskIndexes
{
    NSMutableData *maskData = [NSMutableData dataWithLength:[maskIndexes count] * sizeof(NIMaskIndex)];
    NIMaskIndex *maskIndexArray = [maskData mutableBytes];
    NSUInteger i;
    for (i = 0; i < [maskIndexes count]; i++) {
        maskIndexArray[i] = [[maskIndexes objectAtIndex:i] NIMaskIndexValue];
    }
    
    return [self initWithSortedIndexData:maskData];
}

- (instancetype)initWithSortedIndexData:(NSData *)indexData
{
    if ( (self = [super init]) ) {
        NIMaskIndex *indexes = (NIMaskIndex *)[indexData bytes];
        NSUInteger indexCount = [indexData length];
        NSUInteger i;
        NSMutableArray *maskRuns = [NSMutableArray array];
        
        if (indexCount == 0) {
            _maskRuns = [[NSArray alloc] init];
            return self;
        }
        
        NIMaskRun maskRun = NIMaskRunZero;
        maskRun.widthRange.location = indexes[0].x;
        maskRun.widthRange.length = 1;
        maskRun.heightIndex = indexes[0].y;
        maskRun.depthIndex = indexes[0].z;
        
        for (i = 1; i < indexCount; i++) {
            if (maskRun.widthRange.location + 1 == indexes[i].x &&
                maskRun.heightIndex == indexes[1].y &&
                maskRun.depthIndex == indexes[1].z) {
                maskRun.widthRange.length++;
            } else {
                [maskRuns addObject:[NSValue valueWithNIMaskRun:maskRun]];
                maskRun.widthRange.location = indexes[i].x;
                maskRun.widthRange.length = 1;
                maskRun.heightIndex = indexes[i].y;
                maskRun.depthIndex = indexes[i].z;
            }
        }
        
        [maskRuns addObject:[NSValue valueWithNIMaskRun:maskRun]];
        _maskRuns = [maskRuns retain];
        [self checkdebug];
    }
    return self;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    NSData *maskRunsData = [NIMask maskRunsDataFromStorageData:[aDecoder decodeObjectOfClass:[NSData class] forKey:@"maskRunsData"]];
    return [self initWithSortedMaskRunData:maskRunsData];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[NIMask storageDataFromMaskRunData:[self maskRunsData]] forKey:@"maskRunsData"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithSortedMaskRunData:[[[self maskRunsData] copy] autorelease]];
}

- (void)dealloc
{
    [_maskRunsData release];
    _maskRunsData = nil;
    [_maskRuns release];
    _maskRuns = nil;
    
    [super dealloc];
}

+ (NSData *)storageDataFromMaskRunData:(NSData *)maskRunsData
{
    if ([maskRunsData length] == 0) {
        return maskRunsData;
    }

#if defined(__LITTLE_ENDIAN__)

#if __LP64__
    return maskRunsData;
#else
    NSUInteger maskRunCount = [maskRunsData length]/sizeof(NIMaskRun);
    struct maskRun64bit {
        unsigned long widthRangeLocation;
        unsigned long widthRangeLength;
        unsigned long heightIndex;
        unsigned long depthIndex;
        float intensity;
        int32_t padding;
    };
    struct maskRun64bit *storedData = malloc(sizeof(struct maskRun64bit) * maskRunCount);
    memset(storedData, 0, sizeof(struct maskRun64bit) * maskRunCount);
    const NIMaskRun *maskRuns = [maskRunsData bytes];
    NSUInteger i;
    for (i = 0; i < maskRunCount; i++) {
        storedData[i].widthRangeLocation = (unsigned long)maskRuns[i].widthRange.location;
        storedData[i].widthRangeLength = (unsigned long)maskRuns[i].widthRange.length;
        storedData[i].heightIndex = (unsigned long)maskRuns[i].heightIndex;
        storedData[i].depthIndex = (unsigned long)maskRuns[i].depthIndex;
        storedData[i].intensity = (float)maskRuns[i].intensity;
    }

    return [NSData dataWithBytesNoCopy:storedData length:sizeof(struct maskRun64bit) * maskRunCount freeWhenDone:YES];
#endif

#else
#error "byte swapping for NIMaskRun not implemented for big endian"
#endif
}

+ (NSData *)maskRunsDataFromStorageData:(NSData *)storageData
{
    if ([storageData length] == 0) {
        return storageData;
    }

#if defined(__LITTLE_ENDIAN__)

#if __LP64__
    return storageData;
#else
    struct maskRun64bit {
        unsigned long widthRangeLocation;
        unsigned long widthRangeLength;
        unsigned long heightIndex;
        unsigned long depthIndex;
        float intensity;
        int32_t padding;
    };
    NSUInteger maskRunCount = [storageData length]/sizeof(struct maskRun64bit);

    const struct maskRun64bit *storedDataBytes = [storageData bytes];
    NIMaskRun *maskRunDataBytes = malloc(sizeof(NIMaskRun) * maskRunCount);
    memset(maskRunDataBytes, 0, sizeof(NIMaskRun) * maskRunCount);
    NSUInteger i;
    for (i = 0; i < maskRunCount; i++) {
        maskRunDataBytes[i].widthRange.location = (NSUInteger)storedDataBytes[i].widthRangeLocation;
        maskRunDataBytes[i].widthRange.length = (NSUInteger)storedDataBytes[i].widthRangeLength;
        maskRunDataBytes[i].heightIndex = (NSUInteger)storedDataBytes[i].heightIndex;
        maskRunDataBytes[i].depthIndex = (NSUInteger)storedDataBytes[i].depthIndex;
        maskRunDataBytes[i].intensity = (float)storedDataBytes[i].intensity;
    }

    return [NSData dataWithBytesNoCopy:maskRunDataBytes length:sizeof(NIMaskRun) * maskRunCount freeWhenDone:YES];
#endif

#else
#error "byte swapping for NIMaskRun not implemented for big endian"
#endif
}

- (NIMask *)maskByTranslatingByX:(NSInteger)x Y:(NSInteger)y Z:(NSInteger)z
{
    const NIMaskRun *maskRuns = (const NIMaskRun *)[[self maskRunsData] bytes];
    NSInteger maskRunCount = [self maskRunCount];
    
    NIMaskRun *newMaskRuns = malloc(maskRunCount * sizeof(NIMaskRun));
    memset(newMaskRuns, 0, maskRunCount * sizeof(NIMaskRun));
    NSUInteger newMaskRunsIndex = 0;
    NSUInteger i;
    
    for (i = 0; i < maskRunCount; i++) {
        if ((NSInteger)NIMaskRunLastWidthIndex(maskRuns[i]) >= -x &&
            (NSInteger)maskRuns[i].heightIndex >= -y &&
            (NSInteger)maskRuns[i].depthIndex >= -z) {
            
            newMaskRuns[newMaskRunsIndex] = maskRuns[i];
            
            if ((NSInteger)NIMaskRunFirstWidthIndex(newMaskRuns[newMaskRunsIndex]) < -x) {
                newMaskRuns[newMaskRunsIndex].widthRange.length += x + (NSInteger)NIMaskRunFirstWidthIndex(newMaskRuns[newMaskRunsIndex]);
                newMaskRuns[newMaskRunsIndex].widthRange.location = 0;
            } else {
                newMaskRuns[newMaskRunsIndex].widthRange.location += x;
            }
            
            newMaskRuns[newMaskRunsIndex].heightIndex += y;
            newMaskRuns[newMaskRunsIndex].depthIndex += z;
            
            newMaskRunsIndex++;
        }
    }
    
    if (newMaskRunsIndex < maskRunCount)
        newMaskRuns = realloc(newMaskRuns, MAX(newMaskRunsIndex, 1) * sizeof(NIMaskRun)); // the MAX bit avoids an Analyze warning: Call to 'realloc' has an allocation size of 0 bytes
    
    return [[[NIMask alloc] initWithSortedMaskRunData:[NSData dataWithBytesNoCopy:newMaskRuns length:newMaskRunsIndex * sizeof(NIMaskRun) freeWhenDone:YES]] autorelease];
}

- (NIMask *)maskByIntersectingWithMask:(NIMask *)otherMask
{
    return [self maskBySubtractingMask:[self maskBySubtractingMask:otherMask]];
}

- (NIMask *)maskByUnioningWithMask:(NIMask *)otherMask
{
    NSUInteger index1 = 0;
    NSUInteger index2 = 0;
    
    //    NIMaskRun run1;
    //    NIMaskRun run2;
    
    NIMaskRun runToAdd = NIMaskRunZero;
    NIMaskRun accumulatedRun = NIMaskRunZero;
    accumulatedRun.widthRange.length = 0;
    
    NSData *maskRun1Data = [self maskRunsData];
    NSData *maskRun2Data = [otherMask maskRunsData];
    const NIMaskRun *maskRunArray1 = [maskRun1Data bytes];
    const NIMaskRun *maskRunArray2 = [maskRun2Data bytes];
    
    NSMutableData *resultMaskRuns = [NSMutableData data];
    
    
    while (index1 < [self maskRunCount] || index2 < [otherMask maskRunCount]) {
        if (index1 < [self maskRunCount] && index2 < [otherMask maskRunCount]) {
            if (NIMaskCompareRun(maskRunArray1[index1], maskRunArray2[index2]) == NSOrderedAscending) {
                runToAdd = maskRunArray1[index1];
                index1++;
            } else {
                runToAdd = maskRunArray2[index2];
                index2++;
            }
        } else if (index1 < [self maskRunCount]) {
            runToAdd = maskRunArray1[index1];
            index1++;
        } else {
            runToAdd = maskRunArray2[index2];
            index2++;
        }
        
        if (accumulatedRun.widthRange.length == 0) {
            accumulatedRun = runToAdd;
        } else if (NIMaskRunsOverlap(runToAdd, accumulatedRun) || NIMaskRunsAbut(runToAdd, accumulatedRun)) {
            if (NSMaxRange(runToAdd.widthRange) > NSMaxRange(accumulatedRun.widthRange)) {
                accumulatedRun.widthRange.length = NSMaxRange(runToAdd.widthRange) - accumulatedRun.widthRange.location;
            }
        } else {
            [resultMaskRuns appendBytes:&accumulatedRun length:sizeof(NIMaskRun)];
            accumulatedRun = runToAdd;
        }
    }
    
    if (accumulatedRun.widthRange.length != 0) {
        [resultMaskRuns appendBytes:&accumulatedRun length:sizeof(NIMaskRun)];
    }
    
    return [[[NIMask alloc] initWithSortedMaskRunData:resultMaskRuns] autorelease];
}

- (NIVolumeData *)volumeDataRepresentationWithModelToVoxelTransform:(NIAffineTransform)modelToVoxelTransform;
{
    NSUInteger maxHeight = NSIntegerMin;
    NSUInteger minHeight = NSIntegerMax;
    NSUInteger maxDepth = NSIntegerMin;
    NSUInteger minDepth = NSIntegerMax;
    NSUInteger maxWidth = NSIntegerMin;
    NSUInteger minWidth = NSIntegerMax;
    
    [self extentMinWidth:&minWidth maxWidth:&maxWidth minHeight:&minHeight maxHeight:&maxHeight minDepth:&minDepth maxDepth:&maxDepth];
    
    NSUInteger width = (maxWidth - minWidth) + 1;
    NSUInteger height = (maxHeight - minHeight) + 1;
    NSUInteger depth = (maxDepth - minDepth) + 1;
    
    float *floatBytes = calloc(width * height * depth, sizeof(float));
    if (floatBytes == 0) {
        NSLog(@"%s wasn't able to allocate a buffer of size %ld", __PRETTY_FUNCTION__, width * height * depth * sizeof(float));
        return nil;
    }
    
    NIMaskRun *maskRuns = (NIMaskRun *)[[self maskRunsData] bytes];
    NSInteger maskRunCount = [self maskRunCount];
    NSInteger i;
    
    // draw in the runs
    for (i = 0; i < maskRunCount; i++) {
        NSInteger x = maskRuns[i].widthRange.location - minWidth;
        NSInteger y = maskRuns[i].heightIndex - minHeight;
        NSInteger z = maskRuns[i].depthIndex - minDepth;
        
        vDSP_vfill(&(maskRuns[i].intensity), &(floatBytes[x + y*width + z*width*height]), 1, maskRuns[i].widthRange.length);
    }
    NSData *floatData = [NSData dataWithBytesNoCopy:floatBytes length:width * height * depth * sizeof(float)];
    
    // since we shifted the data, we need to shift the modelToVoxelTransform as well.
    NIAffineTransform shiftedTransform = NIAffineTransformConcat(modelToVoxelTransform, NIAffineTransformMakeTranslation(-1.0*(CGFloat)minWidth, -1.0*(CGFloat)minHeight, -1.0*(CGFloat)minDepth));
    
    return [[[NIVolumeData alloc] initWithData:floatData pixelsWide:width pixelsHigh:height pixelsDeep:depth modelToVoxelTransform:shiftedTransform outOfBoundsValue:0] autorelease];
}

- (NIMask *)maskBySubtractingMask:(NIMask *)subtractMask
{
    NIMaskRunStack *templateRunStack = [[NIMaskRunStack alloc] initWithMaskRunData:[self maskRunsData]];
    NIMaskRun newMaskRun;
    NSUInteger length;
    
    NSUInteger subtractIndex = 0;
    NSData *subtractData = [subtractMask maskRunsData];
    NSInteger subtractDataCount = [subtractData length]/sizeof(NIMaskRun);
    const NIMaskRun *subtractRunArray = [subtractData bytes];
    
    NSMutableData *resultMaskRuns = [NSMutableData data];
    NIMaskRun tempMaskRun;
    
    while (subtractIndex < subtractDataCount && [templateRunStack count]) {
        if (NIMaskRunsOverlap([templateRunStack currentMaskRun], subtractRunArray[subtractIndex]) == NO) {
            if (NIMaskCompareRun([templateRunStack currentMaskRun], subtractRunArray[subtractIndex]) == NSOrderedAscending) {
                tempMaskRun = [templateRunStack currentMaskRun];
                [resultMaskRuns appendBytes:&tempMaskRun length:sizeof(NIMaskRun)];
                [templateRunStack popMaskRun];
            } else {
                subtractIndex++;
            }
        } else {
            // run the 4 cases
            if (NSLocationInRange([templateRunStack currentMaskRun].widthRange.location, subtractRunArray[subtractIndex].widthRange)) {
                if (NSLocationInRange(NSMaxRange([templateRunStack currentMaskRun].widthRange) - 1, subtractRunArray[subtractIndex].widthRange)) {
                    // 1.
                    [templateRunStack popMaskRun];
                } else {
                    // 2.
                    newMaskRun = [templateRunStack currentMaskRun];
                    length = NSIntersectionRange([templateRunStack currentMaskRun].widthRange, subtractRunArray[subtractIndex].widthRange).length;
                    newMaskRun.widthRange.location += length;
                    newMaskRun.widthRange.length -= length;
                    [templateRunStack popMaskRun];
                    [templateRunStack pushMaskRun:newMaskRun];
                    assert(newMaskRun.widthRange.length > 0);
                }
            } else {
                if (NSLocationInRange(NSMaxRange([templateRunStack currentMaskRun].widthRange) - 1, subtractRunArray[subtractIndex].widthRange)) {
                    // 4.
                    newMaskRun = [templateRunStack currentMaskRun];
                    length = NSIntersectionRange([templateRunStack currentMaskRun].widthRange, subtractRunArray[subtractIndex].widthRange).length;
                    newMaskRun.widthRange.length -= length;
                    [templateRunStack popMaskRun];
                    [templateRunStack pushMaskRun:newMaskRun];
                    assert(newMaskRun.widthRange.length > 0);
                } else {
                    // 3.
                    NIMaskRun originalMaskRun = [templateRunStack currentMaskRun];
                    [templateRunStack popMaskRun];
                    
                    newMaskRun = originalMaskRun;
                    length = NSMaxRange(subtractRunArray[subtractIndex].widthRange) - originalMaskRun.widthRange.location;
                    newMaskRun.widthRange.location += length;
                    newMaskRun.widthRange.length -= length;
                    [templateRunStack pushMaskRun:newMaskRun];
                    assert(newMaskRun.widthRange.length > 0);
                    
                    
                    newMaskRun = originalMaskRun;
                    length = NSMaxRange(originalMaskRun.widthRange) - subtractRunArray[subtractIndex].widthRange.location;
                    newMaskRun.widthRange.length -= length;
                    [templateRunStack pushMaskRun:newMaskRun];
                    assert(newMaskRun.widthRange.length > 0);
                }
            }
        }
    }
    
    while ([templateRunStack count]) {
        tempMaskRun = [templateRunStack currentMaskRun];
        [resultMaskRuns appendBytes:&tempMaskRun length:sizeof(NIMaskRun)];
        [templateRunStack popMaskRun];
    }
    
    [templateRunStack release];
    return [[[NIMask alloc] initWithSortedMaskRunData:resultMaskRuns] autorelease];
}

- (NIMask *)maskCroppedToWidth:(NSUInteger)width height:(NSUInteger)height depth:(NSUInteger)depth
{
    const NIMaskRun *maskRuns = (const NIMaskRun *)[[self maskRunsData] bytes];
    NSInteger maskRunCount = [self maskRunCount];
    NSInteger i;
    NSUInteger badRuns = 0; // runs that are totally outside the bounds
    NSUInteger clippedRuns = 0; // runs that are partially outside the bounds and will need to be clipped
    
    for (i = 0; i < maskRunCount; i++) {
        if (NIMaskRunFirstWidthIndex(maskRuns[i]) >= width || maskRuns[i].heightIndex >= height || maskRuns[i].depthIndex >= depth) {
            badRuns++;
        } else if (NIMaskRunLastWidthIndex(maskRuns[i]) >= width) {
            clippedRuns++;
        }
    }
    
    if (badRuns + clippedRuns == 0) {
        return self;
    }
    
    NSUInteger newMaskRunsCount = maskRunCount - badRuns;
    
    if (newMaskRunsCount == 0) {
        return [NIMask mask];
    }
    
    NIMaskRun *newMaskRuns = malloc(newMaskRunsCount * sizeof(NIMaskRun));
    memset(newMaskRuns, 0, newMaskRunsCount * sizeof(NIMaskRun));
    NSUInteger newMaskRunsIndex = 0;
    
    for (i = 0; i < maskRunCount; i++) {
        if (NIMaskRunFirstWidthIndex(maskRuns[i]) < width &&
            maskRuns[i].heightIndex < height &&
            maskRuns[i].depthIndex < depth) {
            
            newMaskRuns[newMaskRunsIndex] = maskRuns[i];
            
            if (NIMaskRunLastWidthIndex(maskRuns[i]) >= width) {
                newMaskRuns[newMaskRunsIndex].widthRange.length = (width - newMaskRuns[newMaskRunsIndex].widthRange.location);
            }
            newMaskRunsIndex++;
        }
    }
    
    return [[[NIMask alloc] initWithSortedMaskRunData:[NSData dataWithBytesNoCopy:newMaskRuns length:newMaskRunsCount * sizeof(NIMaskRun) freeWhenDone:YES]] autorelease];
}

- (NIMask*)binaryMask
{
    return [self binaryMaskWithThreashold:0.5];
}

- (NIMask*)binaryMaskWithThreashold:(CGFloat)threshold
{
    NSMutableArray *newMaskArray = [NSMutableArray array];
    
    for (NSValue *maskRunValue in [self maskRuns]) {
        NIMaskRun maskRun = [maskRunValue NIMaskRunValue];
        if (maskRun.intensity >= threshold) {
            maskRun.intensity = 1;
            [newMaskArray addObject:[NSValue valueWithNIMaskRun:maskRun]];
        }
    }
    
    NIMask *filteredMask = [[[NIMask alloc] initWithSortedMaskRuns:newMaskArray] autorelease];
    [filteredMask checkdebug];
    return filteredMask;
}

- (BOOL)intersectsMask:(NIMask *)otherMask // probably could use a faster implementation...
{
    NIMask *intersection = [self maskByIntersectingWithMask:otherMask];
    return [intersection maskRunCount] > 0;
}

- (BOOL)isEqualToMask:(NIMask *)otherMask // super lazy implementation FIXME!
{
    NIMask *intersection = [self maskByIntersectingWithMask:otherMask];
    NIMask *subMask1 = [self maskBySubtractingMask:intersection];
    NIMask *subMask2 = [otherMask maskBySubtractingMask:intersection];
    
    return [subMask1 maskRunCount] == 0 && [subMask2 maskRunCount] == 0;
}

- (NIMask *)filteredMaskUsingPredicate:(NSPredicate *)predicate volumeData:(NIVolumeData *)volumeData
{
    NSMutableArray *newMaskArray = [NSMutableArray array];
    NIMaskRun activeMaskRun = NIMaskRunZero;
    BOOL isMaskRunActive = NO;
    float intensity;
    NIMaskIndexPredicateStandIn *standIn = [[[NIMaskIndexPredicateStandIn alloc] init] autorelease];
    
    for (NSValue *maskRunValue in [self maskRuns]) {
        NIMaskRun maskRun = [maskRunValue NIMaskRunValue];
        
        NIMaskIndex maskIndex;
        maskIndex.y = maskRun.heightIndex;
        maskIndex.z = maskRun.depthIndex;
        
        standIn.maskIntensity = maskRun.intensity;
        standIn.maskIndexY = maskIndex.y;
        standIn.maskIndexZ = maskIndex.z;
        
        for (maskIndex.x = maskRun.widthRange.location; maskIndex.x < NSMaxRange(maskRun.widthRange); maskIndex.x++) {
            intensity = [volumeData floatAtPixelCoordinateX:maskIndex.x y:maskIndex.y z:maskIndex.z];
            standIn.maskIndexX = maskIndex.x;
            standIn.intensity = intensity;
            
            if ([predicate evaluateWithObject:standIn]) {
                if (isMaskRunActive) {
                    activeMaskRun.widthRange.length++;
                } else {
                    activeMaskRun.widthRange.location = maskIndex.x;
                    activeMaskRun.widthRange.length = 1;
                    activeMaskRun.heightIndex = maskIndex.y;
                    activeMaskRun.depthIndex = maskIndex.z;
                    activeMaskRun.intensity = maskRun.intensity;
                    isMaskRunActive = YES;
                }
            } else {
                if (isMaskRunActive) {
                    [newMaskArray addObject:[NSValue valueWithNIMaskRun:activeMaskRun]];
                    isMaskRunActive = NO;
                }
            }
        }
        if (isMaskRunActive) {
            [newMaskArray addObject:[NSValue valueWithNIMaskRun:activeMaskRun]];
            isMaskRunActive = NO;
        }
    }
    
    NIMask *filteredMask = [[[NIMask alloc] initWithSortedMaskRuns:newMaskArray] autorelease];
    [filteredMask checkdebug];
    return filteredMask;
}

- (NSArray *)maskRuns
{
    if (_maskRuns == nil) {
        NSUInteger maskRunCount = [_maskRunsData length]/sizeof(NIMaskRun);
        const NIMaskRun *maskRunArray = [_maskRunsData bytes];
        NSMutableArray *maskRuns = [[NSMutableArray alloc] initWithCapacity:maskRunCount];
        NSUInteger i;
        for (i = 0; i < maskRunCount; i++) {
            [maskRuns addObject:[NSValue valueWithNIMaskRun:maskRunArray[i]]];
        }
        _maskRuns = maskRuns;
    }
    
    return _maskRuns;
}

- (NSData *)maskRunsData
{
    NIMaskRun *maskRunArray;
    NSInteger i;
    
    if (_maskRunsData == nil) {
        maskRunArray = malloc([_maskRuns count] * sizeof(NIMaskRun));
        
        for (i = 0; i < [_maskRuns count]; i++) {
            maskRunArray[i] = [[_maskRuns objectAtIndex:i] NIMaskRunValue];
        }
        
        _maskRunsData = [[NSData alloc] initWithBytesNoCopy:maskRunArray length:[_maskRuns count] * sizeof(NIMaskRun) freeWhenDone:YES];
    }
    
    return _maskRunsData;
}

- (NSUInteger)maskRunCount
{
    if (_maskRuns) {
        return [_maskRuns count];
    } else {
        return [_maskRunsData length] / sizeof(NIMaskRun);
    }
}

- (NSUInteger)maskIndexCount
{
    NSData *maskRunData = [self maskRunsData];
    const NIMaskRun *maskRunArray = [maskRunData bytes];
    NSUInteger maskRunCount = [self maskRunCount];
    NSUInteger maskIndexCount = 0;
    NSUInteger i = 0;
    
    for (i = 0; i < maskRunCount; i++) {
        maskIndexCount += maskRunArray[i].widthRange.length;
    }
    
    return maskIndexCount;
}

- (NSArray *)maskIndexes
{
    NSValue *maskRunValue;
    NSMutableArray *indexes;
    NIMaskRun maskRun;
    
    indexes = [NSMutableArray array];
    
    for (maskRunValue in [self maskRuns]) {
        maskRun = [maskRunValue NIMaskRunValue];
        if (maskRun.intensity) {
            [indexes addObjectsFromArray:NIMaskIndexesInRun(maskRun)];
        }
    }
    
    return indexes;
}

- (BOOL)indexInMask:(NIMaskIndex)index
{
    return [self containsIndex:index];
}

- (BOOL)containsIndex:(NIMaskIndex)index;
{
    // since the runs are sorted, we can binary search
    NSUInteger runIndex = 0;
    NSUInteger runCount = 0;
    
    NSData *maskRunsData = [self maskRunsData];
    const NIMaskRun *maskRuns = [maskRunsData bytes];
    runCount = [self maskRunCount];
    
    while (runCount) {
        NSUInteger middleIndex = runIndex + (runCount / 2);
        if (NIMaskIndexInRun(index, maskRuns[middleIndex])) {
            return YES;
        }
        
        BOOL before = NO;
        if (index.z < maskRuns[middleIndex].depthIndex) {
            before = YES;
        } else if (index.z == maskRuns[middleIndex].depthIndex && index.y < maskRuns[middleIndex].heightIndex) {
            before = YES;
        } else if (index.z == maskRuns[middleIndex].depthIndex && index.y == maskRuns[middleIndex].heightIndex && index.x < maskRuns[middleIndex].widthRange.location) {
            before = YES;
        }
        
        if (before) {
            runCount /= 2;
        } else {
            runIndex = middleIndex + 1;
            runCount = (runCount - 1) / 2;
        }
    }
    
    return NO;
}

+ (instancetype)maskByResamplingFromVolumeData:(NIVolumeData *)volumeData toModelToVoxelTransform:(NIAffineTransform)toModelToVoxelTransform interpolationMode:(NIInterpolationMode)interpolationsMode
{
    NIMask *resampledMask = nil;
    NIAffineTransform toMaskTransform = NIAffineTransformIdentity;
    NIVector shift = NIVectorZero;

    @autoreleasepool {
        NIVolumeData *toVolumeData = [volumeData volumeDataResampledWithModelToVoxelTransform:toModelToVoxelTransform interpolationMode:interpolationsMode];
        resampledMask = [NIMask maskFromVolumeData:toVolumeData modelToVoxelTransform:&toMaskTransform];

        // volumeDataResampledWithModelToVoxelTransform can shift the data so that it doesn't store more than it needs to, so figure out how much the shift was, and translate the mask so that is is at the right place
        shift = NIVectorApplyTransform(NIVectorZero, NIAffineTransformConcat(NIAffineTransformInvert(toModelToVoxelTransform), toMaskTransform));

#if CGFLOAT_IS_DOUBLE
        shift.x = round(shift.x);
        shift.y = round(shift.y);
        shift.z = round(shift.z);
#else
        shift.x = roundf(shift.x);
        shift.y = roundf(shift.y);
        shift.z = roundf(shift.z);
#endif

        resampledMask = [[resampledMask maskByTranslatingByX:(NSInteger)-shift.x Y:(NSInteger)-shift.y Z:(NSInteger)-shift.z] retain];
    }

    return [resampledMask autorelease];

}

- (instancetype)maskByResamplingFromModelToVoxelTransform:(NIAffineTransform)fromTransform toModelToVoxelTransform:(NIAffineTransform)toModelToVoxelTransform interpolationMode:(NIInterpolationMode)interpolationsMode
{
    if (NIAffineTransformEqualToTransform(fromTransform, toModelToVoxelTransform)) {
        return self;
    }
    
    if ([self maskRunCount] == 0) {
        return self;
    }

    NIMask *resampledMask = nil;

    // The implementation of this function can be made a lot less memory demanding my only sampling one slice at a time instead of the whole volume
    @autoreleasepool {
        NIVolumeData *fromVolumeData = [self volumeDataRepresentationWithModelToVoxelTransform:fromTransform];
        resampledMask = [[NIMask maskByResamplingFromVolumeData:fromVolumeData toModelToVoxelTransform:toModelToVoxelTransform interpolationMode:interpolationsMode] retain];
    }

    return [resampledMask autorelease];
}


- (void)extentMinWidth:(NSUInteger*)minWidthPtr maxWidth:(NSUInteger*)maxWidthPtr minHeight:(NSUInteger*)minHeightPtr maxHeight:(NSUInteger*)maxHeightPtr minDepth:(NSUInteger*)minDepthPtr maxDepth:(NSUInteger*)maxDepthPtr;
{
    NSUInteger maxWidth = 0;
    NSUInteger minWidth = NSUIntegerMax;
    NSUInteger maxHeight = 0;
    NSUInteger minHeight = NSUIntegerMax;
    NSUInteger maxDepth = 0;
    NSUInteger minDepth = NSUIntegerMax;
    
    NIMaskRun *maskRuns = (NIMaskRun *)[[self maskRunsData] bytes];
    NSInteger maskRunCount = [self maskRunCount];
    NSInteger i;
    
    if (maskRunCount == 0) {
        if (minWidthPtr) {
            *minWidthPtr = 0;
        }
        if (maxWidthPtr) {
            *maxWidthPtr = 0;
        }
        if (minHeightPtr) {
            *minHeightPtr = 0;
        }
        if (maxHeightPtr) {
            *maxHeightPtr = 0;
        }
        if (minDepthPtr) {
            *minDepthPtr = 0;
        }
        if (maxDepthPtr) {
            *maxDepthPtr = 0;
        }
        
        return;
    }
    
    for (i = 0; i < maskRunCount; i++) {
        maxWidth = MAX(maxWidth, (NSInteger)NIMaskRunLastWidthIndex(maskRuns[i]));
        minWidth = MIN(minWidth, (NSInteger)NIMaskRunFirstWidthIndex(maskRuns[i]));
        
        maxHeight = MAX(maxHeight, (NSInteger)maskRuns[i].heightIndex);
        minHeight = MIN(minHeight, (NSInteger)maskRuns[i].heightIndex);
        
        maxDepth = MAX(maxDepth, (NSInteger)maskRuns[i].depthIndex);
        minDepth = MIN(minDepth, (NSInteger)maskRuns[i].depthIndex);
    }
    
    if (minWidthPtr) {
        *minWidthPtr = minWidth;
    }
    if (maxWidthPtr) {
        *maxWidthPtr = maxWidth;
    }
    if (minHeightPtr) {
        *minHeightPtr = minHeight;
    }
    if (maxHeightPtr) {
        *maxHeightPtr = maxHeight;
    }
    if (minDepthPtr) {
        *minDepthPtr = minDepth;
    }
    if (maxDepthPtr) {
        *maxDepthPtr = maxDepth;
    }
}

- (NSArray *)convexHull
{
    NSUInteger maxHeight = NSIntegerMin;
    NSUInteger minHeight = NSIntegerMax;
    NSUInteger maxDepth = NSIntegerMin;
    NSUInteger minDepth = NSIntegerMax;
    NSUInteger maxWidth = NSIntegerMin;
    NSUInteger minWidth = NSIntegerMax;
    
    [self extentMinWidth:&minWidth maxWidth:&maxWidth minHeight:&minHeight maxHeight:&maxHeight minDepth:&minDepth maxDepth:&maxDepth];
    
    NSMutableArray *hull = [NSMutableArray arrayWithCapacity:8];
    [hull addObject:[NSValue valueWithNIVector:NIVectorMake(minWidth, minDepth, minHeight)]];
    [hull addObject:[NSValue valueWithNIVector:NIVectorMake(minWidth, maxDepth, minHeight)]];
    [hull addObject:[NSValue valueWithNIVector:NIVectorMake(maxWidth, maxDepth, minHeight)]];
    [hull addObject:[NSValue valueWithNIVector:NIVectorMake(maxWidth, minDepth, minHeight)]];
    [hull addObject:[NSValue valueWithNIVector:NIVectorMake(minWidth, minDepth, maxHeight)]];
    [hull addObject:[NSValue valueWithNIVector:NIVectorMake(minWidth, maxDepth, maxHeight)]];
    [hull addObject:[NSValue valueWithNIVector:NIVectorMake(maxWidth, maxDepth, maxHeight)]];
    [hull addObject:[NSValue valueWithNIVector:NIVectorMake(maxWidth, minDepth, maxHeight)]];
    
    return hull;
}

- (NIVector)centerOfMass
{
    NSData *maskData = [self maskRunsData];
    NSInteger runCount = [maskData length]/sizeof(NIMaskRun);
    const NIMaskRun *runArray = [maskData bytes];
    NSUInteger i;
    CGFloat floatCount = 0;
    NIVector centerOfMass = NIVectorZero;
    
    for (i = 0; i < runCount; i++) {
        centerOfMass.x += ((CGFloat)runArray[i].widthRange.location+((CGFloat)runArray[i].widthRange.length/2.0)) * (CGFloat)runArray[i].widthRange.length;
        centerOfMass.y += (CGFloat)runArray[i].heightIndex*(CGFloat)runArray[i].widthRange.length;
        centerOfMass.z += (CGFloat)runArray[i].depthIndex*(CGFloat)runArray[i].widthRange.length;
        floatCount += runArray[i].widthRange.length;
    }
    
    centerOfMass.x /= floatCount;
    centerOfMass.y /= floatCount;
    centerOfMass.z /= floatCount;
    
    return centerOfMass;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString string];
    [desc appendString:NSStringFromClass([self class])];
    [desc appendFormat:@"\nMask Run Count: %lld\n", (long long)[self maskRunCount]];
    [desc appendFormat:@"Index Count: %lld\n", (long long)[self maskIndexCount]];
    
    if ([self maskRunCount] > 0) {
        NSUInteger minWidth = 0;
        NSUInteger minHeight = 0;
        NSUInteger minDepth = 0;
        NSUInteger maxWidth = 0;
        NSUInteger maxHeight = 0;
        NSUInteger maxDepth = 0;
        [self extentMinWidth:&minWidth maxWidth:&maxWidth minHeight:&minHeight maxHeight:&maxHeight minDepth:&minDepth maxDepth:&maxDepth];
        [desc appendFormat:@"Width  Range: %4ld...%-4ld\n", (long )minWidth, (long)maxWidth];
        [desc appendFormat:@"Height Range: %4ld...%-4ld\n", (long )minHeight, (long)maxHeight];
        [desc appendFormat:@"Depth  Range: %4ld...%-4ld\n", (long )minDepth, (long)maxDepth];
    }
    
    [desc appendString:@"{\n"];
    
    NSUInteger maskRunsCount = [self maskRunCount];
    const NIMaskRun *maskRuns = [[self maskRunsData] bytes];
    NSUInteger i;
    
    for (i = 0; i < maskRunsCount; i++) {
        NSString* intensity = (maskRuns[i].intensity != 1? [NSString stringWithFormat:@" (%.2f)", maskRuns[i].intensity] : @"");
        if (maskRuns[i].widthRange.length != 1)
            [desc appendFormat:@"X:%4ld...%-4ld Y:%-4ld Z:%-4ld%@\n", (long)NIMaskRunFirstWidthIndex(maskRuns[i]), (long)NIMaskRunLastWidthIndex(maskRuns[i]), (long)maskRuns[i].heightIndex, (long)maskRuns[i].depthIndex, intensity];
        else [desc appendFormat:@"X:%-4ld Y:%-4ld Z:%-4ld%@\n", (long)NIMaskRunFirstWidthIndex(maskRuns[i]), (long)maskRuns[i].heightIndex, (long)maskRuns[i].depthIndex, intensity];
    }
    
    [desc appendString:@"}"];
    return desc;
}

- (void)checkdebug
{
#ifndef NDEBUG
    // make sure that all the runs are in order.
    assert(_maskRuns || _maskRunsData);
    NSInteger i;
    if (_maskRunsData) {
        NSInteger maskRunsDataCount = [_maskRunsData length]/sizeof(NIMaskRun);
        const NIMaskRun *maskRunArray = [_maskRunsData bytes];
        for (i = 0; i < (maskRunsDataCount - 1); i++) {
            assert(NIMaskCompareRun(maskRunArray[i], maskRunArray[i+1]) == NSOrderedAscending);
            assert(NIMaskRunsOverlap(maskRunArray[i], maskRunArray[i+1]) == NO);
        }
        for (i = 0; i < maskRunsDataCount; i++) {
            assert(maskRunArray[i].widthRange.length > 0);
        }
    }
    
    if (_maskRuns) {
        for (i = 0; i < ((NSInteger)[_maskRuns count]) - 1; i++) {
            assert(NIMaskCompareRunValues([_maskRuns objectAtIndex:i], [_maskRuns objectAtIndex:i+1], NULL) == NSOrderedAscending);
            assert(NIMaskRunsOverlap([[_maskRuns objectAtIndex:i] NIMaskRunValue], [[_maskRuns objectAtIndex:i+1] NIMaskRunValue]) == NO);
        }
        for (i = 0; i < [_maskRuns count]; i++) {
            assert([[_maskRuns objectAtIndex:i] NIMaskRunValue].widthRange.length > 0);
        }
    }
#endif
}





@end

@implementation NSValue (NIMaskRun)

+ (NSValue *)valueWithNIMaskRun:(NIMaskRun)volumeRun
{
    return [NSValue valueWithBytes:&volumeRun objCType:@encode(NIMaskRun)];
}

- (NIMaskRun)NIMaskRunValue
{
    NIMaskRun run;
    assert(strcmp([self objCType], @encode(NIMaskRun)) == 0);
    [self getValue:&run];
    return run;
}	

+ (NSValue *)valueWithNIMaskIndex:(NIMaskIndex)maskIndex
{
    return [NSValue valueWithBytes:&maskIndex objCType:@encode(NIMaskIndex)];
}

- (NIMaskIndex)NIMaskIndexValue
{
    NIMaskIndex index;
    assert(strcmp([self objCType], @encode(NIMaskIndex)) == 0);
    [self getValue:&index];
    return index;
}

@end



NSString *NSStringFromNIMaskRun(NIMaskRun run)
{
    NSMutableString* str = [NSMutableString stringWithFormat:@"{%lu", (unsigned long)run.widthRange.location];
    if (run.widthRange.length != 1)
        [str appendFormat:@"..%lu, ", (unsigned long)run.widthRange.location+run.widthRange.length];
    [str appendFormat:@", %lu, %lu", (unsigned long)run.heightIndex, (unsigned long)run.depthIndex];
    if (run.intensity != 1)
        [str appendFormat:@": %f", run.intensity];
    [str appendFormat:@"}"];
    return str;
}









