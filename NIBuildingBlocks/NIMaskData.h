//  Copyright (c) 2017 Spaltenstein Natural Image
//  Copyright (c) 2017 OsiriX Foundation
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

#ifndef _NIMASKDATA_H_
#define _NIMASKDATA_H_

#import <Cocoa/Cocoa.h>
#import "NIMask.h"
// this is the representation of the data within the generic annotation

/**  
 
 The `NIMaskData` class is used to access pixel in a NIVolumeData instance data under a given NIMask.
 
 */


@class NIVolumeData;

@interface NIMaskData : NSObject {
    NSMutableDictionary *_valueCache;
    NSData *_floatData;
	NIMask *_mask;
	NIVolumeData *_volumeData;
}

///-----------------------------------
/// @name Creating annotation Float Pixel Data Objects
///-----------------------------------

/** Initializes and returns a newly created annotation Float Pixel Data Object.
 
 Creates a Float Pixel Data instance to access pixels covered by the given mask in the given Float Volume Data
	
 @return The initialized annotation Float Pixel Data object or `nil` if there was a problem initializing the object.
 
 @param mask the mask under which the receiver will access pixels.
 @param volumeData The Float Volume Data the receiver will use to access pixels.
 */

- (id)initWithMask:(NIMask *)mask volumeData:(NIVolumeData *)volumeData;

///-----------------------------------
/// @name Accessing Properties
///-----------------------------------

/** The receiver’s mask.
 */
@property (nonatomic, readonly, retain) NIMask *mask;
/** The receiver’s Float Volume Data.
 */
@property (nonatomic, readonly, retain) NIVolumeData *volumeData;

///-----------------------------------
/// @name Accessing Standard Metrics
///-----------------------------------

/** Returns the mean intensity of the pixels under the mask.
 
 @return The mean intensity of the pixels under the mask
 */
- (float)intensityMean;

/** Returns the maximum intensity of the pixels under the mask.
 
 @return The maximum intensity of the pixels under the mask
 */
- (float)intensityMax;

/** Returns the minumim intensity of the pixels under the mask.
 
 @return The minumim intensity of the pixels under the mask
 */
- (float)intensityMin;

/** Returns the median intensity of the pixels under the mask.
 
 @return The media intensity of the pixels under the mask
 */
- (float)intensityMedian;

/** Returns the interquartile range of the intensity of the pixels under the mask.
 
 @return The interquartile range of the intensity of the pixels under the mask
 */
- (float)intensityInterQuartileRange;

/** Returns the standard deviation of the intensity of the pixels under the mask.
 
 @return The standard deviation of the intensity of the pixels under the mask
 */
- (float)intensityStandardDeviation;

/** Returns by reference the quartiles of the intensity of the pixels under the mask. 
 
 Pass NULL to any parameter you don't care about
 
 */
- (void)getIntensityMinimum:(float *)minimum firstQuartile:(float *)firstQuartile secondQuartile:(float *)secondQuartile thirdQuartile:(float *)thirdQuartile maximum:(float *)maximum;


///-----------------------------------
/// @name Accessing Pixel Data
///-----------------------------------


/** Returns the number of pixels under the mask.
 
 @return The number of pixels under the mask.
 */
- (NSUInteger)floatCount;

/** Copies a number of floats from the start of the receiver's data into a given buffer
 
 This will copy `count * sizeof(float)` bytes into the given buffer.
 
 @return The number of floats copied.
 
 @param buffer A buffer into which to copy data.
 @param count The number of floats to copy.
 */
- (NSUInteger)getFloatData:(float *)buffer floatCount:(NSUInteger)count;

/** Returns a NSData containing the values of the reciever's data
  
 @return a NSData containing the values of the reciever's data.
 
 */
- (NSData *)floatData;


@end

#endif /* _NIMASKDATA_H_ */
