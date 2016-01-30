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

#ifndef _NIBEZIERCORE_H_
#define _NIBEZIERCORE_H_

#include <ApplicationServices/ApplicationServices.h>
#include <AppKit/NSBezierPath.h>

#include "NIGeometry.h"

/* look in NIBezierCoreAdditions.h for additional functions that could be of interest */

CF_EXTERN_C_BEGIN

enum NIBezierCoreSegmentType {
    NIMoveToBezierCoreSegmentType,
    NILineToBezierCoreSegmentType,
    NICurveToBezierCoreSegmentType,
    NICloseBezierCoreSegmentType,
    NIEndBezierCoreSegmentType = 0xFFFFFFFF
};
typedef enum NIBezierCoreSegmentType NIBezierCoreSegmentType;

extern const CFDictionaryValueCallBacks kNIBezierCoreDictionaryValueCallBacks;
extern const CFArrayCallBacks kNIBezierCoreArrayCallBacks;

extern const CGFloat NIBezierDefaultFlatness;
extern const CGFloat NIBezierDefaultSubdivideSegmentLength;

typedef const struct NIBezierCore *NIBezierCoreRef;
typedef struct NIBezierCore *NIMutableBezierCoreRef;
typedef struct NIBezierCoreIterator *NIBezierCoreIteratorRef;
typedef const struct NIBezierCoreRandomAccessor *NIBezierCoreRandomAccessorRef;

NIBezierCoreRef NIBezierCoreCreate();
NIMutableBezierCoreRef NIBezierCoreCreateMutable();
void *NIBezierCoreRetain(NIBezierCoreRef bezierCore);
void NIBezierCoreRelease(NIBezierCoreRef bezierCore);
bool NIBezierCoreEqualToBezierCore(NIBezierCoreRef bezierCore1, NIBezierCoreRef bezierCore2);
CFStringRef NIBezierCoreCopyDescription(NIBezierCoreRef bezierCore);
bool NIBezierCoreHasCurve(NIBezierCoreRef bezierCore);

NIBezierCoreRef NIBezierCoreCreateCopy(NIBezierCoreRef bezierCore);
NIMutableBezierCoreRef NIBezierCoreCreateMutableCopy(NIBezierCoreRef bezierCore);

CFDictionaryRef NIBezierCoreCreateDictionaryRepresentation(NIBezierCoreRef bezierCore);
NIBezierCoreRef NIBezierCoreCreateWithDictionaryRepresentation(CFDictionaryRef dict);
NIMutableBezierCoreRef NIBezierCoreCreateMutableWithDictionaryRepresentation(CFDictionaryRef dict);
NIMutableBezierCoreRef NIBezierCoreCreateMutableWithNSBezierPath(NSBezierPath* path);

void NIBezierCoreAddSegment(NIMutableBezierCoreRef bezierCore, NIBezierCoreSegmentType segmentType, NIVector control1, NIVector control2, NIVector endpoint);
void NIBezierCoreSetVectorsForSegmentAtIndex(NIMutableBezierCoreRef bezierCore, CFIndex index, NIVector control1, NIVector control2, NIVector endpoint);
void NIBezierCoreFlatten(NIMutableBezierCoreRef bezierCore, CGFloat flatness);
void NIBezierCoreSubdivide(NIMutableBezierCoreRef bezierCore, CGFloat maxSegementLength);
void NIBezierCoreSanitize(NIMutableBezierCoreRef bezierCore, CGFloat minSegmentLength); // removes segments that are shorter than minSegmentLength
void NIBezierCoreApplyTransform(NIMutableBezierCoreRef bezierCore, NIAffineTransform transform);
    
void NIBezierCoreAppendBezierCore(NIMutableBezierCoreRef bezierCore, NIBezierCoreRef appenedBezier, bool connectPaths);

NIBezierCoreRef NIBezierCoreCreateFlattenedCopy(NIBezierCoreRef bezierCore, CGFloat flatness);
NIMutableBezierCoreRef NIBezierCoreCreateFlattenedMutableCopy(NIBezierCoreRef bezierCore, CGFloat flatness);
NIBezierCoreRef NIBezierCoreCreateSubdividedCopy(NIBezierCoreRef bezierCore, CGFloat maxSegementLength);
NIMutableBezierCoreRef NIBezierCoreCreateSubdividedMutableCopy(NIBezierCoreRef bezierCore, CGFloat maxSegementLength);
NIBezierCoreRef NIBezierCoreCreateSanitizedCopy(NIBezierCoreRef bezierCore, CGFloat minSegementLength); // removes segments that are shorter than minSegmentLength
NIBezierCoreRef NIBezierCoreCreateSanitizedMutableCopy(NIBezierCoreRef bezierCore, CGFloat minSegementLength); // removes segments that are shorter than minSegmentLength
NIBezierCoreRef NIBezierCoreCreateTransformedCopy(NIBezierCoreRef bezierCore, NIAffineTransform transform);
NIMutableBezierCoreRef NIBezierCoreCreateTransformedMutableCopy(NIBezierCoreRef bezierCore, NIAffineTransform transform);

CFIndex NIBezierCoreSegmentCount(NIBezierCoreRef bezierCore);
CFIndex NIBezierCoreSubpathCount(NIBezierCoreRef bezierCore);
CGFloat NIBezierCoreLength(NIBezierCoreRef bezierCore);

/* This requires a traverse though a linked list on every call, if you care for speed use a BezierCoreIterator or a BezierCoreRandomAccessor */
NIBezierCoreSegmentType NIBezierCoreGetSegmentAtIndex(NIBezierCoreRef bezierCore, CFIndex index, NIVectorPointer control1, NIVectorPointer control2, NIVectorPointer endpoint);

/* Debug */
void NIBezierCoreCheckDebug(NIBezierCoreRef bezierCore);

/* BezierCoreIterator */

NIBezierCoreIteratorRef NIBezierCoreIteratorCreateWithBezierCore(NIBezierCoreRef bezierCore);
NIBezierCoreIteratorRef NIBezierCoreIteratorRetain(NIBezierCoreIteratorRef bezierCoreIterator);
void NIBezierCoreIteratorRelease(NIBezierCoreIteratorRef bezierCoreIterator);

NIBezierCoreSegmentType NIBezierCoreIteratorGetNextSegment(NIBezierCoreIteratorRef bezierCoreIterator, NIVectorPointer control1, NIVectorPointer control2, NIVectorPointer endpoint);

bool NIBezierCoreIteratorIsAtEnd(NIBezierCoreIteratorRef bezierCoreIterator);
CFIndex NIBezierCoreIteratorIndex(NIBezierCoreIteratorRef bezierCoreIterator);
void NIBezierCoreIteratorSetIndex(NIBezierCoreIteratorRef bezierCoreIterator, CFIndex index);
CFIndex NIBezierCoreIteratorSegmentCount(NIBezierCoreIteratorRef bezierCoreIterator);


/* BezierCoreRandomAccessor */
/* Caches pointers to each element of the linked list so iterating is O(n) not O(n^2) */

NIBezierCoreRandomAccessorRef NIBezierCoreRandomAccessorCreateWithBezierCore(NIBezierCoreRef bezierCore);
NIBezierCoreRandomAccessorRef NIBezierCoreRandomAccessorCreateWithMutableBezierCore(NIMutableBezierCoreRef bezierCore);
NIBezierCoreRandomAccessorRef NIBezierCoreRandomAccessorRetain(NIBezierCoreRandomAccessorRef bezierCoreRandomAccessor);
void NIBezierCoreRandomAccessorRelease(NIBezierCoreRandomAccessorRef bezierCoreRandomAccessor);

NIBezierCoreSegmentType NIBezierCoreRandomAccessorGetSegmentAtIndex(NIBezierCoreRandomAccessorRef bezierCoreRandomAccessor, CFIndex index, NIVectorPointer control1, NIVectorPointer control2, NIVectorPointer endpoint);
void NIBezierCoreRandomAccessorSetVectorsForSegementAtIndex(NIBezierCoreRandomAccessorRef bezierCoreRandomAccessor, CFIndex index, NIVector control1, NIVector control2, NIVector endpoint); // the random accessor must have been created with the mutable beziercore
CFIndex NIBezierCoreRandomAccessorSegmentCount(NIBezierCoreRandomAccessorRef bezierCoreRandomAccessor);

CF_EXTERN_C_END

#endif	/* _NIBEZIERCORE_H_ */
