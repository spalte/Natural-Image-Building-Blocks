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

#include <libkern/OSAtomic.h>
#import <Foundation/Foundation.h>

#include "NIBBBezierCore.h"

static const void *_NIBBBezierCoreRetainCallback(CFAllocatorRef allocator, const void *value)
{
	return NIBBBezierCoreRetain((NIBBBezierCoreRef)value);
}

static void _NIBBBezierCoreReleaseCallback(CFAllocatorRef allocator, const void *value)
{
	NIBBBezierCoreRelease((NIBBBezierCoreRef)value);
}

static CFStringRef _NIBBBezierCoreCopyDescriptionCallBack(const void *value)
{
	return NIBBBezierCoreCopyDescription((NIBBBezierCoreRef)value);
}

static Boolean _NIBBBezierCoreEqualCallBack(const void *value1, const void *value2)
{
	return NIBBBezierCoreEqualToBezierCore((NIBBBezierCoreRef)value1, (NIBBBezierCoreRef)value2);
}

const CFArrayCallBacks kNIBBBezierCoreArrayCallBacks = {
	0,
	_NIBBBezierCoreRetainCallback,
	_NIBBBezierCoreReleaseCallback,
	_NIBBBezierCoreCopyDescriptionCallBack,
	_NIBBBezierCoreEqualCallBack
};

const CFDictionaryValueCallBacks kNIBBBezierCoreDictionaryValueCallBacks = {
	0,
	_NIBBBezierCoreRetainCallback,
	_NIBBBezierCoreReleaseCallback,
	_NIBBBezierCoreCopyDescriptionCallBack,
	_NIBBBezierCoreEqualCallBack
};


const CGFloat NIBBBezierDefaultFlatness = 0.1;
const CGFloat NIBBBezierDefaultSubdivideSegmentLength = 3;

typedef struct NIBBBezierCoreElement *NIBBBezierCoreElementRef; 

struct NIBBBezierCore
{
    volatile int32_t retainCount __attribute__ ((aligned (4)));
    NIBBBezierCoreElementRef elementList;
    NIBBBezierCoreElementRef lastElement;
    CFIndex elementCount;
};

struct NIBBBezierCoreElement {
    NIBBBezierCoreSegmentType segmentType;
    NIBBVector control1;
    NIBBVector control2;
    NIBBVector endpoint;
    NIBBBezierCoreElementRef next; // the last element has next set to NULL
    NIBBBezierCoreElementRef previous; // the first element has previous set to NULL
};
typedef struct NIBBBezierCoreElement NIBBBezierCoreElement;

struct NIBBBezierCoreIterator
{
    volatile int32_t retainCount __attribute__ ((aligned (4)));
    NIBBBezierCoreRef bezierCore;
    CFIndex index;
    NIBBBezierCoreElementRef elementAtIndex;
};
typedef struct NIBBBezierCoreIterator NIBBBezierCoreIterator;

struct NIBBBezierCoreRandomAccessor {
    volatile int32_t retainCount __attribute__ ((aligned (4)));
    NIBBMutableBezierCoreRef bezierCore;
    NIBBBezierCoreElementRef *elementArray;
	char mutableBezierCore; // boolean
};
typedef struct NIBBBezierCoreRandomAccessor NIBBBezierCoreRandomAccessor;

static CGFloat _NIBBBezierCoreElementLength(NIBBBezierCoreElementRef element); // only gives a very rough approximation for curved paths, but the approximation is guaranteed to be the real length or longer
static CGFloat _NIBBBezierCoreElementFlatness(NIBBBezierCoreElementRef element);
static void _NIBBBezierCoreElementDivide(NIBBBezierCoreElementRef element);
static bool _NIBBBezierCoreElementEqualToElement(NIBBBezierCoreElementRef element1, NIBBBezierCoreElementRef element2);
static NIBBVector _NIBBBezierCoreLastMoveTo(NIBBBezierCoreRef bezierCore);

#pragma mark -
#pragma mark NIBBBezierCore


NIBBBezierCoreRef NIBBBezierCoreCreate()
{
    return NIBBBezierCoreCreateMutable();
}

NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutable()
{
    NIBBMutableBezierCoreRef bezierCore;

    bezierCore = malloc(sizeof(struct NIBBBezierCore));
    memset(bezierCore, 0, sizeof(struct NIBBBezierCore));
    
    NIBBBezierCoreRetain(bezierCore);
    NIBBBezierCoreCheckDebug(bezierCore);
    return bezierCore;
}

void *NIBBBezierCoreRetain(NIBBBezierCoreRef bezierCore)
{
    NIBBMutableBezierCoreRef mutableBezierCore;
    mutableBezierCore = (NIBBMutableBezierCoreRef)bezierCore;
    if (bezierCore) {
        OSAtomicIncrement32(&(mutableBezierCore->retainCount));
        NIBBBezierCoreCheckDebug(bezierCore);
    }
    return mutableBezierCore;
}


void NIBBBezierCoreRelease(NIBBBezierCoreRef bezierCore)
{
    NIBBMutableBezierCoreRef mutableBezierCore;
    mutableBezierCore = (NIBBMutableBezierCoreRef)bezierCore;
    NIBBBezierCoreElementRef element;
    NIBBBezierCoreElementRef nextElement;
        
    if (bezierCore) {
        NIBBBezierCoreCheckDebug(bezierCore);
        assert(bezierCore->retainCount > 0);
        if (OSAtomicDecrement32Barrier(&(mutableBezierCore->retainCount)) == 0) {
            element = bezierCore->elementList;
            
            while (element) {
                nextElement = element->next;
                free(element);
                element = nextElement;
            }
            
            free((NIBBMutableBezierCoreRef) bezierCore);
        }
    }
}

bool NIBBBezierCoreEqualToBezierCore(NIBBBezierCoreRef bezierCore1, NIBBBezierCoreRef bezierCore2)
{
    NIBBBezierCoreElementRef element1;
    NIBBBezierCoreElementRef element2;
    
    if (bezierCore1 == bezierCore2) {
        return true;
    }
    
    if (bezierCore1->elementCount != bezierCore2->elementCount) {
        return false;
    }

    element1 = bezierCore1->elementList;
    element2 = bezierCore2->elementList;
    
    while (element1) {
        if (_NIBBBezierCoreElementEqualToElement(element1, element2) == false) {
            return false;
        }
        element1 = element1->next;
        element2 = element2->next;
    }
    
    return true;
}

bool NIBBBezierCoreHasCurve(NIBBBezierCoreRef bezierCore)
{
    NIBBBezierCoreElementRef element;
    
    if (bezierCore->elementList == NULL) {
        return false;
    }
    
    element = bezierCore->elementList->next;
    
    while (element) {
        if (element->segmentType == NIBBCurveToBezierCoreSegmentType) {
            return true;
        }
        element = element->next;
    }
    
    return false;
}

CFStringRef NIBBBezierCoreCopyDescription(NIBBBezierCoreRef bezierCore)
{
	CFDictionaryRef dictionaryRep;
	CFStringRef description;
	
	dictionaryRep = NIBBBezierCoreCreateDictionaryRepresentation(bezierCore);
	description = (CFStringRef)[[(NSDictionary *)dictionaryRep description] retain];
	CFRelease(dictionaryRep);
	return description;
}

NIBBBezierCoreRef NIBBBezierCoreCreateCopy(NIBBBezierCoreRef bezierCore)
{
    return NIBBBezierCoreCreateMutableCopy(bezierCore);
}

NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableCopy(NIBBBezierCoreRef bezierCore)
{
    NIBBMutableBezierCoreRef newBezierCore;
    NIBBBezierCoreElementRef element;
    NIBBBezierCoreElementRef prevNewElement;
    NIBBBezierCoreElementRef newElement;
    CFIndex elementCount;

    newBezierCore = malloc(sizeof(struct NIBBBezierCore));
    memset(newBezierCore, 0, sizeof(struct NIBBBezierCore));
    
    newElement = NULL;
    element = bezierCore->elementList;
    prevNewElement = 0;
    elementCount = 0;
    
    if (element) {
        newElement = malloc(sizeof(NIBBBezierCoreElement));
        memcpy(newElement, element, sizeof(NIBBBezierCoreElement));
        assert(newElement->previous == NULL);
        
        newBezierCore->elementList = newElement;
        elementCount++;
        
        prevNewElement = newElement;
        element = element->next;
    }
    
    while (element) {
        newElement = malloc(sizeof(NIBBBezierCoreElement));
        memcpy(newElement, element, sizeof(NIBBBezierCoreElement));
        
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
    
    NIBBBezierCoreRetain(newBezierCore);

    NIBBBezierCoreCheckDebug(bezierCore);
    return newBezierCore;
}

CFDictionaryRef NIBBBezierCoreCreateDictionaryRepresentation(NIBBBezierCoreRef bezierCore)
{
	NSMutableArray *segments;
	NSDictionary *segmentDictionary;
	NIBBVector control1;
	NIBBVector control2;
	NIBBVector endpoint;
	CFDictionaryRef control1Dict;
	CFDictionaryRef control2Dict;
	CFDictionaryRef endpointDict;
	NIBBBezierCoreSegmentType segmentType;
	NIBBBezierCoreIteratorRef bezierCoreIterator;
	
	segments = [NSMutableArray array];
	bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(bezierCore);
	
	while (NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator) == NO) {
		segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, &control1, &control2, &endpoint);
		control1Dict = NIBBVectorCreateDictionaryRepresentation(control1);
		control2Dict = NIBBVectorCreateDictionaryRepresentation(control2);
		endpointDict = NIBBVectorCreateDictionaryRepresentation(endpoint);
		switch (segmentType) {
			case NIBBMoveToBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"moveTo", @"segmentType", (id)endpointDict, @"endpoint", nil];
				break;
			case NIBBLineToBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"lineTo", @"segmentType", (id)endpointDict, @"endpoint", nil];
				break;
			case NIBBCloseBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"close", @"segmentType", (id)endpointDict, @"endpoint", nil];
                break;
            case NIBBCurveToBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"curveTo", @"segmentType", (id)control1Dict, @"control1",
									 (id)control2Dict, @"control2", (id)endpointDict, @"endpoint", nil];
				break;
			default:
				assert(0);
				break;
		}
		CFRelease(control1Dict);
		CFRelease(control2Dict);
		CFRelease(endpointDict);
		[segments addObject:segmentDictionary];
	}
	NIBBBezierCoreIteratorRelease(bezierCoreIterator);
	return (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:segments, @"segments", nil];
}

NIBBBezierCoreRef NIBBBezierCoreCreateWithDictionaryRepresentation(CFDictionaryRef dict)
{
	return NIBBBezierCoreCreateMutableWithDictionaryRepresentation(dict);
}

// we could make this a bit more robust against passing in junk
NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableWithDictionaryRepresentation(CFDictionaryRef dict)
{
	NSArray *segments;
	NSDictionary *segmentDictionary;
	NIBBMutableBezierCoreRef mutableBezierCore;
	NIBBVector control1;
	NIBBVector control2;
	NIBBVector endpoint;
	
	segments = [(NSDictionary*)dict objectForKey:@"segments"];
	if (segments == nil) {
		return NULL;
	}
	
	mutableBezierCore = NIBBBezierCoreCreateMutable();
	
	for (segmentDictionary in segments) {
		if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"moveTo"]) {
			endpoint = NIBBVectorZero;
			NIBBVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			NIBBBezierCoreAddSegment(mutableBezierCore, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, endpoint);
		} else if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"lineTo"]) {
			endpoint = NIBBVectorZero;
			NIBBVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			NIBBBezierCoreAddSegment(mutableBezierCore, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, endpoint);
		} else if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"close"]) {
			endpoint = NIBBVectorZero;
			NIBBVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			NIBBBezierCoreAddSegment(mutableBezierCore, NIBBCloseBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, endpoint);
		} else if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"curveTo"]) {
			control1 = NIBBVectorZero;
			control2 = NIBBVectorZero;
			endpoint = NIBBVectorZero;
			NIBBVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"control1"], &control1);
			NIBBVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"control2"], &control2);
			NIBBVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			NIBBBezierCoreAddSegment(mutableBezierCore, NIBBCurveToBezierCoreSegmentType, control1, control2, endpoint);
		} else {
			assert(0);
		}
	}
	
	NIBBBezierCoreCheckDebug(mutableBezierCore);
	
	return mutableBezierCore;
}


void NIBBBezierCoreAddSegment(NIBBMutableBezierCoreRef bezierCore, NIBBBezierCoreSegmentType segmentType, NIBBVector control1, NIBBVector control2, NIBBVector endpoint)
{
    NIBBBezierCoreElementRef element;
    
    // if this is the first element, make sure it is a moveto
    assert(bezierCore->elementCount != 0 || segmentType == NIBBMoveToBezierCoreSegmentType);
	
	// if the previous element was a close, make sure the next element is a moveTo
	assert(bezierCore->elementCount == 0 || bezierCore->lastElement->segmentType != NIBBCloseBezierCoreSegmentType || segmentType == NIBBMoveToBezierCoreSegmentType);
	    
    element = malloc(sizeof(NIBBBezierCoreElement));
    memset(element, 0, sizeof(NIBBBezierCoreElement));
    
    element->segmentType = segmentType;
	element->previous = bezierCore->lastElement;
	if (segmentType == NIBBMoveToBezierCoreSegmentType) {
		element->endpoint = endpoint;
	} else if (segmentType == NIBBLineToBezierCoreSegmentType) {
		element->endpoint = endpoint;
	} else if (segmentType == NIBBCurveToBezierCoreSegmentType) {
		element->control1 = control1;
		element->control2 = control2;
		element->endpoint = endpoint;
	} else if (segmentType == NIBBCloseBezierCoreSegmentType) {
		element->endpoint = _NIBBBezierCoreLastMoveTo(bezierCore);
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

void NIBBBezierCoreSetVectorsForSegementAtIndex(NIBBMutableBezierCoreRef bezierCore, CFIndex index, NIBBVector control1, NIBBVector control2, NIBBVector endpoint)
{
	NIBBBezierCoreRandomAccessorRef bezierCoreRandomAccessor;
	
	bezierCoreRandomAccessor = NIBBBezierCoreRandomAccessorCreateWithMutableBezierCore(bezierCore);
	NIBBBezierCoreRandomAccessorSetVectorsForSegementAtIndex(bezierCoreRandomAccessor, index, control1, control2, endpoint);
	NIBBBezierCoreRandomAccessorRelease(bezierCoreRandomAccessor);
}

void NIBBBezierCoreSubdivide(NIBBMutableBezierCoreRef bezierCore, CGFloat maxSegementLength)
{
    NIBBBezierCoreElementRef element;
    NIBBBezierCoreElementRef lastElement;
    	
    if (bezierCore->elementCount < 2) {
        return;
    }
    
    if (maxSegementLength == 0.0) {
        maxSegementLength = NIBBBezierDefaultSubdivideSegmentLength;
    }
    
    element = bezierCore->elementList->next;
    lastElement = NULL;
    while (element) {
        if (_NIBBBezierCoreElementLength(element) > maxSegementLength) {
            _NIBBBezierCoreElementDivide(element);
            bezierCore->elementCount++;
        } else {
            lastElement = element;
            element = element->next;
        }
    }
    bezierCore->lastElement = lastElement;
    
    NIBBBezierCoreCheckDebug(bezierCore);    
}


void NIBBBezierCoreFlatten(NIBBMutableBezierCoreRef bezierCore, CGFloat flatness)
{
    NIBBBezierCoreElementRef element;
    NIBBBezierCoreElementRef lastElement;
    
    if (bezierCore->elementCount < 2) {
        return;
    }
    
    if (flatness == 0.0) {
        flatness = NIBBBezierDefaultFlatness;
    }

    element = bezierCore->elementList->next;
    lastElement = NULL;
    while (element) {
        if (_NIBBBezierCoreElementFlatness(element) > flatness) {
            _NIBBBezierCoreElementDivide(element);
            bezierCore->elementCount++;
        } else {
            if (element->segmentType == NIBBCurveToBezierCoreSegmentType) {
                element->segmentType = NIBBLineToBezierCoreSegmentType;
                element->control1 = NIBBVectorZero;
                element->control2 = NIBBVectorZero;
            }
            lastElement = element;
            element = element->next;
        }
    }
    bezierCore->lastElement = lastElement;
    
    NIBBBezierCoreCheckDebug(bezierCore);
}

void NIBBBezierCoreApplyTransform(NIBBMutableBezierCoreRef bezierCore, NIBBAffineTransform transform)
{
    NIBBBezierCoreElementRef element;
    
    element = bezierCore->elementList;
    
    while (element) {
        element->endpoint = NIBBVectorApplyTransform(element->endpoint, transform);
		
		if (element->segmentType == NIBBCurveToBezierCoreSegmentType) {
			element->control1 = NIBBVectorApplyTransform(element->control1, transform);
			element->control2 = NIBBVectorApplyTransform(element->control2, transform);
		}
        element = element->next;
    }
    
    NIBBBezierCoreCheckDebug(bezierCore);
}

void NIBBBezierCoreAppendBezierCore(NIBBMutableBezierCoreRef bezierCore, NIBBBezierCoreRef appenedBezier, bool connectPaths)
{
    NIBBBezierCoreElementRef element;
    NIBBBezierCoreElementRef lastElement;
    
    element = appenedBezier->elementList;
    
    if (element != NULL && connectPaths) {
        element = element->next; // remove the first moveto
		
		if (bezierCore->lastElement->segmentType == NIBBCloseBezierCoreSegmentType) { // remove the last close if it is there
			bezierCore->lastElement->previous->next = NULL;
			lastElement = bezierCore->lastElement;
			bezierCore->lastElement = bezierCore->lastElement->previous;
			free(lastElement);
			bezierCore->elementCount -= 1;
		}
    }
    
    while (element) {
        NIBBBezierCoreAddSegment(bezierCore, element->segmentType, element->control1, element->control2, element->endpoint);
        element = element->next;
    }
    
    NIBBBezierCoreCheckDebug(bezierCore);
}

NIBBBezierCoreRef NIBBBezierCoreCreateFlattenedCopy(NIBBBezierCoreRef bezierCore, CGFloat flatness)
{
    return NIBBBezierCoreCreateFlattenedMutableCopy(bezierCore, flatness);
}

NIBBMutableBezierCoreRef NIBBBezierCoreCreateFlattenedMutableCopy(NIBBBezierCoreRef bezierCore, CGFloat flatness)
{
    NIBBMutableBezierCoreRef newBezierCore;
    
    newBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
    NIBBBezierCoreFlatten(newBezierCore, flatness);
    
    NIBBBezierCoreCheckDebug(newBezierCore);

    return newBezierCore;    
}

NIBBBezierCoreRef NIBBBezierCoreCreateSubdividedCopy(NIBBBezierCoreRef bezierCore, CGFloat maxSegementLength)
{
    return NIBBBezierCoreCreateSubdividedMutableCopy(bezierCore, maxSegementLength);
}

NIBBMutableBezierCoreRef NIBBBezierCoreCreateSubdividedMutableCopy(NIBBBezierCoreRef bezierCore, CGFloat maxSegementLength)
{
    NIBBMutableBezierCoreRef newBezierCore;
    
    newBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
    NIBBBezierCoreSubdivide(newBezierCore, maxSegementLength);
    
    NIBBBezierCoreCheckDebug(newBezierCore);
    
    return newBezierCore;    
}    

NIBBBezierCoreRef NIBBBezierCoreCreateTransformedCopy(NIBBBezierCoreRef bezierCore, NIBBAffineTransform transform)
{
    return NIBBBezierCoreCreateTransformedMutableCopy(bezierCore, transform);
}

NIBBMutableBezierCoreRef NIBBBezierCoreCreateTransformedMutableCopy(NIBBBezierCoreRef bezierCore, NIBBAffineTransform transform)
{
    NIBBMutableBezierCoreRef newBezierCore;
    
    newBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
    NIBBBezierCoreApplyTransform(newBezierCore, transform);
    
    NIBBBezierCoreCheckDebug(newBezierCore);

    return newBezierCore;    
}    

CFIndex NIBBBezierCoreSegmentCount(NIBBBezierCoreRef bezierCore)
{
    return bezierCore->elementCount;
}

CFIndex NIBBBezierCoreSubpathCount(NIBBBezierCoreRef bezierCore)
{
	NIBBBezierCoreElementRef element;
	CFIndex subpathCount;
	
	subpathCount = 0;
	element = bezierCore->elementList;
	while (element) {
		if (element->segmentType == NIBBMoveToBezierCoreSegmentType) {
			subpathCount++;
		}
		element = element->next;
	}
	
	return subpathCount;
}

CGFloat NIBBBezierCoreLength(NIBBBezierCoreRef bezierCore)
{
    NIBBBezierCoreElementRef element;
    NIBBBezierCoreRef flattenedBezierCore;
    NIBBVector lastPoint;
    CGFloat length;
    
    if (bezierCore->elementList == NULL) {
        return 0.0;
    }
    
    lastPoint = bezierCore->elementList->endpoint;
    element = bezierCore->elementList->next;
    length = 0.0;
    
    while (element) {
        if (element->segmentType == NIBBCurveToBezierCoreSegmentType) {
            flattenedBezierCore = NIBBBezierCoreCreateFlattenedCopy(bezierCore, NIBBBezierDefaultFlatness);
            length = NIBBBezierCoreLength(flattenedBezierCore);
            NIBBBezierCoreRelease(flattenedBezierCore);
            return length;
        } else if (element->segmentType == NIBBLineToBezierCoreSegmentType || element->segmentType == NIBBCloseBezierCoreSegmentType) {
            length += NIBBVectorDistance(lastPoint, element->endpoint);
        }
        
        lastPoint = element->endpoint;
        element = element->next;
    }
    
    return length;
}

NIBBBezierCoreSegmentType NIBBBezierCoreGetSegmentAtIndex(NIBBBezierCoreRef bezierCore, CFIndex index, NIBBVectorPointer control1, NIBBVectorPointer control2, NIBBVectorPointer endpoint)
{
    NIBBBezierCoreElementRef element;
    CFIndex i;
    
    NIBBBezierCoreCheckDebug(bezierCore);

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


void NIBBBezierCoreCheckDebug(NIBBBezierCoreRef bezierCore)
{
#ifndef NDEBUG
    // the first segment must be a moveto
    // the member lastElement should really point to the last element
    // the number of elements in the list should really be elementCount
	// the endpoint of a close must be equal to the last moveTo;
	// the element right after a close must be a moveTo
    
    CFIndex elementCount;
    NIBBBezierCoreElementRef element;
    NIBBBezierCoreElementRef prevElement;
	NIBBVector lastMoveTo;
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
        assert(element->segmentType == NIBBMoveToBezierCoreSegmentType);
		lastMoveTo = element->endpoint;
        
        while (element->next) {
            elementCount++;
            prevElement = element;
            element = element->next;
            assert(element->previous == prevElement);
            switch (element->segmentType) {
                case NIBBMoveToBezierCoreSegmentType:
					lastMoveTo = element->endpoint;
					needsMoveTo = false;
					break;
                case NIBBLineToBezierCoreSegmentType:
                case NIBBCurveToBezierCoreSegmentType:
					assert(needsMoveTo == false);
					break;
                case NIBBCloseBezierCoreSegmentType:
					assert(needsMoveTo == false);
					assert(NIBBVectorEqualToVector(element->endpoint, lastMoveTo));
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
#pragma mark NIBBBezierCoreIterator

NIBBBezierCoreIteratorRef NIBBBezierCoreIteratorCreateWithBezierCore(NIBBBezierCoreRef bezierCore)
{
    NIBBBezierCoreIteratorRef bezierCoreIterator;
    
    bezierCoreIterator = malloc(sizeof(NIBBBezierCoreIterator));
    memset(bezierCoreIterator, 0, sizeof(NIBBBezierCoreIterator));
    
    bezierCoreIterator->bezierCore = NIBBBezierCoreRetain(bezierCore);
    bezierCoreIterator->elementAtIndex = bezierCore->elementList;
    
    NIBBBezierCoreIteratorRetain(bezierCoreIterator);
    
    return bezierCoreIterator;
}

NIBBBezierCoreIteratorRef NIBBBezierCoreIteratorRetain(NIBBBezierCoreIteratorRef bezierCoreIterator)
{
    if (bezierCoreIterator) {
        OSAtomicIncrement32(&(bezierCoreIterator->retainCount));
    }
    return bezierCoreIterator;    
}

void NIBBBezierCoreIteratorRelease(NIBBBezierCoreIteratorRef bezierCoreIterator)
{    
    if (bezierCoreIterator) {
        assert(bezierCoreIterator->retainCount > 0);
        if (OSAtomicDecrement32Barrier(&(bezierCoreIterator->retainCount)) == 0) {
            NIBBBezierCoreRelease(bezierCoreIterator->bezierCore);
            free(bezierCoreIterator);
        }
    }
}

NIBBBezierCoreSegmentType NIBBBezierCoreIteratorGetNextSegment(NIBBBezierCoreIteratorRef bezierCoreIterator, NIBBVectorPointer control1, NIBBVectorPointer control2, NIBBVectorPointer endpoint)
{
    NIBBBezierCoreSegmentType segmentType;
    
    if (bezierCoreIterator->elementAtIndex == NULL) {
        if (control1) {
            *control1 = NIBBVectorZero;
        }
        if (control2) {
            *control2 = NIBBVectorZero;
        }
        if (endpoint) {
            *endpoint = NIBBVectorZero;
        }        
        return NIBBEndBezierCoreSegmentType;
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

bool NIBBBezierCoreIteratorIsAtEnd(NIBBBezierCoreIteratorRef bezierCoreIterator)
{
    return (bezierCoreIterator->elementAtIndex == NULL);
}

CFIndex NIBBBezierCoreIteratorIndex(NIBBBezierCoreIteratorRef bezierCoreIterator)
{
    return bezierCoreIterator->index;
}

void NIBBBezierCoreIteratorSetIndex(NIBBBezierCoreIteratorRef bezierCoreIterator, CFIndex index)
{
    NIBBBezierCoreElementRef element;
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

CFIndex NIBBBezierCoreIteratorSegmentCount(NIBBBezierCoreIteratorRef bezierCoreIterator)
{
    return bezierCoreIterator->bezierCore->elementCount;
}

#pragma mark -
#pragma mark NIBBBezierCoreRandomAccessor

NIBBBezierCoreRandomAccessorRef NIBBBezierCoreRandomAccessorCreateWithBezierCore(NIBBBezierCoreRef bezierCore)
{
    NIBBBezierCoreRandomAccessor *bezierCoreRandomAccessor;
    NIBBBezierCoreElementRef element;
    CFIndex i;
    
    bezierCoreRandomAccessor = malloc(sizeof(NIBBBezierCoreRandomAccessor));
    memset(bezierCoreRandomAccessor, 0, sizeof(NIBBBezierCoreRandomAccessor));
    
    bezierCoreRandomAccessor->bezierCore = NIBBBezierCoreRetain(bezierCore); // this does the casting to mutable for us
    if (bezierCore->elementCount) {
        bezierCoreRandomAccessor->elementArray = malloc(sizeof(NIBBBezierCoreElementRef) * bezierCore->elementCount);
        
        element = bezierCore->elementList;
        bezierCoreRandomAccessor->elementArray[0] = element;
        
        for (i = 1; i < bezierCore->elementCount; i++) {
            element = element->next;
            bezierCoreRandomAccessor->elementArray[i] = element;
        }
    }
    
    NIBBBezierCoreRandomAccessorRetain(bezierCoreRandomAccessor);
    
    return bezierCoreRandomAccessor;
}

NIBBBezierCoreRandomAccessorRef NIBBBezierCoreRandomAccessorCreateWithMutableBezierCore(NIBBMutableBezierCoreRef bezierCore)
{
	NIBBBezierCoreRandomAccessor *bezierCoreRandomAccessor;
	
	bezierCoreRandomAccessor = (NIBBBezierCoreRandomAccessor *)NIBBBezierCoreRandomAccessorCreateWithBezierCore(bezierCore);
	bezierCoreRandomAccessor->mutableBezierCore = true;
	return bezierCoreRandomAccessor;
}

NIBBBezierCoreRandomAccessorRef NIBBBezierCoreRandomAccessorRetain(NIBBBezierCoreRandomAccessorRef bezierCoreRandomAccessor)
{
    NIBBBezierCoreRandomAccessor *mutableBezierCoreRandomAccessor;
    mutableBezierCoreRandomAccessor = (NIBBBezierCoreRandomAccessor *)bezierCoreRandomAccessor;
    
    if (bezierCoreRandomAccessor) {
        OSAtomicIncrement32(&(mutableBezierCoreRandomAccessor->retainCount));
    }
    return bezierCoreRandomAccessor;    
}

void NIBBBezierCoreRandomAccessorRelease(NIBBBezierCoreRandomAccessorRef bezierCoreRandomAccessor)
{
    NIBBBezierCoreRandomAccessor *mutableBezierCoreRandomAccessor;
    mutableBezierCoreRandomAccessor = (NIBBBezierCoreRandomAccessor *)bezierCoreRandomAccessor;
    
    if (bezierCoreRandomAccessor) {
        assert(bezierCoreRandomAccessor->retainCount > 0);
        if (OSAtomicDecrement32Barrier(&(mutableBezierCoreRandomAccessor->retainCount)) == 0) {
            NIBBBezierCoreRelease(bezierCoreRandomAccessor->bezierCore);
            free(bezierCoreRandomAccessor->elementArray);
            free(mutableBezierCoreRandomAccessor);
        }
    }    
}

NIBBBezierCoreSegmentType NIBBBezierCoreRandomAccessorGetSegmentAtIndex(NIBBBezierCoreRandomAccessorRef bezierCoreRandomAccessor, CFIndex index, NIBBVectorPointer control1, NIBBVectorPointer control2, NIBBVectorPointer endpoint)
{
    NIBBBezierCoreElementRef element;
    
    if (index == bezierCoreRandomAccessor->bezierCore->elementCount) {
        return NIBBEndBezierCoreSegmentType;
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

void NIBBBezierCoreRandomAccessorSetVectorsForSegementAtIndex(NIBBBezierCoreRandomAccessorRef bezierCoreRandomAccessor, CFIndex index, NIBBVector control1, NIBBVector control2, NIBBVector endpoint)
{
    NIBBBezierCoreElementRef element;
	
	assert (bezierCoreRandomAccessor->mutableBezierCore);
    assert (index < bezierCoreRandomAccessor->bezierCore->elementCount);
	
	element = bezierCoreRandomAccessor->elementArray[index];
	switch (element->segmentType) {
		case NIBBMoveToBezierCoreSegmentType: // ouch figure out if there is a closepath later on, and update it too
			element->endpoint = endpoint;
			element = element->next;
			while (element) {
				if (element->segmentType == NIBBCloseBezierCoreSegmentType) {
					element->endpoint = endpoint;
					break;
				} else if (element->segmentType == NIBBMoveToBezierCoreSegmentType) {
					break;
				}
				element = element->next;
			}
			break;
		case NIBBLineToBezierCoreSegmentType:
			element->endpoint = endpoint;
			break;
		case NIBBCurveToBezierCoreSegmentType:
			element->control1 = control1;
			element->control2 = control2;
			element->endpoint = endpoint;
			break;
		case NIBBCloseBezierCoreSegmentType:
			break;
		default:
			assert(0);
			break;
	}
}

CFIndex NIBBBezierCoreRandomAccessorSegmentCount(NIBBBezierCoreRandomAccessorRef bezierCoreRandomAccessor)
{
    return bezierCoreRandomAccessor->bezierCore->elementCount;
}


#pragma mark -
#pragma mark Private Methods

static CGFloat _NIBBBezierCoreElementLength(NIBBBezierCoreElementRef element) // only gives a very rough approximation for curved paths
{
    CGFloat distance;
    
    assert(element->segmentType == NIBBMoveToBezierCoreSegmentType || element->previous);

    distance = 0.0;
	
	switch (element->segmentType) {
		case NIBBLineToBezierCoreSegmentType:
		case NIBBCloseBezierCoreSegmentType:
			distance = NIBBVectorDistance(element->endpoint, element->previous->endpoint);
			break;
		case NIBBCurveToBezierCoreSegmentType:
			distance = NIBBVectorDistance(element->previous->endpoint, element->control1);
			distance += NIBBVectorDistance(element->control1, element->control2);
			distance += NIBBVectorDistance(element->control2, element->endpoint);			
			break;
		default:
			break;
	}
    
    return distance;
}


static CGFloat _NIBBBezierCoreElementFlatness(NIBBBezierCoreElementRef element)
{
    CGFloat flatness1;
    CGFloat endFlatness1;
    CGFloat flatness2;
    CGFloat endFlatness2;
    CGFloat maxFlatness;
    NIBBVector line;
    CGFloat lineLength;
    NIBBVector vectorToControl1;
    CGFloat control1ScalarProjection;
    NIBBVector vectorToControl2;
    CGFloat control2ScalarProjection;
    
    if (element->segmentType != NIBBCurveToBezierCoreSegmentType) {
        return 0.0;
    }
    
    assert(element->previous);
    
    line = NIBBVectorSubtract(element->endpoint, element->previous->endpoint);
    vectorToControl1 = NIBBVectorSubtract(element->control1, element->previous->endpoint);
    vectorToControl2 = NIBBVectorSubtract(element->control2, element->endpoint);
    
    lineLength = NIBBVectorLength(line);
    
    control1ScalarProjection = NIBBVectorDotProduct(line, vectorToControl1) / lineLength;
    endFlatness1 = control1ScalarProjection * -1.0;
    flatness1 = NIBBVectorLength(NIBBVectorSubtract(vectorToControl1, NIBBVectorScalarMultiply(line, control1ScalarProjection / lineLength)));
    
    control2ScalarProjection = NIBBVectorDotProduct(line, vectorToControl2) / lineLength;
    endFlatness2 = control2ScalarProjection;
    flatness2 = NIBBVectorLength(NIBBVectorSubtract(vectorToControl2, NIBBVectorScalarMultiply(line, control2ScalarProjection / lineLength)));
    
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

static void _NIBBBezierCoreElementDivide(NIBBBezierCoreElementRef element)
{
    NIBBBezierCoreElementRef newElement;
    NIBBVector q0;
    NIBBVector q1;
    NIBBVector q2;
    NIBBVector r0;
    NIBBVector r1;
    NIBBVector b;
    
	assert(element->segmentType != NIBBMoveToBezierCoreSegmentType); // it doesn't make any sense to divide a moveTo
    assert(element->segmentType == NIBBCurveToBezierCoreSegmentType || element->segmentType == NIBBLineToBezierCoreSegmentType || element->segmentType == NIBBCloseBezierCoreSegmentType);
    assert(element->previous); // there better be a previous so that the starting position is set.
    
    newElement = malloc(sizeof(NIBBBezierCoreElement));
    memset(newElement, 0, sizeof(NIBBBezierCoreElement));
    newElement->previous = element;
    newElement->next = element->next;
    newElement->endpoint = element->endpoint;
    newElement->segmentType = element->segmentType;

    
    if (element->next) {
        element->next->previous = newElement;
    }
    element->next = newElement;
    
    if (element->segmentType == NIBBLineToBezierCoreSegmentType) {
        element->endpoint = NIBBVectorScalarMultiply(NIBBVectorAdd(element->previous->endpoint, newElement->endpoint), 0.5);
    } else if (element->segmentType == NIBBCloseBezierCoreSegmentType) {
        element->endpoint = NIBBVectorScalarMultiply(NIBBVectorAdd(element->previous->endpoint, newElement->endpoint), 0.5);
		element->segmentType = NIBBLineToBezierCoreSegmentType;
		newElement->segmentType = NIBBCloseBezierCoreSegmentType;
    } else if (element->segmentType == NIBBCurveToBezierCoreSegmentType) {
        q0 = NIBBVectorScalarMultiply(NIBBVectorAdd(element->previous->endpoint, element->control1), 0.5);
        q1 = NIBBVectorScalarMultiply(NIBBVectorAdd(element->control1, element->control2), 0.5);
        q2 = NIBBVectorScalarMultiply(NIBBVectorAdd(element->control2, element->endpoint), 0.5);
        r0 = NIBBVectorScalarMultiply(NIBBVectorAdd(q0, q1), 0.5);
        r1 = NIBBVectorScalarMultiply(NIBBVectorAdd(q1, q2), 0.5);
        b = NIBBVectorScalarMultiply(NIBBVectorAdd(r0, r1), 0.5);
        
        newElement->control1 = r1;
        newElement->control2 = q2;
        element->control1 = q0;
        element->control2 = r0;
        element->endpoint = b;
    }
}

static bool _NIBBBezierCoreElementEqualToElement(NIBBBezierCoreElementRef element1, NIBBBezierCoreElementRef element2)
{
    if (element1 == element2) {
        return true;
    }
    
    if (element1->segmentType != element2->segmentType) {
        return false;
    }
    
    if (element1->segmentType == NIBBCurveToBezierCoreSegmentType) {
        return NIBBVectorEqualToVector(element1->endpoint, element2->endpoint) &&
                NIBBVectorEqualToVector(element1->control1, element2->control1) &&
                NIBBVectorEqualToVector(element1->control2, element2->control2);
	} else {
        return NIBBVectorEqualToVector(element1->endpoint, element2->endpoint);
    }
}

static NIBBVector _NIBBBezierCoreLastMoveTo(NIBBBezierCoreRef bezierCore)
{
	NIBBBezierCoreElementRef element;
	NIBBVector lastMoveTo;
	
	lastMoveTo = NIBBVectorZero;
	element = bezierCore->lastElement;
	
	while (element) {
		if (element->segmentType == NIBBMoveToBezierCoreSegmentType) {
			lastMoveTo = element->endpoint;
			break;
		}
		element = element->previous;
	}
	
	return lastMoveTo;
}


















