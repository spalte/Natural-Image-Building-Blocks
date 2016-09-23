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

#import "NIGeometry.h"
#import "NIVolumeData.h"

NS_ASSUME_NONNULL_BEGIN
/** A structure used to describe a single run length of a mask.
 
 */

struct NIMaskRun {
    NSRange widthRange;
    NSUInteger heightIndex;
    NSUInteger depthIndex;
    float intensity;
    int32_t _padding; // so that this struct stays on a 8 byte boundary in 64bit
};
typedef struct NIMaskRun NIMaskRun;


extern const NIMaskRun NIMaskRunZero;

/** Returns a newly created NIMaskRun
 
 */
NIMaskRun NIMaskRunMake(NSRange widthRange, NSUInteger heightIndex, NSUInteger depthIndex, float intensity);

/** Returns the first width index that is under the run.
 
 */
NSUInteger NIMaskRunFirstWidthIndex(NIMaskRun maskRun);

/** Returns the last width index that is under the run.
 
 */
NSUInteger NIMaskRunLastWidthIndex(NIMaskRun maskRun);

/** A structure used to describe a single point in a mask.
 
 */

struct NIMaskIndex {
    NSUInteger x;
    NSUInteger y;
    NSUInteger z;
};
typedef struct NIMaskIndex NIMaskIndex;

CF_EXTERN_C_BEGIN

extern const NIMaskIndex NIMaskIndexInvalid;

NIMaskIndex NIMaskIndexMake(NSUInteger x, NSUInteger y, NSUInteger z);
BOOL NIMaskIndexEqualToMaskIndex(NIMaskIndex mi1, NIMaskIndex mi2);

/** Transforms the maskIndex using the given transform, and returns an NIVector
 
 */
NIVector NIMaskIndexApplyTransform(NIMaskIndex maskIndex, NIAffineTransform transform);

/** Returns YES if the `maskIndex` is withing the `maskRun`
 
 */
BOOL NIMaskIndexInRun(NIMaskIndex maskIndex, NIMaskRun maskRun);
/** Returns an array of all the NIMaskIndex structs in the `maskRun`.
 
 */
NSArray *NIMaskIndexesInRun(NIMaskRun maskRun); // should this be a function, or a class method on NIMask?

/** Returns NSOrderedAscending if `maskRun2` is larger than `maskRun1`.
 
 */
NSComparisonResult NIMaskCompareRunValues(NSValue *maskRun1, NSValue *maskRun2, void * _Nullable context);

/** Returns a value larger than 0 if `maskRun2` is larger than `maskRun1`.
 
 */
NSComparisonResult NIMaskCompareRun(NIMaskRun maskRun1, NIMaskRun maskRun2);

/** Returns YES if the two mask runs overlap, NO otherwise.
 
 */
BOOL NIMaskRunsOverlap(NIMaskRun maskRun1, NIMaskRun maskRun2);

/** Returns YES if the two mask runs abut, NO otherwise.
 
 */
BOOL NIMaskRunsAbut(NIMaskRun maskRun1, NIMaskRun maskRun2);


CF_EXTERN_C_END

// masks are stored in width direction run lengths

/** `NIMask` instances represent a mask that can be applied to a volume. The Mask itself is stored as a set of individual mask runs.
 
 Stored masks use the following structs.
 
 `test`
 
 
 
 `struct NIMaskRun {`
 
 `NSRange widthRange;`
 
 `NSUInteger heightIndex;`
 
 `float intensity;`
 
 `};`
 
 `typedef struct NIMaskRun NIMaskRun;`
 
 `struct NIMaskIndex {`
 
 `NSUInteger x;`
 
 `NSUInteger y;`
 
 `NSUInteger z;`
 
 `};`
 
 `typedef struct NIMaskIndex NIMaskIndex;`
 
 Use the following functions are also available
 
 `BOOL NIMaskIndexInRun(NIMaskIndex maskIndex, NIMaskRun maskRun);`
 
 `NSArray *NIMaskIndexesInRun(NIMaskRun maskRun);`
 
 
 
 
 */

@interface NIMask : NSObject <NSCopying, NSSecureCoding> {
@private
    NSData *_maskRunsData;
    NSArray *_maskRuns;
}

///-----------------------------------
/// @name Creating Masks
///-----------------------------------

/** Returns a newly created empty mask.
 
 @return The newly crated and initialized mask object.
 */
+ (nullable instancetype)mask;

/** Returns a newly created mask that has the shape of a sphere with the specified diameter.
 
 @return The newly crated and initialized mask object.
 */
+ (nullable instancetype)maskWithSphereDiameter:(NSUInteger)diameter;

/** Returns a newly created mask that has the shape of a cube with the specified size.
 
 @return The newly crated and initialized mask object.
 */
+ (nullable instancetype)maskWithCubeSize:(NSUInteger)size;

/** Returns a newly created mask that has the shape of a box with the specified sizes.
 
 @return The newly crated and initialized mask object.
 */
+ (nullable instancetype)maskWithBoxWidth:(NSUInteger)width height:(NSUInteger)height depth:(NSUInteger)depth;

/** Returns a newly created mask that has the shape of an ellipsoid with the specified sizes.
 
 @return The newly crated and initialized mask object.
 */
+ (nullable instancetype)maskWithEllipsoidWidth:(NSUInteger)width height:(NSUInteger)height depth:(NSUInteger)depth;

/** Returns a mask formed by drawing the line from start to end.

 */
+ (nullable instancetype)maskWithLineFrom:(NIVector)start to:(NIVector)end;

/** Returns a newly created mask based on the intesities of the volumeData.
 
 The returned mask  is a mask on the volumeData with the intensities of the volumeData.
 
 @return The newly crated and initialized mask object or `nil` if there was a problem initializing the object.
 @param volumeData The NIVolumeData on which to build and base the mask.
 @param modelToVoxelTransformPtr Returns the transform needed to go from model space to the mask
 */
+ (nullable instancetype)maskFromVolumeData:(NIVolumeData *)volumeData modelToVoxelTransform:(nullable NIAffineTransformPointer)modelToVoxelTransformPtr;
+ (nullable instancetype)maskFromVolumeData:(NIVolumeData *)volumeData __deprecated;

/** Initializes and returns a newly created empty mask.
 
 Creates an empty mask.
 
 @return The initialized mask object.
 */
- (nullable instancetype)init NS_DESIGNATED_INITIALIZER;

// create the thing, maybe we should really be working with C arrays.... or at least give the option
/** Initializes and returns a newly created mask.
 
 Creates a mask based on the given individual runs.
 
 @return The initialized mask object or `nil` if there was a problem initializing the object.
 @param maskRuns An array of NIMaskRun structs in NSValues.
 */
- (nullable instancetype)initWithMaskRuns:(NSArray *)maskRuns;

/** Initializes and returns a newly created mask.
 
 Creates a mask based on the given individual runs.
 
 @return The initialized mask object or `nil` if there was a problem initializing the object.
 @param maskRunData is the serialized NIMaskRuns.
 */
- (nullable instancetype)initWithMaskRunData:(NSData *)maskRunData;

/** Initializes and returns a newly created mask.
 
 Creates a mask based on the given individual runs. The mask runs must be sorted.
 
 @return The initialized mask object or `nil` if there was a problem initializing the object.
 @param maskRunData is the serialized NIMaskRuns.
 */
- (nullable instancetype)initWithSortedMaskRunData:(NSData *)maskRunData;

// create the thing, maybe we should really be working with C arrays.... or at least give the option
/** Initializes and returns a newly created mask.
 
 Creates a mask based on the given individual runs. The mask runs must be sorted.
 
 @return The initialized mask object or `nil` if there was a problem initializing the object.
 @param maskRuns An array of NIMaskRun structs in NSValues.
 */
- (nullable instancetype)initWithSortedMaskRuns:(NSArray *)maskRuns;

/** Initializes and returns a newly created mask.
 
 Creates a mask based on the given individual indexes.
 
 @return The initialized mask object or `nil` if there was a problem initializing the object.
 @param maskIndexes An array of NIMaskIndex structs in NSValues.
 */
- (nullable instancetype)initWithIndexes:(NSArray *)maskIndexes;

/** Initializes and returns a newly created mask.
 
 Creates a mask based on the given individual indexes.
 
 @return The initialized mask object or `nil` if there was a problem initializing the object.
 @param indexData is the serialized NIMaskIndexes.
 */
- (nullable instancetype)initWithIndexData:(NSData *)indexData;

/** Initializes and returns a newly created mask.
 
 Creates a mask based on the given individual indexes. The mask indexes must be sorted.
 
 @return The initialized mask object or `nil` if there was a problem initializing the object.
 @param maskIndexes An array of NIMaskIndex structs in NSValues.
 */
- (nullable instancetype)initWithSortedIndexes:(NSArray *)maskIndexes;

/** Initializes and returns a newly created mask.
 
 Creates a mask based on the given individual indexes. The mask indexes must be sorted.
 
 @return The initialized mask object or `nil` if there was a problem initializing the object.
 @param indexData An array of NIMaskIndex structs in NSValues.
 */
- (nullable instancetype)initWithSortedIndexData:(NSData *)indexData;

///-----------------------------------
/// @name Working with the Mask
///-----------------------------------

/** Returns a mask made by translating the receiever by the given distances.
 
 */
- (NIMask *)maskByTranslatingByX:(NSInteger)x Y:(NSInteger)y Z:(NSInteger)z;

/** Returns a mask that represents the intersection of the receiver and the given mask .
 
 */
- (NIMask *)maskByIntersectingWithMask:(NIMask *)otherMask;

/** Returns a mask that represents the union of the receiver and the given mask .
 
 */
- (NIMask *)maskByUnioningWithMask:(NIMask *)otherMask;

/** Returns a mask formed by subtracting otherMask from the receiver.
 
 */
- (NIMask *)maskBySubtractingMask:(NIMask *)otherMask;

/** Returns a NIVolumeData filled with the intensities of the mask.
 
 */
- (nullable NIVolumeData *)volumeDataRepresentationWithModelToVoxelTransform:(NIAffineTransform)modelToVoxelTransform;

/** Returns a mask formed by cropping any indexes that are further out than the bounds specified from the receiver.

 */
- (NIMask *)maskCroppedToWidth:(NSUInteger)width height:(NSUInteger)height depth:(NSUInteger)depth;

/** Returns -[NIMask binaryMaskWithThreshold:0.5]
 
 */
- (NIMask*)binaryMask;

/** Returns a mask by filtering out all mask runs with intensity lower than the thresold, and changing kept mask run intensities to 1.
 
 */
- (NIMask*)binaryMaskWithThreashold:(CGFloat)threshold;

/** Returns YES if the two masks intersect.
 
 */
- (BOOL)intersectsMask:(NIMask *)otherMask;

/** Returns YES if the two masks are equal.
 
 */
- (BOOL)isEqualToMask:(NIMask *)otherMask;

/** Evaluates a given predicate against each pixel in the mask and returns a new mask containing the pixels for which the predicate returns true.
 
 The evaluated object used for the predicate responds to:
 -(float)intensity; The value of the pixel
 -(float)maskIntensity; The value of the intesity stored in the mask
 -(NSUInteger)maskIndexX;
 -(NSUInteger)maskIndexY;
 -(NSUInteger)maskIndexZ;
 
 @return The resulting mask after having applied the predicate to the receiver.
 */
- (NIMask *)filteredMaskUsingPredicate:(NSPredicate *)predicate volumeData:(NIVolumeData *)volumeData;

/** Returns the mask as a set ofNIMaskRun structs in NSValues.
 
 @return The mask as a set of NIMaskRun structs in NSValues.
 */
- (NSArray *)maskRuns;

/** Returns the mask as an NSData that contains a C array of NIMaskRun structs.
 
 @return The mask as an NSData that contains a C array of NIMaskRun structs.
 */
- (NSData *)maskRunsData;

/** Returns the count of mask runs.
 
 @return The count of mask runs.
 */
- (NSUInteger)maskRunCount;

/** Returns the mask as a set NIMaskIndex structs in NSValues.
 
 @return The mask as a set NIMaskIndex structs in NSValues.
 */
- (NSArray *)maskIndexes;

/** Returns the count of mask indexes.
 
 @return The count of mask index. (the number of voxels in the mask)
 */
- (NSUInteger)maskIndexCount;

/** Returns YES if the given index is within the mask.
 
 @return YES if the given index is within the mask.
 
 @param index NIMaskIndex struct to test.
 */
- (BOOL)containsIndex:(NIMaskIndex)index;
- (BOOL)indexInMask:(NIMaskIndex)index __deprecated;

/** Returns a mask that has been resampled from the volume to coordinates specified by toTransform.

 */
+ (instancetype)maskByResamplingFromVolumeData:(NIVolumeData *)volumeData toModelToVoxelTransform:(NIAffineTransform)toModelToVoxelTransform interpolationMode:(NIInterpolationMode)interpolationsMode;

/** Returns a mask that has been resampled from being in the volume as the position fromTransform to a mask that is in the volume at position toTransform.

 */
- (instancetype)maskByResamplingFromModelToVoxelTransform:(NIAffineTransform)fromModelToVoxelTransform toModelToVoxelTransform:(NIAffineTransform)toModelToVoxelTransform interpolationMode:(NIInterpolationMode)interpolationsMode;

/** Returns the extent of the receiver. All values are inclusive.
 
 */
- (void)extentMinWidth:(nullable NSUInteger*)minWidthPtr maxWidth:(nullable NSUInteger*)maxWidthPtr minHeight:(nullable NSUInteger*)minHeightPtr maxHeight:(nullable NSUInteger*)maxHeightPtr minDepth:(nullable NSUInteger*)minDepthPtr maxDepth:(nullable NSUInteger*)maxDepthPtr;

/** Returns an array of points that represent the outside bounds of the mask.
 
 @return An array of NIVectors stored at NSValues that represent the outside bounds of the mask.
 */
- (NSArray *)convexHull; // NIVectors stored in NSValue objects. The mask is inside of these points

/** Returns the center of mass of the mask.
 
 @return The center of mass of the mask.
 */
- (NIVector)centerOfMass;


@end


/** NSValue methods to handle Mask types.
 
 */

@interface NSValue (NIMaskRun)

///-----------------------------------
/// @name NIMaskRun methods
///-----------------------------------

/** Creates and returns an NSValue object that contains a given NIMaskRun structure.
 
 @return A new NSValue object that contains the value of volumeRun.
 @param volumeRun The value for the new object.
 */
+ (NSValue *)valueWithNIMaskRun:(NIMaskRun)volumeRun;

/** Returns an NIMaskRun structure representation of the receiver.
 
 @return An NIMaskRun structure representation of the receiver.
 */
@property (readonly) NIMaskRun NIMaskRunValue;

/** Creates and returns an NSValue object that contains a given NIMaskIndex structure.
 
 @return A new NSValue object that contains the value of maskIndex.
 @param maskIndex The value for the new object.
 */
+ (NSValue *)valueWithNIMaskIndex:(NIMaskIndex)maskIndex;

/** Returns an NIMaskIndex structure representation of the receiver.
 
 @return An NIMaskIndex structure representation of the receiver.
 */
@property (readonly) NIMaskIndex NIMaskIndexValue;

#if __has_attribute(objc_boxable)
typedef struct __attribute__((objc_boxable)) NIMaskRun NIMaskRun;
typedef struct __attribute__((objc_boxable)) NIMaskIndex NIMaskIndex;
#endif

@end

NSString *NSStringFromNIMaskRun(NIMaskRun run);

NS_ASSUME_NONNULL_END

