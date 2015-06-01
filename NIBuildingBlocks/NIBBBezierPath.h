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

#import <Foundation/Foundation.h>
#import <AppKit/NSBezierPath.h>

#import "NIBBGeometry.h"
#import "NIBBBezierCore.h"
#import "NIBBBezierCoreAdditions.h"

// NIBBBezierDefaultFlatness and NIBBBezierDefaultSubdivideSegmentLength are defined in NIBBBezierCore.h
// NIBBBezierNodeStyle is defined in NIBBBezierCoreAdditions.h

@class NSBezierPath;

enum _NIBBBezierPathElement {
    NIBBMoveToBezierPathElement,
    NIBBLineToBezierPathElement,
    NIBBCurveToBezierPathElement,
	NIBBCloseBezierPathElement
};
typedef NSInteger NIBBBezierPathElement;

@interface NIBBBezierPath : NSObject <NSCopying, NSMutableCopying, NSCoding, NSFastEnumeration> // fast enumeration returns NSValues of the endpoints
{
    NIBBMutableBezierCoreRef _bezierCore;
    CGFloat _length;
    NIBBBezierCoreRandomAccessorRef _bezierCoreRandomAccessor;
}

- (id)init;
- (id)initWithBezierPath:(NIBBBezierPath *)bezierPath;
- (id)initWithDictionaryRepresentation:(NSDictionary *)dict;
- (id)initWithNIBBBezierCore:(NIBBBezierCoreRef)bezierCore;
- (id)initWithNodeArray:(NSArray *)nodes style:(NIBBBezierNodeStyle)style; // array of NIBBVectors in NSValues;

+ (id)bezierPath;
+ (id)bezierPathWithBezierPath:(NIBBBezierPath *)bezierPath;
+ (id)bezierPathNIBBBezierCore:(NIBBBezierCoreRef)bezierCore;
+ (id)bezierPathCircleWithCenter:(NIBBVector)center radius:(CGFloat)radius normal:(NIBBVector)normal;

- (BOOL)isEqualToBezierPath:(NIBBBezierPath *)bezierPath;

- (NIBBBezierPath *)bezierPathByFlattening:(CGFloat)flatness;
- (NIBBBezierPath *)bezierPathBySubdividing:(CGFloat)maxSegmentLength;
- (NIBBBezierPath *)bezierPathByApplyingTransform:(NIBBAffineTransform)transform;
- (NIBBBezierPath *)bezierPathByAppendingBezierPath:(NIBBBezierPath *)bezierPath connectPaths:(BOOL)connectPaths;
- (NIBBBezierPath *)bezierPathByAddingEndpointsAtIntersectionsWithPlane:(NIBBPlane)plane; // will  flatten the path if it is not already flattened
- (NIBBBezierPath *)bezierPathByProjectingToPlane:(NIBBPlane)plane;
- (NIBBBezierPath *)outlineBezierPathAtDistance:(CGFloat)distance initialNormal:(NIBBVector)initalNormal spacing:(CGFloat)spacing;
- (NIBBBezierPath *)outlineBezierPathAtDistance:(CGFloat)distance projectionNormal:(NIBBVector)projectionNormal spacing:(CGFloat)spacing;

- (NSInteger)elementCount;
- (CGFloat)length;
- (CGFloat)lengthThroughElementAtIndex:(NSInteger)element; // the length of the curve up to and including the element at index
- (NIBBBezierCoreRef)NIBBBezierCore;
- (NSBezierPath *)NSBezierPath;;
- (NSDictionary *)dictionaryRepresentation;
- (NIBBVector)vectorAtStart;
- (NIBBVector)vectorAtEnd;
- (NIBBVector)tangentAtStart;
- (NIBBVector)tangentAtEnd;
- (NIBBVector)normalAtEndWithInitialNormal:(NIBBVector)initialNormal;
- (BOOL)isPlanar;
- (NIBBPlane)leastSquaresPlane;
- (NIBBPlane)topBoundingPlaneForNormal:(NIBBVector)normal;
- (NIBBPlane)bottomBoundingPlaneForNormal:(NIBBVector)normal;
- (NIBBBezierPathElement)elementAtIndex:(NSInteger)index;
- (NIBBBezierPathElement)elementAtIndex:(NSInteger)index control1:(NIBBVectorPointer)control1 control2:(NIBBVectorPointer)control2 endpoint:(NIBBVectorPointer)endpoint; // Warning: differs from NSBezierPath in that controlVector2 is is not always the end

// extra functions to help with rendering and such
- (NIBBVector)vectorAtRelativePosition:(CGFloat)relativePosition; // RelativePosition is in [0, 1]
- (NIBBVector)tangentAtRelativePosition:(CGFloat)relativePosition;
- (NIBBVector)normalAtRelativePosition:(CGFloat)relativePosition initialNormal:(NIBBVector)initialNormal;

- (CGFloat)relativePositionClosestToVector:(NIBBVector)vector;
- (CGFloat)relativePositionClosestToLine:(NIBBLine)line;
- (CGFloat)relativePositionClosestToLine:(NIBBLine)line closestVector:(NIBBVectorPointer)vectorPointer;
- (NIBBBezierPath *)bezierPathByCollapsingZ;
- (NIBBBezierPath *)bezierPathByReversing;

- (NSArray*)intersectionsWithPlane:(NIBBPlane)plane; // returns NSValues containing NIBBVectors of the intersections.
- (NSArray*)intersectionsWithPlane:(NIBBPlane)plane relativePositions:(NSArray **)returnedRelativePositions;

- (NSArray *)subPaths;
- (NIBBBezierPath *)bezierPathByClippingFromRelativePosition:(CGFloat)startRelativePosition toRelativePosition:(CGFloat)endRelativePosition;

- (CGFloat)signedAreaUsingNormal:(NIBBVector)normal;

@end


@interface NIBBMutableBezierPath : NIBBBezierPath
{
}

- (void)moveToVector:(NIBBVector)vector;
- (void)lineToVector:(NIBBVector)vector;
- (void)curveToVector:(NIBBVector)vector controlVector1:(NIBBVector)controlVector1 controlVector2:(NIBBVector)controlVector2;
- (void)close;

- (void)flatten:(CGFloat)flatness;
- (void)subdivide:(CGFloat)maxSegmentLength;
- (void)applyAffineTransform:(NIBBAffineTransform)transform;
- (void)projectToPlane:(NIBBPlane)plane;
- (void)appendBezierPath:(NIBBBezierPath *)bezierPath connectPaths:(BOOL)connectPaths;
- (void)addEndpointsAtIntersectionsWithPlane:(NIBBPlane)plane; // will  flatten the path if it is not already flattened
- (void)setVectorsForElementAtIndex:(NSInteger)index control1:(NIBBVector)control1 control2:(NIBBVector)control2 endpoint:(NIBBVector)endpoint;

@end



