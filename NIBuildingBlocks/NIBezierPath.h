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

#import <Foundation/Foundation.h>
#import <AppKit/NSBezierPath.h>

#import "NIGeometry.h"
#import "NIBezierCore.h"
#import "NIBezierCoreAdditions.h"

NS_ASSUME_NONNULL_BEGIN

// NIBezierDefaultFlatness and NIBezierDefaultSubdivideSegmentLength are defined in NIBezierCore.h
// NIBezierNodeStyle is defined in NIBezierCoreAdditions.h

@class NSBezierPath;

typedef NS_ENUM(NSInteger, NIBezierPathElement) { // shouldn't the be typed as unsigned long to match the segments?
    NIMoveToBezierPathElement,
    NILineToBezierPathElement,
    NICurveToBezierPathElement,
    NICloseBezierPathElement
};

@interface NIBezierPath : NSObject <NSCopying, NSMutableCopying, NSSecureCoding, NSFastEnumeration> // fast enumeration returns NSValues of the endpoints
{
    NIMutableBezierCoreRef _bezierCore;
    CGFloat _length;
    NIBezierCoreRandomAccessorRef _bezierCoreRandomAccessor;
}

- (nullable instancetype)init NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithBezierPath:(NIBezierPath *)bezierPath;
- (nullable instancetype)initWithNSBezierPath:(NSBezierPath *)bezierPath;
- (nullable instancetype)initWithDictionaryRepresentation:(NSDictionary *)dict;
- (nullable instancetype)initWithNIBezierCore:(NIBezierCoreRef)bezierCore;
- (nullable instancetype)initWithNodeArray:(NSArray *)nodes style:(NIBezierNodeStyle)style; // array of NIVectors in NSValues;

+ (nullable instancetype)bezierPath;
+ (nullable instancetype)bezierPathWithBezierPath:(NIBezierPath *)bezierPath;
+ (nullable instancetype)bezierPathWithNSBezierPath:(NSBezierPath *)bezierPath;
+ (nullable instancetype)bezierPathWithNIBezierCore:(NIBezierCoreRef)bezierCore;
+ (nullable instancetype)bezierPathNIBezierCore:(NIBezierCoreRef)bezierCore __deprecated;
+ (nullable instancetype)bezierPathCircleWithCenter:(NIVector)center radius:(CGFloat)radius normal:(NIVector)normal;

- (BOOL)isEqualToBezierPath:(NIBezierPath *)bezierPath;

- (NIBezierPath *)bezierPathByFlattening:(CGFloat)flatness;
- (NIBezierPath *)bezierPathBySubdividing:(CGFloat)maxSegmentLength;
- (NIBezierPath *)bezierPathByApplyingTransform:(NIAffineTransform)transform;
- (NIBezierPath *)bezierPathByApplyingConverter:(NIVector (^)(NIVector vector))converter __deprecated;
- (NIBezierPath *)bezierPathByAppendingBezierPath:(NIBezierPath *)bezierPath connectPaths:(BOOL)connectPaths;
- (NIBezierPath *)bezierPathByAddingEndpointsAtIntersectionsWithPlane:(NIPlane)plane; // will  flatten the path if it is not already flattened
- (NIBezierPath *)bezierPathByProjectingToPlane:(NIPlane)plane;
- (nullable NIBezierPath *)outlineBezierPathAtDistance:(CGFloat)distance initialNormal:(NIVector)initalNormal spacing:(CGFloat)spacing;
- (nullable NIBezierPath *)outlineBezierPathAtDistance:(CGFloat)distance projectionNormal:(NIVector)projectionNormal spacing:(CGFloat)spacing;

- (NSInteger)elementCount;
- (CGFloat)length;
- (CGFloat)lengthThroughElementAtIndex:(NSInteger)element; // the length of the curve up to and including the element at index
- (NIBezierCoreRef)NIBezierCore;
- (NSDictionary *)dictionaryRepresentation;
- (NIVector)vectorAtStart;
- (NIVector)vectorAtEnd;
- (NIVector)tangentAtStart;
- (NIVector)tangentAtEnd;
- (NIVector)normalAtEndWithInitialNormal:(NIVector)initialNormal;
- (BOOL)isPlanar;
- (BOOL)isClosed; // if the last segment is a close
- (NIPlane)leastSquaresPlane;
- (NIPlane)topBoundingPlaneForNormal:(NIVector)normal;
- (NIPlane)bottomBoundingPlaneForNormal:(NIVector)normal;
- (NIBezierPathElement)elementAtIndex:(NSInteger)index;
- (NIBezierPathElement)elementAtIndex:(NSInteger)index control1:(nullable NIVectorPointer)control1 control2:(nullable NIVectorPointer)control2 endpoint:(nullable NIVectorPointer)endpoint; // Warning: differs from NSBezierPath in that controlVector2 is is not always the end

// extra functions to help with rendering and such
- (NIVector)vectorAtRelativePosition:(CGFloat)relativePosition; // RelativePosition is in [0, 1]
- (NIVector)tangentAtRelativePosition:(CGFloat)relativePosition;
- (NIVector)normalAtRelativePosition:(CGFloat)relativePosition initialNormal:(NIVector)initialNormal;

- (CGFloat)relativePositionClosestToVector:(NIVector)vector;
- (CGFloat)relativePositionClosestToLine:(NILine)line;
- (CGFloat)relativePositionClosestToLine:(NILine)line closestVector:(nullable NIVectorPointer)vectorPointer;
- (NIBezierPath *)bezierPathByCollapsingZ;
- (NSBezierPath *)NSBezierPath; // collapses Z
- (NIBezierPath *)bezierPathByReversing;

- (NSArray<NSValue *>*)intersectionsWithPlane:(NIPlane)plane; // returns NSValues containing NIVectors of the intersections.
- (NSArray<NSValue *>*)intersectionsWithPlane:(NIPlane)plane relativePositions:(NSArray<NSValue *> * __nonnull * __nullable)returnedRelativePositions;

- (NSArray *)subPaths;
- (NIBezierPath *)bezierPathByClippingFromRelativePosition:(CGFloat)startRelativePosition toRelativePosition:(CGFloat)endRelativePosition;

- (CGFloat)signedAreaUsingNormal:(NIVector)normal;

@end


@interface NIMutableBezierPath : NIBezierPath
{
}

- (void)moveToVector:(NIVector)vector;
- (void)lineToVector:(NIVector)vector;
- (void)curveToVector:(NIVector)vector controlVector1:(NIVector)controlVector1 controlVector2:(NIVector)controlVector2;
- (void)close;

- (void)flatten:(CGFloat)flatness;
- (void)subdivide:(CGFloat)maxSegmentLength;
- (void)applyAffineTransform:(NIAffineTransform)transform;
- (void)applyConverter:(NIVector (^)(NIVector))converter __deprecated;
- (void)projectToPlane:(NIPlane)plane;
- (void)appendBezierPath:(NIBezierPath *)bezierPath connectPaths:(BOOL)connectPaths;
- (void)addEndpointsAtIntersectionsWithPlane:(NIPlane)plane; // will  flatten the path if it is not already flattened
- (void)setVectorsForElementAtIndex:(NSInteger)index control1:(NIVector)control1 control2:(NIVector)control2 endpoint:(NIVector)endpoint;

@end

@interface NIBezierPath (MoveMe)

+ (nullable instancetype)closedSplinePathWithNodes:(NSArray *)nodes; // an array of NIVector values (NSArray<NSValue<NIVector>>)

@end

NS_ASSUME_NONNULL_END


