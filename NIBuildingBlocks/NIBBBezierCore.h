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

#ifndef _NIBBBEZIERCORE_H_
#define _NIBBBEZIERCORE_H_

#include <ApplicationServices/ApplicationServices.h>

#include "NIBBGeometry.h"

/* look in NIBBBezierCoreAdditions.h for additional functions that could be of interest */

CF_EXTERN_C_BEGIN

enum NIBBBezierCoreSegmentType {
    NIBBMoveToBezierCoreSegmentType,
    NIBBLineToBezierCoreSegmentType,
    NIBBCurveToBezierCoreSegmentType,
    NIBBCloseBezierCoreSegmentType,
    NIBBEndBezierCoreSegmentType = 0xFFFFFFFF
};
typedef enum NIBBBezierCoreSegmentType NIBBBezierCoreSegmentType;

extern const CFDictionaryValueCallBacks kNIBBBezierCoreDictionaryValueCallBacks;
extern const CFArrayCallBacks kNIBBBezierCoreArrayCallBacks;

extern const CGFloat NIBBBezierDefaultFlatness;
extern const CGFloat NIBBBezierDefaultSubdivideSegmentLength;

typedef const struct NIBBBezierCore *NIBBBezierCoreRef;
typedef struct NIBBBezierCore *NIBBMutableBezierCoreRef;
typedef struct NIBBBezierCoreIterator *NIBBBezierCoreIteratorRef;
typedef const struct NIBBBezierCoreRandomAccessor *NIBBBezierCoreRandomAccessorRef;

NIBBBezierCoreRef NIBBBezierCoreCreate();
NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutable();
void *NIBBBezierCoreRetain(NIBBBezierCoreRef bezierCore);
void NIBBBezierCoreRelease(NIBBBezierCoreRef bezierCore);
bool NIBBBezierCoreEqualToBezierCore(NIBBBezierCoreRef bezierCore1, NIBBBezierCoreRef bezierCore2);
CFStringRef NIBBBezierCoreCopyDescription(NIBBBezierCoreRef bezierCore);
bool NIBBBezierCoreHasCurve(NIBBBezierCoreRef bezierCore);

NIBBBezierCoreRef NIBBBezierCoreCreateCopy(NIBBBezierCoreRef bezierCore);
NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableCopy(NIBBBezierCoreRef bezierCore);

CFDictionaryRef NIBBBezierCoreCreateDictionaryRepresentation(NIBBBezierCoreRef bezierCore);
NIBBBezierCoreRef NIBBBezierCoreCreateWithDictionaryRepresentation(CFDictionaryRef dict);
NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableWithDictionaryRepresentation(CFDictionaryRef dict);

void NIBBBezierCoreAddSegment(NIBBMutableBezierCoreRef bezierCore, NIBBBezierCoreSegmentType segmentType, NIBBVector control1, NIBBVector control2, NIBBVector endpoint);
void NIBBBezierCoreSetVectorsForSegementAtIndex(NIBBMutableBezierCoreRef bezierCore, CFIndex index, NIBBVector control1, NIBBVector control2, NIBBVector endpoint);
void NIBBBezierCoreFlatten(NIBBMutableBezierCoreRef bezierCore, CGFloat flatness);
void NIBBBezierCoreSubdivide(NIBBMutableBezierCoreRef bezierCore, CGFloat maxSegementLength);
void NIBBBezierCoreApplyTransform(NIBBMutableBezierCoreRef bezierCore, NIBBAffineTransform transform);
void NIBBBezierCoreAppendBezierCore(NIBBMutableBezierCoreRef bezierCore, NIBBBezierCoreRef appenedBezier, bool connectPaths);

NIBBBezierCoreRef NIBBBezierCoreCreateFlattenedCopy(NIBBBezierCoreRef bezierCore, CGFloat flatness);
NIBBMutableBezierCoreRef NIBBBezierCoreCreateFlattenedMutableCopy(NIBBBezierCoreRef bezierCore, CGFloat flatness);
NIBBBezierCoreRef NIBBBezierCoreCreateSubdividedCopy(NIBBBezierCoreRef bezierCore, CGFloat maxSegementLength);
NIBBMutableBezierCoreRef NIBBBezierCoreCreateSubdividedMutableCopy(NIBBBezierCoreRef bezierCore, CGFloat maxSegementLength);
NIBBBezierCoreRef NIBBBezierCoreCreateTransformedCopy(NIBBBezierCoreRef bezierCore, NIBBAffineTransform transform);
NIBBMutableBezierCoreRef NIBBBezierCoreCreateTransformedMutableCopy(NIBBBezierCoreRef bezierCore, NIBBAffineTransform transform);

CFIndex NIBBBezierCoreSegmentCount(NIBBBezierCoreRef bezierCore);
CFIndex NIBBBezierCoreSubpathCount(NIBBBezierCoreRef bezierCore);
CGFloat NIBBBezierCoreLength(NIBBBezierCoreRef bezierCore);

/* This requires a traverse though a linked list on every call, if you care for speed use a BezierCoreIterator or a BezierCoreRandomAccessor */
NIBBBezierCoreSegmentType NIBBBezierCoreGetSegmentAtIndex(NIBBBezierCoreRef bezierCore, CFIndex index, NIBBVectorPointer control1, NIBBVectorPointer control2, NIBBVectorPointer endpoint);

/* Debug */
void NIBBBezierCoreCheckDebug(NIBBBezierCoreRef bezierCore);

/* BezierCoreIterator */

NIBBBezierCoreIteratorRef NIBBBezierCoreIteratorCreateWithBezierCore(NIBBBezierCoreRef bezierCore);
NIBBBezierCoreIteratorRef NIBBBezierCoreIteratorRetain(NIBBBezierCoreIteratorRef bezierCoreIterator);
void NIBBBezierCoreIteratorRelease(NIBBBezierCoreIteratorRef bezierCoreIterator);

NIBBBezierCoreSegmentType NIBBBezierCoreIteratorGetNextSegment(NIBBBezierCoreIteratorRef bezierCoreIterator, NIBBVectorPointer control1, NIBBVectorPointer control2, NIBBVectorPointer endpoint);

bool NIBBBezierCoreIteratorIsAtEnd(NIBBBezierCoreIteratorRef bezierCoreIterator);
CFIndex NIBBBezierCoreIteratorIndex(NIBBBezierCoreIteratorRef bezierCoreIterator);
void NIBBBezierCoreIteratorSetIndex(NIBBBezierCoreIteratorRef bezierCoreIterator, CFIndex index);
CFIndex NIBBBezierCoreIteratorSegmentCount(NIBBBezierCoreIteratorRef bezierCoreIterator);


/* BezierCoreRandomAccessor */
/* Caches pointers to each element of the linked list so iterating is O(n) not O(n^2) */

NIBBBezierCoreRandomAccessorRef NIBBBezierCoreRandomAccessorCreateWithBezierCore(NIBBBezierCoreRef bezierCore);
NIBBBezierCoreRandomAccessorRef NIBBBezierCoreRandomAccessorCreateWithMutableBezierCore(NIBBMutableBezierCoreRef bezierCore);
NIBBBezierCoreRandomAccessorRef NIBBBezierCoreRandomAccessorRetain(NIBBBezierCoreRandomAccessorRef bezierCoreRandomAccessor);
void NIBBBezierCoreRandomAccessorRelease(NIBBBezierCoreRandomAccessorRef bezierCoreRandomAccessor);

NIBBBezierCoreSegmentType NIBBBezierCoreRandomAccessorGetSegmentAtIndex(NIBBBezierCoreRandomAccessorRef bezierCoreRandomAccessor, CFIndex index, NIBBVectorPointer control1, NIBBVectorPointer control2, NIBBVectorPointer endpoint);
void NIBBBezierCoreRandomAccessorSetVectorsForSegementAtIndex(NIBBBezierCoreRandomAccessorRef bezierCoreRandomAccessor, CFIndex index, NIBBVector control1, NIBBVector control2, NIBBVector endpoint); // the random accessor must have been created with the mutable beziercore
CFIndex NIBBBezierCoreRandomAccessorSegmentCount(NIBBBezierCoreRandomAccessorRef bezierCoreRandomAccessor);

CF_EXTERN_C_END

#endif	/* _NIBBBEZIERCORE_H_ */
