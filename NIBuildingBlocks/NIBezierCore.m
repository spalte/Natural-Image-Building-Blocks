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

#include <libkern/OSAtomic.h>
#import <Foundation/Foundation.h>

#include "NIBezierCore.h"

static const void *_NIBezierCoreRetainCallback(CFAllocatorRef allocator, const void *value)
{
	return NIBezierCoreRetain((NIBezierCoreRef)value);
}

static void _NIBezierCoreReleaseCallback(CFAllocatorRef allocator, const void *value)
{
	NIBezierCoreRelease((NIBezierCoreRef)value);
}

static CFStringRef _NIBezierCoreCopyDescriptionCallBack(const void *value)
{
	return NIBezierCoreCopyDescription((NIBezierCoreRef)value);
}

static Boolean _NIBezierCoreEqualCallBack(const void *value1, const void *value2)
{
	return NIBezierCoreEqualToBezierCore((NIBezierCoreRef)value1, (NIBezierCoreRef)value2);
}

const CFArrayCallBacks kNIBezierCoreArrayCallBacks = {
	0,
	_NIBezierCoreRetainCallback,
	_NIBezierCoreReleaseCallback,
	_NIBezierCoreCopyDescriptionCallBack,
	_NIBezierCoreEqualCallBack
};

const CFDictionaryValueCallBacks kNIBezierCoreDictionaryValueCallBacks = {
	0,
	_NIBezierCoreRetainCallback,
	_NIBezierCoreReleaseCallback,
	_NIBezierCoreCopyDescriptionCallBack,
	_NIBezierCoreEqualCallBack
};


const CGFloat NIBezierDefaultFlatness = 0.1;
const CGFloat NIBezierDefaultSubdivideSegmentLength = 3;

typedef struct NIBezierCoreElement *NIBezierCoreElementRef; 

struct NIBezierCore
{
    volatile int32_t retainCount __attribute__ ((aligned (4)));
    NIBezierCoreElementRef elementList;
    NIBezierCoreElementRef lastElement;
    CFIndex elementCount;
};

struct NIBezierCoreElement {
    NIBezierCoreSegmentType segmentType;
    NIVector control1;
    NIVector control2;
    NIVector endpoint;
    NIBezierCoreElementRef next; // the last element has next set to NULL
    NIBezierCoreElementRef previous; // the first element has previous set to NULL
};
typedef struct NIBezierCoreElement NIBezierCoreElement;

struct NIBezierCoreIterator
{
    volatile int32_t retainCount __attribute__ ((aligned (4)));
    NIBezierCoreRef bezierCore;
    CFIndex index;
    NIBezierCoreElementRef elementAtIndex;
};
typedef struct NIBezierCoreIterator NIBezierCoreIterator;

struct NIBezierCoreRandomAccessor {
    volatile int32_t retainCount __attribute__ ((aligned (4)));
    NIMutableBezierCoreRef bezierCore;
    NIBezierCoreElementRef *elementArray;
	char mutableBezierCore; // boolean
};
typedef struct NIBezierCoreRandomAccessor NIBezierCoreRandomAccessor;

static CGFloat _NIBezierCoreElementLength(NIBezierCoreElementRef element); // only gives a very rough approximation for curved paths, but the approximation is guaranteed to be the real length or longer
static CGFloat _NIBezierCoreElementFlatness(NIBezierCoreElementRef element);
static void _NIBezierCoreElementDivide(NIBezierCoreElementRef element);
static bool _NIBezierCoreElementEqualToElement(NIBezierCoreElementRef element1, NIBezierCoreElementRef element2);
static NIVector _NIBezierCoreLastMoveTo(NIBezierCoreRef bezierCore);

#pragma mark -
#pragma mark NIBezierCore


NIBezierCoreRef NIBezierCoreCreate()
{
    return NIBezierCoreCreateMutable();
}

NIMutableBezierCoreRef NIBezierCoreCreateMutable()
{
    NIMutableBezierCoreRef bezierCore;

    bezierCore = malloc(sizeof(struct NIBezierCore));
    memset(bezierCore, 0, sizeof(struct NIBezierCore));
    
    NIBezierCoreRetain(bezierCore);
    NIBezierCoreCheckDebug(bezierCore);
    return bezierCore;
}

void *NIBezierCoreRetain(NIBezierCoreRef bezierCore)
{
    NIMutableBezierCoreRef mutableBezierCore;
    mutableBezierCore = (NIMutableBezierCoreRef)bezierCore;
    if (bezierCore) {
        OSAtomicIncrement32(&(mutableBezierCore->retainCount));
        NIBezierCoreCheckDebug(bezierCore);
    }
    return mutableBezierCore;
}


void NIBezierCoreRelease(NIBezierCoreRef bezierCore)
{
    NIMutableBezierCoreRef mutableBezierCore;
    mutableBezierCore = (NIMutableBezierCoreRef)bezierCore;
    NIBezierCoreElementRef element;
    NIBezierCoreElementRef nextElement;
        
    if (bezierCore) {
        NIBezierCoreCheckDebug(bezierCore);
        assert(bezierCore->retainCount > 0);
        if (OSAtomicDecrement32Barrier(&(mutableBezierCore->retainCount)) == 0) {
            element = bezierCore->elementList;
            
            while (element) {
                nextElement = element->next;
                free(element);
                element = nextElement;
            }
            
            free((NIMutableBezierCoreRef) bezierCore);
        }
    }
}

bool NIBezierCoreEqualToBezierCore(NIBezierCoreRef bezierCore1, NIBezierCoreRef bezierCore2)
{
    NIBezierCoreElementRef element1;
    NIBezierCoreElementRef element2;
    
    if (bezierCore1 == bezierCore2) {
        return true;
    }
    
    if (bezierCore1->elementCount != bezierCore2->elementCount) {
        return false;
    }

    element1 = bezierCore1->elementList;
    element2 = bezierCore2->elementList;
    
    while (element1) {
        if (_NIBezierCoreElementEqualToElement(element1, element2) == false) {
            return false;
        }
        element1 = element1->next;
        element2 = element2->next;
    }
    
    return true;
}

bool NIBezierCoreHasCurve(NIBezierCoreRef bezierCore)
{
    NIBezierCoreElementRef element;
    
    if (bezierCore->elementList == NULL) {
        return false;
    }
    
    element = bezierCore->elementList->next;
    
    while (element) {
        if (element->segmentType == NICurveToBezierCoreSegmentType) {
            return true;
        }
        element = element->next;
    }
    
    return false;
}

CFStringRef NIBezierCoreCopyDescription(NIBezierCoreRef bezierCore)
{
	CFDictionaryRef dictionaryRep;
	CFStringRef description;
	
	dictionaryRep = NIBezierCoreCreateDictionaryRepresentation(bezierCore);
	description = (CFStringRef)[[(NSDictionary *)dictionaryRep description] retain];
	CFRelease(dictionaryRep);
	return description;
}

NIBezierCoreRef NIBezierCoreCreateCopy(NIBezierCoreRef bezierCore)
{
    return NIBezierCoreCreateMutableCopy(bezierCore);
}

NIMutableBezierCoreRef NIBezierCoreCreateMutableCopy(NIBezierCoreRef bezierCore)
{
    NIMutableBezierCoreRef newBezierCore;
    NIBezierCoreElementRef element;
    NIBezierCoreElementRef prevNewElement;
    NIBezierCoreElementRef newElement;
    CFIndex elementCount;

    newBezierCore = malloc(sizeof(struct NIBezierCore));
    memset(newBezierCore, 0, sizeof(struct NIBezierCore));
    
    newElement = NULL;
    element = bezierCore->elementList;
    prevNewElement = 0;
    elementCount = 0;
    
    if (element) {
        newElement = malloc(sizeof(NIBezierCoreElement));
        memcpy(newElement, element, sizeof(NIBezierCoreElement));
        assert(newElement->previous == NULL);
        
        newBezierCore->elementList = newElement;
        elementCount++;
        
        prevNewElement = newElement;
        element = element->next;
    }
    
    while (element) {
        newElement = malloc(sizeof(NIBezierCoreElement));
        memcpy(newElement, element, sizeof(NIBezierCoreElement));
        
        prevNewElement->next = newElement;
        newElement->previous = prevNewElement;
        
        elementCount++;
        prevNewElement = newElement;
        element = element->next;
    }
    
    if (newElement) {
        newElement->next = NULL;
        newBezierCore->lastElement = newElement;
    }
    
    assert(elementCount == bezierCore->elementCount);
    newBezierCore->elementCount = bezierCore->elementCount;
    
    NIBezierCoreRetain(newBezierCore);

    NIBezierCoreCheckDebug(bezierCore);
    return newBezierCore;
}

CFDictionaryRef NIBezierCoreCreateDictionaryRepresentation(NIBezierCoreRef bezierCore)
{
	NSMutableArray *segments;
	NSDictionary *segmentDictionary;
	NIVector control1;
	NIVector control2;
	NIVector endpoint;
	CFDictionaryRef control1Dict;
	CFDictionaryRef control2Dict;
	CFDictionaryRef endpointDict;
	NIBezierCoreSegmentType segmentType;
	NIBezierCoreIteratorRef bezierCoreIterator;
	
	segments = [NSMutableArray array];
	bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(bezierCore);
	
	while (NIBezierCoreIteratorIsAtEnd(bezierCoreIterator) == NO) {
		segmentType = NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, &control1, &control2, &endpoint);
		control1Dict = NIVectorCreateDictionaryRepresentation(control1);
		control2Dict = NIVectorCreateDictionaryRepresentation(control2);
		endpointDict = NIVectorCreateDictionaryRepresentation(endpoint);
		switch (segmentType) {
			case NIMoveToBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"moveTo", @"segmentType", (id)endpointDict, @"endpoint", nil];
				break;
			case NILineToBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"lineTo", @"segmentType", (id)endpointDict, @"endpoint", nil];
				break;
			case NICloseBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"close", @"segmentType", (id)endpointDict, @"endpoint", nil];
                break;
            case NICurveToBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"curveTo", @"segmentType", (id)control1Dict, @"control1",
									 (id)control2Dict, @"control2", (id)endpointDict, @"endpoint", nil];
				break;
			default:
                segmentDictionary = NULL;
				assert(0);
				break;
		}
		CFRelease(control1Dict);
		CFRelease(control2Dict);
		CFRelease(endpointDict);
		[segments addObject:segmentDictionary];
	}
	NIBezierCoreIteratorRelease(bezierCoreIterator);
	return (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:segments, @"segments", nil];
}

NIBezierCoreRef NIBezierCoreCreateWithDictionaryRepresentation(CFDictionaryRef dict)
{
	return NIBezierCoreCreateMutableWithDictionaryRepresentation(dict);
}

// we could make this a bit more robust against passing in junk
NIMutableBezierCoreRef NIBezierCoreCreateMutableWithDictionaryRepresentation(CFDictionaryRef dict)
{
	NSArray *segments;
	NSDictionary *segmentDictionary;
	NIMutableBezierCoreRef mutableBezierCore;
	NIVector control1;
	NIVector control2;
	NIVector endpoint;
	
	segments = [(NSDictionary*)dict objectForKey:@"segments"];
	if (segments == nil) {
		return NULL;
	}
	
	mutableBezierCore = NIBezierCoreCreateMutable();
	
	for (segmentDictionary in segments) {
		if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"moveTo"]) {
			endpoint = NIVectorZero;
			NIVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			NIBezierCoreAddSegment(mutableBezierCore, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, endpoint);
		} else if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"lineTo"]) {
			endpoint = NIVectorZero;
			NIVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			NIBezierCoreAddSegment(mutableBezierCore, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, endpoint);
		} else if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"close"]) {
			endpoint = NIVectorZero;
			NIVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			NIBezierCoreAddSegment(mutableBezierCore, NICloseBezierCoreSegmentType, NIVectorZero, NIVectorZero, endpoint);
		} else if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"curveTo"]) {
			control1 = NIVectorZero;
			control2 = NIVectorZero;
			endpoint = NIVectorZero;
			NIVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"control1"], &control1);
			NIVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"control2"], &control2);
			NIVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			NIBezierCoreAddSegment(mutableBezierCore, NICurveToBezierCoreSegmentType, control1, control2, endpoint);
		} else {
			assert(0);
		}
	}
	
	NIBezierCoreCheckDebug(mutableBezierCore);
	
	return mutableBezierCore;
}

NIMutableBezierCoreRef NIBezierCoreCreateMutableWithNSBezierPath(NSBezierPath* path)
{
    NIMutableBezierCoreRef mutableBezierCore = NIBezierCoreCreateMutable();

    NSPoint ps[3];
    NSInteger elementCount = path.elementCount;

    NSBezierPathElement pathElement = NSMoveToBezierPathElement;

    for (NSInteger i = 0; i < elementCount; i++) {
        if (i == elementCount - 1 && pathElement == NSClosePathBezierPathElement && [path elementAtIndex:i associatedPoints:ps] == NSMoveToBezierPathElement) {
            break;
        }

        pathElement = [path elementAtIndex:i associatedPoints:ps];
        switch (pathElement) {
            case NSMoveToBezierPathElement: {
                NIBezierCoreAddSegment(mutableBezierCore, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, NIVectorMakeFromNSPoint(ps[0]));
            } break;
            case NSLineToBezierPathElement: {
                NIBezierCoreAddSegment(mutableBezierCore, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, NIVectorMakeFromNSPoint(ps[0]));
            } break;
            case NSCurveToBezierPathElement: {
                NIBezierCoreAddSegment(mutableBezierCore, NICurveToBezierCoreSegmentType, NIVectorMakeFromNSPoint(ps[0]), NIVectorMakeFromNSPoint(ps[1]), NIVectorMakeFromNSPoint(ps[2]));
            } break;
            case NSClosePathBezierPathElement: {
                NIBezierCoreAddSegment(mutableBezierCore, NICloseBezierCoreSegmentType, NIVectorZero, NIVectorZero, NIVectorMakeFromNSPoint(ps[0]));
            } break;
        }
    }
    
    NIBezierCoreCheckDebug(mutableBezierCore);
    
    return mutableBezierCore;
}


void NIBezierCoreAddSegment(NIMutableBezierCoreRef bezierCore, NIBezierCoreSegmentType segmentType, NIVector control1, NIVector control2, NIVector endpoint)
{
    NIBezierCoreElementRef element;
    
    // if this is the first element, make sure it is a moveto
    assert(bezierCore->elementCount != 0 || segmentType == NIMoveToBezierCoreSegmentType);
	
	// if the previous element was a close, make sure the next element is a moveTo
	assert(bezierCore->elementCount == 0 || bezierCore->lastElement->segmentType != NICloseBezierCoreSegmentType || segmentType == NIMoveToBezierCoreSegmentType);
	    
    element = malloc(sizeof(NIBezierCoreElement));
    memset(element, 0, sizeof(NIBezierCoreElement));
    
    element->segmentType = segmentType;
	element->previous = bezierCore->lastElement;
	if (segmentType == NIMoveToBezierCoreSegmentType) {
		element->endpoint = endpoint;
	} else if (segmentType == NILineToBezierCoreSegmentType) {
		element->endpoint = endpoint;
	} else if (segmentType == NICurveToBezierCoreSegmentType) {
		element->control1 = control1;
		element->control2 = control2;
		element->endpoint = endpoint;
	} else if (segmentType == NICloseBezierCoreSegmentType) {
		element->endpoint = _NIBezierCoreLastMoveTo(bezierCore);
	}
	
    if (bezierCore->lastElement) {
        bezierCore->lastElement->next = element;
    }
    bezierCore->lastElement = element;
    if (bezierCore->elementList == NULL) {
        bezierCore->elementList = element;
    }
    
    bezierCore->elementCount++;
}

void NIBezierCoreSetVectorsForSegmentAtIndex(NIMutableBezierCoreRef bezierCore, CFIndex index, NIVector control1, NIVector control2, NIVector endpoint)
{
	NIBezierCoreRandomAccessorRef bezierCoreRandomAccessor;
	
	bezierCoreRandomAccessor = NIBezierCoreRandomAccessorCreateWithMutableBezierCore(bezierCore);
	NIBezierCoreRandomAccessorSetVectorsForSegementAtIndex(bezierCoreRandomAccessor, index, control1, control2, endpoint);
	NIBezierCoreRandomAccessorRelease(bezierCoreRandomAccessor);
}

void NIBezierCoreSubdivide(NIMutableBezierCoreRef bezierCore, CGFloat maxSegementLength)
{
    NIBezierCoreElementRef element;
    NIBezierCoreElementRef lastElement;
    	
    if (bezierCore->elementCount < 2) {
        return;
    }
    
    if (maxSegementLength == 0.0) {
        maxSegementLength = NIBezierDefaultSubdivideSegmentLength;
    }
    
    element = bezierCore->elementList->next;
    lastElement = NULL;
    while (element) {
        if (_NIBezierCoreElementLength(element) > maxSegementLength) {
            _NIBezierCoreElementDivide(element);
            bezierCore->elementCount++;
        } else {
            lastElement = element;
            element = element->next;
        }
    }
    bezierCore->lastElement = lastElement;
    
    NIBezierCoreCheckDebug(bezierCore);    
}


void NIBezierCoreFlatten(NIMutableBezierCoreRef bezierCore, CGFloat flatness)
{
    NIBezierCoreElementRef element;
    NIBezierCoreElementRef lastElement;
    
    if (bezierCore->elementCount < 2) {
        return;
    }
    
    if (flatness == 0.0) {
        flatness = NIBezierDefaultFlatness;
    }

    element = bezierCore->elementList->next;
    lastElement = NULL;
    while (element) {
        if (_NIBezierCoreElementFlatness(element) > flatness) {
            _NIBezierCoreElementDivide(element);
            bezierCore->elementCount++;
        } else {
            if (element->segmentType == NICurveToBezierCoreSegmentType) {
                element->segmentType = NILineToBezierCoreSegmentType;
                element->control1 = NIVectorZero;
                element->control2 = NIVectorZero;
            }
            lastElement = element;
            element = element->next;
        }
    }
    bezierCore->lastElement = lastElement;
    
    NIBezierCoreCheckDebug(bezierCore);
}

void NIBezierCoreSanitize(NIMutableBezierCoreRef bezierCore, CGFloat minSegmentLength) // removes segments that are shorter than minSegmentLength
{
    // iterate over the line segments, and make sure each has a reason for being
    // segments that need to go are: (for this discussion, same position means a distance smaller than minSegmentLength
    // 1. MoveTo that is followed by another MoveTo
    // 2. MoveTo that goes to the same position as the current position
    // 3. CurveTo that goes to the same position as the the current point and distance to the control points is smaller than minSegmentLength
    // 4. MoveTo right before a Close that goes to the same position as the close
    NIBezierCoreElementRef element;
    NIBezierCoreElementRef prevElement;

    if (bezierCore->elementCount < 2) {
        return;
    }

    prevElement = bezierCore->elementList;
    element = prevElement->next;

    while (element) {
        // if we need to remove the segment
        if ((element->segmentType == NIMoveToBezierCoreSegmentType && element->next != NULL && element->next->segmentType == NIMoveToBezierCoreSegmentType) || // 1.
            (element->segmentType == NILineToBezierCoreSegmentType && NIVectorDistance(prevElement->endpoint, element->endpoint) < minSegmentLength) || // 2.
            (element->segmentType == NICurveToBezierCoreSegmentType && NIVectorDistance(prevElement->endpoint, element->endpoint) < minSegmentLength // 3.
                                                                    && NIVectorDistance(element->endpoint, element->control1) < minSegmentLength
                                                                    && NIVectorDistance(element->endpoint, element->control2) < minSegmentLength)) {

            prevElement->next = element->next;

            if (element->next) {
                element->next->previous = prevElement;
            } else {
                bezierCore->lastElement = prevElement;
            }

            free(element);
            bezierCore->elementCount--;
            element = prevElement->next;
        } else if (element->segmentType == NILineToBezierCoreSegmentType && element->next != NULL && element->next->segmentType == NICloseBezierCoreSegmentType && NIVectorDistance(element->endpoint, element->next->endpoint) < minSegmentLength) { // 4.
            prevElement->next = element->next;
            element->next->previous = prevElement;
            free(element);
            bezierCore->elementCount--;

            element = prevElement;
            prevElement = prevElement->previous;
        } else {
            element = element->next;
            prevElement = prevElement->next;
        }
    }

    NIBezierCoreCheckDebug(bezierCore);
}

void NIBezierCoreApplyTransform(NIMutableBezierCoreRef bezierCore, NIAffineTransform transform)
{
    NIBezierCoreElementRef element;
    
    element = bezierCore->elementList;
    
    while (element) {
        element->endpoint = NIVectorApplyTransform(element->endpoint, transform);
		
		if (element->segmentType == NICurveToBezierCoreSegmentType) {
			element->control1 = NIVectorApplyTransform(element->control1, transform);
			element->control2 = NIVectorApplyTransform(element->control2, transform);
		}
        element = element->next;
    }
    
    NIBezierCoreCheckDebug(bezierCore);
}

void NIBezierCoreAppendBezierCore(NIMutableBezierCoreRef bezierCore, NIBezierCoreRef appenedBezier, bool connectPaths)
{
    NIBezierCoreElementRef element;
    NIBezierCoreElementRef lastElement;
    
    element = appenedBezier->elementList;

    if (bezierCore->elementCount != 0 && element != NULL && connectPaths) {
        element = element->next; // remove the first moveto
		
		if (bezierCore->lastElement->segmentType == NICloseBezierCoreSegmentType) { // remove the last close if it is there
			bezierCore->lastElement->previous->next = NULL;
			lastElement = bezierCore->lastElement;
			bezierCore->lastElement = bezierCore->lastElement->previous;
			free(lastElement);
			bezierCore->elementCount -= 1;
		}
    }
    
    while (element) {
        NIBezierCoreAddSegment(bezierCore, element->segmentType, element->control1, element->control2, element->endpoint);
        element = element->next;
    }
    
    NIBezierCoreCheckDebug(bezierCore);
}

NIBezierCoreRef NIBezierCoreCreateFlattenedCopy(NIBezierCoreRef bezierCore, CGFloat flatness)
{
    return NIBezierCoreCreateFlattenedMutableCopy(bezierCore, flatness);
}

NIMutableBezierCoreRef NIBezierCoreCreateFlattenedMutableCopy(NIBezierCoreRef bezierCore, CGFloat flatness)
{
    NIMutableBezierCoreRef newBezierCore;
    
    newBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
    NIBezierCoreFlatten(newBezierCore, flatness);
    
    NIBezierCoreCheckDebug(newBezierCore);

    return newBezierCore;    
}

NIBezierCoreRef NIBezierCoreCreateSubdividedCopy(NIBezierCoreRef bezierCore, CGFloat maxSegementLength)
{
    return NIBezierCoreCreateSubdividedMutableCopy(bezierCore, maxSegementLength);
}

NIMutableBezierCoreRef NIBezierCoreCreateSubdividedMutableCopy(NIBezierCoreRef bezierCore, CGFloat maxSegementLength)
{
    NIMutableBezierCoreRef newBezierCore;
    
    newBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
    NIBezierCoreSubdivide(newBezierCore, maxSegementLength);

    return newBezierCore;    
}

NIBezierCoreRef NIBezierCoreCreateSanitizedCopy(NIBezierCoreRef bezierCore, CGFloat minSegementLength) // removes segments that are shorter than minSegmentLength
{
    return NIBezierCoreCreateSanitizedMutableCopy(bezierCore, minSegementLength);
}

NIMutableBezierCoreRef NIBezierCoreCreateSanitizedMutableCopy(NIBezierCoreRef bezierCore, CGFloat minSegementLength) // removes segments that are shorter than minSegmentLength
{
    NIMutableBezierCoreRef newBezierCore;

    newBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
    NIBezierCoreSanitize(newBezierCore, minSegementLength);

    return newBezierCore;
}

NIBezierCoreRef NIBezierCoreCreateTransformedCopy(NIBezierCoreRef bezierCore, NIAffineTransform transform)
{
    return NIBezierCoreCreateTransformedMutableCopy(bezierCore, transform);
}

NIMutableBezierCoreRef NIBezierCoreCreateTransformedMutableCopy(NIBezierCoreRef bezierCore, NIAffineTransform transform)
{
    NIMutableBezierCoreRef newBezierCore;
    
    newBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
    NIBezierCoreApplyTransform(newBezierCore, transform);
    
    NIBezierCoreCheckDebug(newBezierCore);

    return newBezierCore;    
}    

CFIndex NIBezierCoreSegmentCount(NIBezierCoreRef bezierCore)
{
    return bezierCore->elementCount;
}

CFIndex NIBezierCoreSubpathCount(NIBezierCoreRef bezierCore)
{
	NIBezierCoreElementRef element;
	CFIndex subpathCount;
	
	subpathCount = 0;
	element = bezierCore->elementList;
	while (element) {
		if (element->segmentType == NIMoveToBezierCoreSegmentType) {
			subpathCount++;
		}
		element = element->next;
	}
	
	return subpathCount;
}

CGFloat NIBezierCoreLength(NIBezierCoreRef bezierCore)
{
    NIBezierCoreElementRef element;
    NIBezierCoreRef flattenedBezierCore;
    NIVector lastPoint;
    CGFloat length;
    
    if (bezierCore->elementList == NULL) {
        return 0.0;
    }
    
    lastPoint = bezierCore->elementList->endpoint;
    element = bezierCore->elementList->next;
    length = 0.0;
    
    while (element) {
        if (element->segmentType == NICurveToBezierCoreSegmentType) {
            flattenedBezierCore = NIBezierCoreCreateFlattenedCopy(bezierCore, NIBezierDefaultFlatness);
            length = NIBezierCoreLength(flattenedBezierCore);
            NIBezierCoreRelease(flattenedBezierCore);
            return length;
        } else if (element->segmentType == NILineToBezierCoreSegmentType || element->segmentType == NICloseBezierCoreSegmentType) {
            length += NIVectorDistance(lastPoint, element->endpoint);
        }
        
        lastPoint = element->endpoint;
        element = element->next;
    }
    
    return length;
}

NIBezierCoreSegmentType NIBezierCoreGetSegmentAtIndex(NIBezierCoreRef bezierCore, CFIndex index, NIVectorPointer control1, NIVectorPointer control2, NIVectorPointer endpoint)
{
    NIBezierCoreElementRef element;
    CFIndex i;
    
    NIBezierCoreCheckDebug(bezierCore);

    assert (index < bezierCore->elementCount && index >= 0);
    
    if (index < bezierCore->elementCount / 2) {
        element = bezierCore->elementList;
        for (i = 1; i <= index; i++) {
            element = element->next;
        }
    } else {
        element = bezierCore->lastElement;
        for (i = bezierCore->elementCount - 2; i + 1 > index; i--) {
            element = element->previous;
        }
    }

    assert(element);
    
    if (control1) {
        *control1 = element->control1;
    }
    if (control2) {
        *control2 = element->control2;
    }
    if (endpoint) {
        *endpoint = element->endpoint;
    }

    return element->segmentType;
}

#pragma mark -
#pragma mark DEBUG


void NIBezierCoreCheckDebug(NIBezierCoreRef bezierCore)
{
#ifndef NDEBUG
    // the first segment must be a moveto
    // the member lastElement should really point to the last element
    // the number of elements in the list should really be elementCount
	// the endpoint of a close must be equal to the last moveTo;
	// the element right after a close must be a moveTo
    
    CFIndex elementCount;
    NIBezierCoreElementRef element;
    NIBezierCoreElementRef prevElement;
	NIVector lastMoveTo;
	bool needsMoveTo;
    element = NULL;
	needsMoveTo = false;
    
    assert(bezierCore->retainCount > 0);
    if (bezierCore->elementList == NULL) {
        assert(bezierCore->elementCount == 0);
        assert(bezierCore->lastElement == NULL);
    } else {
        element = bezierCore->elementList;
        elementCount = 1;
        assert(element->previous == NULL);
        assert(element->segmentType == NIMoveToBezierCoreSegmentType);
		lastMoveTo = element->endpoint;
        
        while (element->next) {
            elementCount++;
            prevElement = element;
            element = element->next;
            assert(element->previous == prevElement);
            switch (element->segmentType) {
                case NIMoveToBezierCoreSegmentType:
					lastMoveTo = element->endpoint;
					needsMoveTo = false;
					break;
                case NILineToBezierCoreSegmentType:
                case NICurveToBezierCoreSegmentType:
					assert(needsMoveTo == false);
					break;
                case NICloseBezierCoreSegmentType:
					assert(needsMoveTo == false);
					assert(NIVectorEqualToVector(element->endpoint, lastMoveTo));
					needsMoveTo = true;
                    break;
                default:
                    assert(0);
                    break;
            }
        }
        
        assert(bezierCore->elementCount == elementCount);
        assert(bezierCore->lastElement == element);
    }
#endif
}


#pragma mark -
#pragma mark NIBezierCoreIterator

NIBezierCoreIteratorRef NIBezierCoreIteratorCreateWithBezierCore(NIBezierCoreRef bezierCore)
{
    NIBezierCoreIteratorRef bezierCoreIterator;
    
    bezierCoreIterator = malloc(sizeof(NIBezierCoreIterator));
    memset(bezierCoreIterator, 0, sizeof(NIBezierCoreIterator));
    
    bezierCoreIterator->bezierCore = NIBezierCoreRetain(bezierCore);
    bezierCoreIterator->elementAtIndex = bezierCore->elementList;
    
    NIBezierCoreIteratorRetain(bezierCoreIterator);
    
    return bezierCoreIterator;
}

NIBezierCoreIteratorRef NIBezierCoreIteratorRetain(NIBezierCoreIteratorRef bezierCoreIterator)
{
    if (bezierCoreIterator) {
        OSAtomicIncrement32(&(bezierCoreIterator->retainCount));
    }
    return bezierCoreIterator;    
}

void NIBezierCoreIteratorRelease(NIBezierCoreIteratorRef bezierCoreIterator)
{    
    if (bezierCoreIterator) {
        assert(bezierCoreIterator->retainCount > 0);
        if (OSAtomicDecrement32Barrier(&(bezierCoreIterator->retainCount)) == 0) {
            NIBezierCoreRelease(bezierCoreIterator->bezierCore);
            free(bezierCoreIterator);
        }
    }
}

NIBezierCoreSegmentType NIBezierCoreIteratorGetNextSegment(NIBezierCoreIteratorRef bezierCoreIterator, NIVectorPointer control1, NIVectorPointer control2, NIVectorPointer endpoint)
{
    NIBezierCoreSegmentType segmentType;
    
    if (bezierCoreIterator->elementAtIndex == NULL) {
        if (control1) {
            *control1 = NIVectorZero;
        }
        if (control2) {
            *control2 = NIVectorZero;
        }
        if (endpoint) {
            *endpoint = NIVectorZero;
        }        
        return NIEndBezierCoreSegmentType;
    }
        
    if (control1) {
        *control1 = bezierCoreIterator->elementAtIndex->control1;
    }
    if (control2) {
        *control2 = bezierCoreIterator->elementAtIndex->control2;
    }
    if (endpoint) {
        *endpoint = bezierCoreIterator->elementAtIndex->endpoint;
    }
    
    segmentType = bezierCoreIterator->elementAtIndex->segmentType;
    
    bezierCoreIterator->index++;
    bezierCoreIterator->elementAtIndex = bezierCoreIterator->elementAtIndex->next;
    
    return segmentType;
}

bool NIBezierCoreIteratorIsAtEnd(NIBezierCoreIteratorRef bezierCoreIterator)
{
    return (bezierCoreIterator->elementAtIndex == NULL);
}

CFIndex NIBezierCoreIteratorIndex(NIBezierCoreIteratorRef bezierCoreIterator)
{
    return bezierCoreIterator->index;
}

void NIBezierCoreIteratorSetIndex(NIBezierCoreIteratorRef bezierCoreIterator, CFIndex index)
{
    NIBezierCoreElementRef element;
    CFIndex i;
    
    assert (index < bezierCoreIterator->bezierCore->elementCount);
    
    if (index == bezierCoreIterator->index) {
        return;
    }
    
    element = bezierCoreIterator->bezierCore->elementList;
    
    for (i = 1; i <= index; i++) {
        element = element->next;
    }
    
    assert(element);
    
    bezierCoreIterator->elementAtIndex = element;
    bezierCoreIterator->index = index;
}

CFIndex NIBezierCoreIteratorSegmentCount(NIBezierCoreIteratorRef bezierCoreIterator)
{
    return bezierCoreIterator->bezierCore->elementCount;
}

#pragma mark -
#pragma mark NIBezierCoreRandomAccessor

NIBezierCoreRandomAccessorRef NIBezierCoreRandomAccessorCreateWithBezierCore(NIBezierCoreRef bezierCore)
{
    NIBezierCoreRandomAccessor *bezierCoreRandomAccessor;
    NIBezierCoreElementRef element;
    CFIndex i;
    
    bezierCoreRandomAccessor = malloc(sizeof(NIBezierCoreRandomAccessor));
    memset(bezierCoreRandomAccessor, 0, sizeof(NIBezierCoreRandomAccessor));
    
    bezierCoreRandomAccessor->bezierCore = NIBezierCoreRetain(bezierCore); // this does the casting to mutable for us
    if (bezierCore->elementCount) {
        bezierCoreRandomAccessor->elementArray = malloc(sizeof(NIBezierCoreElementRef) * bezierCore->elementCount);
        
        element = bezierCore->elementList;
        bezierCoreRandomAccessor->elementArray[0] = element;
        
        for (i = 1; i < bezierCore->elementCount; i++) {
            element = element->next;
            bezierCoreRandomAccessor->elementArray[i] = element;
        }
    }
    
    NIBezierCoreRandomAccessorRetain(bezierCoreRandomAccessor);
    
    return bezierCoreRandomAccessor;
}

NIBezierCoreRandomAccessorRef NIBezierCoreRandomAccessorCreateWithMutableBezierCore(NIMutableBezierCoreRef bezierCore)
{
	NIBezierCoreRandomAccessor *bezierCoreRandomAccessor;
	
	bezierCoreRandomAccessor = (NIBezierCoreRandomAccessor *)NIBezierCoreRandomAccessorCreateWithBezierCore(bezierCore);
	bezierCoreRandomAccessor->mutableBezierCore = true;
	return bezierCoreRandomAccessor;
}

NIBezierCoreRandomAccessorRef NIBezierCoreRandomAccessorRetain(NIBezierCoreRandomAccessorRef bezierCoreRandomAccessor)
{
    NIBezierCoreRandomAccessor *mutableBezierCoreRandomAccessor;
    mutableBezierCoreRandomAccessor = (NIBezierCoreRandomAccessor *)bezierCoreRandomAccessor;
    
    if (bezierCoreRandomAccessor) {
        OSAtomicIncrement32(&(mutableBezierCoreRandomAccessor->retainCount));
    }
    return bezierCoreRandomAccessor;    
}

void NIBezierCoreRandomAccessorRelease(NIBezierCoreRandomAccessorRef bezierCoreRandomAccessor)
{
    NIBezierCoreRandomAccessor *mutableBezierCoreRandomAccessor;
    mutableBezierCoreRandomAccessor = (NIBezierCoreRandomAccessor *)bezierCoreRandomAccessor;
    
    if (bezierCoreRandomAccessor) {
        assert(bezierCoreRandomAccessor->retainCount > 0);
        if (OSAtomicDecrement32Barrier(&(mutableBezierCoreRandomAccessor->retainCount)) == 0) {
            NIBezierCoreRelease(bezierCoreRandomAccessor->bezierCore);
            free(bezierCoreRandomAccessor->elementArray);
            free(mutableBezierCoreRandomAccessor);
        }
    }    
}

NIBezierCoreSegmentType NIBezierCoreRandomAccessorGetSegmentAtIndex(NIBezierCoreRandomAccessorRef bezierCoreRandomAccessor, CFIndex index, NIVectorPointer control1, NIVectorPointer control2, NIVectorPointer endpoint)
{
    NIBezierCoreElementRef element;
    
    if (index == bezierCoreRandomAccessor->bezierCore->elementCount) {
        return NIEndBezierCoreSegmentType;
    }

    assert (index <= bezierCoreRandomAccessor->bezierCore->elementCount);
    
    element = bezierCoreRandomAccessor->elementArray[index];
    
    if (control1) {
        *control1 = element->control1;
    }
    if (control2) {
        *control2 = element->control2;
    }
    if (endpoint) {
        *endpoint = element->endpoint;
    }
    
    return element->segmentType;
}

void NIBezierCoreRandomAccessorSetVectorsForSegementAtIndex(NIBezierCoreRandomAccessorRef bezierCoreRandomAccessor, CFIndex index, NIVector control1, NIVector control2, NIVector endpoint)
{
    NIBezierCoreElementRef element;
	
	assert (bezierCoreRandomAccessor->mutableBezierCore);
    assert (index < bezierCoreRandomAccessor->bezierCore->elementCount);
	
	element = bezierCoreRandomAccessor->elementArray[index];
	switch (element->segmentType) {
		case NIMoveToBezierCoreSegmentType: // ouch figure out if there is a closepath later on, and update it too
			element->endpoint = endpoint;
			element = element->next;
			while (element) {
				if (element->segmentType == NICloseBezierCoreSegmentType) {
					element->endpoint = endpoint;
					break;
				} else if (element->segmentType == NIMoveToBezierCoreSegmentType) {
					break;
				}
				element = element->next;
			}
			break;
		case NILineToBezierCoreSegmentType:
			element->endpoint = endpoint;
			break;
		case NICurveToBezierCoreSegmentType:
			element->control1 = control1;
			element->control2 = control2;
			element->endpoint = endpoint;
			break;
		case NICloseBezierCoreSegmentType:
			break;
		default:
			assert(0);
			break;
	}
}

CFIndex NIBezierCoreRandomAccessorSegmentCount(NIBezierCoreRandomAccessorRef bezierCoreRandomAccessor)
{
    return bezierCoreRandomAccessor->bezierCore->elementCount;
}


#pragma mark -
#pragma mark Private Methods

static CGFloat _NIBezierCoreElementLength(NIBezierCoreElementRef element) // only gives a very rough approximation for curved paths
{
    CGFloat distance;
    
    assert(element->segmentType == NIMoveToBezierCoreSegmentType || element->previous);

    distance = 0.0;
	
	switch (element->segmentType) {
		case NILineToBezierCoreSegmentType:
		case NICloseBezierCoreSegmentType:
			distance = NIVectorDistance(element->endpoint, element->previous->endpoint);
			break;
		case NICurveToBezierCoreSegmentType:
			distance = NIVectorDistance(element->previous->endpoint, element->control1);
			distance += NIVectorDistance(element->control1, element->control2);
			distance += NIVectorDistance(element->control2, element->endpoint);			
			break;
		default:
			break;
	}
    
    return distance;
}


static CGFloat _NIBezierCoreElementFlatness(NIBezierCoreElementRef element)
{
    CGFloat flatness1;
    CGFloat endFlatness1;
    CGFloat flatness2;
    CGFloat endFlatness2;
    CGFloat maxFlatness;
    NIVector line;
    CGFloat lineLength;
    NIVector vectorToControl1;
    CGFloat control1ScalarProjection;
    NIVector vectorToControl2;
    CGFloat control2ScalarProjection;
    
    if (element->segmentType != NICurveToBezierCoreSegmentType) {
        return 0.0;
    }
    
    assert(element->previous);
    
    line = NIVectorSubtract(element->endpoint, element->previous->endpoint);
    vectorToControl1 = NIVectorSubtract(element->control1, element->previous->endpoint);
    vectorToControl2 = NIVectorSubtract(element->control2, element->endpoint);
    
    lineLength = NIVectorLength(line);
    
    control1ScalarProjection = NIVectorDotProduct(line, vectorToControl1) / lineLength;
    endFlatness1 = control1ScalarProjection * -1.0;
    flatness1 = NIVectorLength(NIVectorSubtract(vectorToControl1, NIVectorScalarMultiply(line, control1ScalarProjection / lineLength)));
    
    control2ScalarProjection = NIVectorDotProduct(line, vectorToControl2) / lineLength;
    endFlatness2 = control2ScalarProjection;
    flatness2 = NIVectorLength(NIVectorSubtract(vectorToControl2, NIVectorScalarMultiply(line, control2ScalarProjection / lineLength)));
    
    maxFlatness = flatness1;
    if (flatness2 > maxFlatness) {
        maxFlatness = flatness2;
    }
    if (endFlatness1 > maxFlatness) {
        maxFlatness = endFlatness1;
    }
    if (endFlatness2 > maxFlatness) {
        maxFlatness = endFlatness2;
    }
    
    return maxFlatness;
}

static void _NIBezierCoreElementDivide(NIBezierCoreElementRef element)
{
    NIBezierCoreElementRef newElement;
    NIVector q0;
    NIVector q1;
    NIVector q2;
    NIVector r0;
    NIVector r1;
    NIVector b;
    
	assert(element->segmentType != NIMoveToBezierCoreSegmentType); // it doesn't make any sense to divide a moveTo
    assert(element->segmentType == NICurveToBezierCoreSegmentType || element->segmentType == NILineToBezierCoreSegmentType || element->segmentType == NICloseBezierCoreSegmentType);
    assert(element->previous); // there better be a previous so that the starting position is set.
    
    newElement = malloc(sizeof(NIBezierCoreElement));
    memset(newElement, 0, sizeof(NIBezierCoreElement));
    newElement->previous = element;
    newElement->next = element->next;
    newElement->endpoint = element->endpoint;
    newElement->segmentType = element->segmentType;

    
    if (element->next) {
        element->next->previous = newElement;
    }
    element->next = newElement;
    
    if (element->segmentType == NILineToBezierCoreSegmentType) {
        element->endpoint = NIVectorScalarMultiply(NIVectorAdd(element->previous->endpoint, newElement->endpoint), 0.5);
    } else if (element->segmentType == NICloseBezierCoreSegmentType) {
        element->endpoint = NIVectorScalarMultiply(NIVectorAdd(element->previous->endpoint, newElement->endpoint), 0.5);
		element->segmentType = NILineToBezierCoreSegmentType;
    } else if (element->segmentType == NICurveToBezierCoreSegmentType) {
        q0 = NIVectorScalarMultiply(NIVectorAdd(element->previous->endpoint, element->control1), 0.5);
        q1 = NIVectorScalarMultiply(NIVectorAdd(element->control1, element->control2), 0.5);
        q2 = NIVectorScalarMultiply(NIVectorAdd(element->control2, element->endpoint), 0.5);
        r0 = NIVectorScalarMultiply(NIVectorAdd(q0, q1), 0.5);
        r1 = NIVectorScalarMultiply(NIVectorAdd(q1, q2), 0.5);
        b = NIVectorScalarMultiply(NIVectorAdd(r0, r1), 0.5);
        
        newElement->control1 = r1;
        newElement->control2 = q2;
        element->control1 = q0;
        element->control2 = r0;
        element->endpoint = b;
    }
}

static bool _NIBezierCoreElementEqualToElement(NIBezierCoreElementRef element1, NIBezierCoreElementRef element2)
{
    if (element1 == element2) {
        return true;
    }
    
    if (element1->segmentType != element2->segmentType) {
        return false;
    }
    
    if (element1->segmentType == NICurveToBezierCoreSegmentType) {
        return NIVectorEqualToVector(element1->endpoint, element2->endpoint) &&
                NIVectorEqualToVector(element1->control1, element2->control1) &&
                NIVectorEqualToVector(element1->control2, element2->control2);
	} else {
        return NIVectorEqualToVector(element1->endpoint, element2->endpoint);
    }
}

static NIVector _NIBezierCoreLastMoveTo(NIBezierCoreRef bezierCore)
{
	NIBezierCoreElementRef element;
	NIVector lastMoveTo;
	
	lastMoveTo = NIVectorZero;
	element = bezierCore->lastElement;
	
	while (element) {
		if (element->segmentType == NIMoveToBezierCoreSegmentType) {
			lastMoveTo = element->endpoint;
			break;
		}
		element = element->previous;
	}
	
	return lastMoveTo;
}


















