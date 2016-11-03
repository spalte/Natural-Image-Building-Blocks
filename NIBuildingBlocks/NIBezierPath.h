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

#import <Foundation/Foundation.h>
#import <AppKit/NSBezierPath.h>

#import "NIGeometry.h"
#import "NIBezierCore.h"
#import "NIBezierCoreAdditions.h"

NS_ASSUME_NONNULL_BEGIN

// NIBezierDefaultFlatness and NIBezierDefaultSubdivideSegmentLength are defined in NIBezierCore.h
// NIBezierNodeStyle is defined in NIBezierCoreAdditions.h

@class NSBezierPath;

/**
 Types of bezier path elements.
*/
typedef NS_ENUM(NSInteger, NIBezierPathElement) { // shouldn't these be typed as unsigned long to match the segments?
/**
 Move To bezier element.
*/
    NIMoveToBezierPathElement,
/**
 Line To bezier element.
*/
    NILineToBezierPathElement,
/**
 Curve To bezier element.
*/
    NICurveToBezierPathElement,
/**
 Close bezier element.
*/
    NICloseBezierPathElement
};

/**
 NIBezierPath objects represent piecewise cubic bezier curves through 3D space. They  are modeled on NSBeizierPath and encapsulate a list of
 Line To, Move To, Curve To, and Close elements. NIBezierPath exists as a pair with its subclass NIMutableBezierpath.
 Fast enumeration returns NSValues of the endpoints. NIBezierPath is threadsafe, but modifying a NIMutableBezierPath is not.
 @see NIMutableBezierPath
*/
@interface NIBezierPath : NSObject <NSCopying, NSMutableCopying, NSSecureCoding, NSFastEnumeration> // fast enumeration returns NSValues of the endpoints
{
    NIMutableBezierCoreRef _bezierCore;
    CGFloat _length;
    NIBezierCoreRandomAccessorRef _bezierCoreRandomAccessor;
}

/**
 Returns an empty initialized NIBezierPath object.
*/
- (instancetype)init NS_DESIGNATED_INITIALIZER;
/**
 Returns an NIBezierPath object initialized by copying the elements from another given path.
 @param bezierPath The path to copy.
 @return An NIBezierPath object initalized with the contents of the given path.
*/
- (instancetype)initWithBezierPath:(NIBezierPath *)bezierPath;
/**
 Returns an NIBezierPath object initialized by copying the elements from the given NSBezierPath. The z values of the newly initialized elements
 is set to 0.
 @param bezierPath The path to copy.
 @return An NIBezierPath object initalized with the contents of the given path.
*/
- (instancetype)initWithNSBezierPath:(NSBezierPath *)bezierPath;
/**
 Returns an NIBezierPath object initialized with the contents of the given dictionary. A dictionary suitable for this method can be obtained
 by calling dictionaryRepresentation.
 @param dictionaryRepresentation The dictionary from which to obtain values .
 @return An NIBezierPath object initalized with the contents of the given dictionary.
 @see dictionaryRepresentation
 */
- (instancetype)initWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation;
/**
 Returns an NIBezierPath object initialized with the contents of the given NIBezierCoreRef. NIBezierCoreRef is an opaque struct that represents
 a piecewise cubic bezier curves using a C API.
 @param bezierCore The path from which to copy values .
 @return An NIBezierPath object initalized with the contents of the given dictionary.
 @see NIBezierCoreRef
 */
- (instancetype)initWithNIBezierCore:(NIBezierCoreRef)bezierCore;
/**
 Returns an NIBezierPath object by finding a piecewise cubic bezier path that is smooth and passes though the given nodes.
 The nodes are given as an array of NSValues that encode NIVectors. At least 2 nodes need to be defined.
 @param nodes An array of NSValues that encode NIVectors the represent the nodes the returned bezierPath must pass through. At least 2 nodes need to be defined.
 @style How the ends of the bezier path behave.
 @return A smooth NIBezierPath object.
 @see NIBezierNodeStyle
 @see valueWithNIVector:
 @see NIVectorValue
 @see initClosedWithNodeArray:style:
 */
- (instancetype)initWithNodeArray:(NSArray<NSValue *> *)nodes style:(NIBezierNodeStyle)style; // array of NIVectors in NSValues;
/**
 Returns an NIBezierPath object by finding a closed piecewise cubic bezier path that is smooth and passes though the given nodes.
 The nodes are given as an array of NSValues that encode NIVectors. Usually this method is called with a style of NIBezierNodeEndsMeetStyle.
 At least 2 nodes need to be defined.
 @param nodes An array of NSValues that encode NIVectors the represent the nodes the returned bezierPath must pass through. At least 2 nodes need to be defined.
 @style How the ends of the bezier path behave. This value is usually NIBezierNodeEndsMeetStyle for closed paths.
 @return A smooth NIBezierPath object.
 @see NIBezierNodeStyle
 @see valueWithNIVector:
 @see NIVectorValue
 @see initWithNodeArray:style:
 */
- (instancetype)initClosedWithNodeArray:(NSArray<NSValue *> *)nodes style:(NIBezierNodeStyle)style; // array of NIVectors in NSValues;

/**
 Creates and returns an empty bezier path.
 @return An empty bezier path.
*/
+ (instancetype)bezierPath;
/*!
 Creates and returns an NIBezierPath object initialized by copying the elements from another given path.
 @param bezierPath The path to copy.
 @return An NIBezierPath object initalized with the contents of the given path.
 */
+ (instancetype)bezierPathWithBezierPath:(NIBezierPath *)bezierPath;
/**
 Creates and eturns an NIBezierPath object initialized by copying the elements from the given NSBezierPath. The z values of the newly initialized elements
 is set to 0.
 @param bezierPath The path to copy.
 @return An NIBezierPath object initalized with the contents of the given path.
 */
+ (instancetype)bezierPathWithNSBezierPath:(NSBezierPath *)bezierPath;
/**
 Creates and returns an NIBezierPath object initialized with the contents of the given NIBezierCoreRef. NIBezierCoreRef is an opaque struct that represents
 a piecewise cubic bezier curves using a C API.
 @param bezierCore The path from which to copy values .
 @return An NIBezierPath object initalized with the contents of the given dictionary.
 @see NIBezierCoreRef
 */
+ (instancetype)bezierPathWithNIBezierCore:(NIBezierCoreRef)bezierCore;
+ (instancetype)bezierPathNIBezierCore:(NIBezierCoreRef)bezierCore __deprecated;
/**
 Creates and returns a circular ring NIBezierPath object around the given center, of the given radius, and with a given plane normal.
 @param center The center of the returned ring.
 @param radius The radius of the given ring.
 @param normal The plane normal of the returned ring.
 @return An circular NIBezierPath object around the given center, of the given radius, and with a given plane normal.
*/
+ (instancetype)bezierPathCircleWithCenter:(NIVector)center radius:(CGFloat)radius normal:(NIVector)normal;

/**
 Returns a Boolean value that indicates whether a given bezier path is equal to the receiver.
 @param bezierPath The NIBezierPath object with which to compare.
 @return A Boolean value that indicates whether a given bezier path is equal to the receiver.
*/
- (BOOL)isEqualToBezierPath:(NIBezierPath *)bezierPath;

/**
 Flattening a path converts all curved line eleme into straight line approximations. The granularity of the approximations
 is controlled by the flatness value. The default flatness value is NIBezierDefaultFlatness.
 @param flatness The granularity of the strait line approximations.
 @return A NIBezierPath object where all curved line elements have been replaced with straight line approximations.
*/
- (NIBezierPath *)bezierPathByFlattening:(CGFloat)flatness;
/**
 Returns a NIBezierPath object created by subdiving the any elements longer than the maxElementLength of the receiver. The
 length of curved segments is approximated by line segments between the endpoints going through the control points.
 @param maxElementLength The longest allowed element length the the returned NIBezierPath object.
 @return Returns a NIBezierPath object with no elements longer the the maxElementLength.
*/
- (NIBezierPath *)bezierPathBySubdividing:(CGFloat)maxElementLength;
/**
 Transforms all points in the receiver using the specified transform.
 @param transform The transform to apply to the receiver.
 @return Returns a NIBezierPath object created by applying the specified transform on the receiver.
*/
- (NIBezierPath *)bezierPathByApplyingTransform:(NIAffineTransform)transform;
- (NIBezierPath *)bezierPathByApplyingConverter:(NIVector (^)(NIVector vector))converter __deprecated;
/**
 Returns a NIBezierPath object made by appending the given NIBezierPath object to the receiver. The path can be appended
 using ether a Move To element of a Line To element. If connectPaths is YES and the receiver ends with a Close, that Close is removed.
 @param bezierPath The path of append to the receiver.
 @param connectPaths If this value is YES the paths are connected with a Line To, otherwise the paths are connected with a Move To.
 @return Returns a NIBezierPath object that consists of the given path appended to the receiver.
*/
- (NIBezierPath *)bezierPathByAppendingBezierPath:(NIBezierPath *)bezierPath connectPaths:(BOOL)connectPaths;
/**
 Returns a copy of the receiver with added endpoints at any intersections with the given plane have. The current implementation
 returns a path that has been flattened using NIBezierDefaultFlatness, but future versions may return a path that is not flattened
 @param plane The plane with which to search for intersections.
 @return Returns a NIBezierPath object with added nodes at the intersections with the given plane.
*/
- (NIBezierPath *)bezierPathByAddingEndpointsAtIntersectionsWithPlane:(NIPlane)plane; // will  flatten the path if it is not already flattened
/**
 Returns a copy of the receiver that has been projected onto the given plane.
 @param plane The plane onto which to project the NIBezierPath.
 @return Returns a NIBezierPath object that is projected onto the given plane.
*/
- (NIBezierPath *)bezierPathByProjectingToPlane:(NIPlane)plane;
/**
 Returns an NIBezierPath object with 2 subpaths that follow the receiver at a given distance to the side. The position on the returned bezier path
 starts offset in the direction of initialNormal and then windes along the path defined by the receiver. This method only works on paths with 
 a single subpath.
 @param distance The distance at which the outline follows the receiver.
 @param initialNormal The initial direction between the outline and the receiver.
 @param spacing The oulines will be generated by taking steps of the given distance along the receiver.
 @return Returns an NIBezierPath object that contains 2 subpath that follow the receiver a given distance to the side.
*/
- (nullable NIBezierPath *)outlineBezierPathAtDistance:(CGFloat)distance initialNormal:(NIVector)initialNormal spacing:(CGFloat)spacing;
/**
 Returns an NIBezierPath object with 2 subpaths that follow the receiver at a given distance to the side. The returned path will be offset
 from the receiver in the by the cross product between the tangent of the receiver and the given projectionNormal. This method only works on
 paths with a single subpath.
 @param distance The distance at which the outline follows the receiver.
 @param projectionNormal The returned subpaths will be offset in the direction of the cross product between the tangen of the receiver and the projectionNormal.
 @param spacing The oulines will be generated by taking steps of the given distance along the receiver.
 @return Returns an NIBezierPath object that contains 2 subpath that follow the receiver a given distance to the side.
 */
- (nullable NIBezierPath *)outlineBezierPathAtDistance:(CGFloat)distance projectionNormal:(NIVector)projectionNormal spacing:(CGFloat)spacing;

/**
 The number of elements in the receiver.
*/
@property (readonly) NSInteger elementCount;
/**
 The length of the receiver. The length of NIBezierPaths with curved elements is calculated by using a flattened copy of the receiver using
 NIBezierDefaultFlatness as the flatness. This value is cached by the receiver.
 @see lengthThroughElementAtIndex:
*/
@property (readonly) CGFloat length;
/**
 The length of the receiver up to and including the element at the given index.
 @param element The index of the of element through which to find the size.
 @return The length of the receiver up to and including the element at the given index.
 @see length
*/
- (CGFloat)lengthThroughElementAtIndex:(NSInteger)element; // the length of the curve up to and including the element at index

/**
 Returns an autoreleased NIBezierCoreRef representation of the receiver.
*/
@property (readonly) NIBezierCoreRef NIBezierCore;
/**
 Returns a NSDictionary object that contains all the values found in the receiver. This NSDictionary is suitable to be used with
 -[NIBezierCore initWithDictionaryRepresentation:].
 @see initWithDictionaryRepresentation:
*/
@property (readonly, copy) NSDictionary* dictionaryRepresentation;
/**
 The point at the start of the path.
*/
@property (readonly) NIVector vectorAtStart;
/**
 The point at the end of the path.
 */
@property (readonly) NIVector vectorAtEnd;
/**
 The tangant of the path at the start.
 */
@property (readonly) NIVector tangentAtStart;
/**
 The tangant of the path at the end.
*/
@property (readonly) NIVector tangentAtEnd;
/**
 The normal to the path at the end, given an initial normal and following the winding of the path.
 @param initialNormal The normal at the start of the path to follow as the path winds.
 @return The normal to the end of the path.
*/
- (NIVector)normalAtEndWithInitialNormal:(NIVector)initialNormal;
/**
 Returns a boolean value that represents whether the path is all on a single plane, given an arbitrary tolerance.
*/
@property (readonly) BOOL isPlanar;
/**
 Returns a boolean value that represents whether the receiver ends with a Close element.
*/
@property (readonly) BOOL isClosed; // if the last element is a close
/**
 Returns the least squares plane through the endpoints of the elements of the receiver.
*/
@property (readonly) NIPlane leastSquaresPlane;
/**
 Given the provided normal, returns the bounding plane that is highest in the direction of the normal.
 @param normal Normal of the requested plane.
 @return Returns the ounding plane that highest in the direction of the normal.
*/
- (NIPlane)boundingPlaneForNormal:(NIVector)normal;
- (NIPlane)topBoundingPlaneForNormal:(NIVector)normal __deprecated; // same as boundingPlaneForNormal, call boundingPlaneForNormal:normal
- (NIPlane)bottomBoundingPlaneForNormal:(NIVector)normal __deprecated; // same as boundingPlaneForNormal:NIVectorInvert(normal)
/**
 Returns the element type for the given index.
 @param index The index of the element.
 @return The element type for the given index.
 @see elementAtIndex:control1:control2:endpoint:
*/
- (NIBezierPathElement)elementAtIndex:(NSInteger)index;
/**
 Returns the element type and the control points for element at the given index.
 @param index The index of the element.
 @param control1 A pointer to a NIVector to be used to output the first control point for a Curve To element. Pass in NULL if you don't need this value.
 @param control2 A pointer to a NIVector to be used to output the second control point for a Curve To element. Pass in NULL if you don't need this value.
 @param endpoint A pointer to a NIVector to be used to output the endpoint for an element. Returns the location of the last MoveTo in the case of a Close element. Pass in NULL if you don't need this value.
 @return The element type for the given index.
 @see elementAtIndex:
*/
- (NIBezierPathElement)elementAtIndex:(NSInteger)index control1:(nullable NIVectorPointer)control1 control2:(nullable NIVectorPointer)control2 endpoint:(nullable NIVectorPointer)endpoint; // Warning: differs from NSBezierPath in that controlVector2 is is not always the end

// extra functions to help with rendering and such
/**
 Returns the position at the given relative position. The relative position is a value between 0 and 1, inclusive, that represents how far to travel along
 the path. The distance is calculated by using a flattened copy of the receiver with NIBezierDefaultFlatness as the flatness.
 @param relativePosition The relative position at which to evaluate the path.
 @return The position at the given relative position.
*/
- (NIVector)vectorAtRelativePosition:(CGFloat)relativePosition; // RelativePosition is in [0, 1]
/**
 Returns the tangent at the given relative position. The relative position is a value between 0 and 1, inclusive, that represents how far to travel along
 the path. The distance is calculated by using a flattened copy of the receiver with NIBezierDefaultFlatness as the flatness.
 @param relativePosition The relative position at which to evaluate the path.
 @return The tangent at the given relative position.
 */
- (NIVector)tangentAtRelativePosition:(CGFloat)relativePosition;
/**
 Returns the normal at the given relative position, given an initial normal and following the winding of the path. The relative position is a value between
 0 and 1, inclusive, that represents how far to travel along the path. The distance is calculated by using a flattened copy of the receiver with
 NIBezierDefaultFlatness as the flatness.
 @param relativePosition The relative position at which to evaluate the path.
 @param initialNormal The normal at the start of the path to follow as the path winds.
 @return The normal at the given relative position.
 */
- (NIVector)normalAtRelativePosition:(CGFloat)relativePosition initialNormal:(NIVector)initialNormal;

/**
 Returns the closest relative position to the given point. The relative position is a value between 0 and 1, inclusive, that represents how far to travel along
 the path. The distance is calculated by using a flattened copy of the receiver with NIBezierDefaultFlatness as the flatness.
 @param vector The returned relative position will be closest to this point.
 @return The relative position closest to the givien point.
 @see relativePositionClosestToLine:
 @see relativePositionClosestToLine:closestVector:
*/
- (CGFloat)relativePositionClosestToVector:(NIVector)vector;
/**
 Returns the closest relative position to the given line. The relative position is a value between 0 and 1, inclusive, that represents how far to travel along
 the path. The distance is calculated by using a flattened copy of the receiver with NIBezierDefaultFlatness as the flatness.
 @param line The returned relative position will be closest to this line.
 @return The relative position closest to the givien line.
 @see relativePositionClosestToVector:
 @see relativePositionClosestToLine:closestVector:
*/
- (CGFloat)relativePositionClosestToLine:(NILine)line;
/**
 Returns the closest relative position to the given line. The relative position is a value between 0 and 1, inclusive, that represents how far to travel along
 the path. The distance is calculated by using a flattened copy of the receiver with NIBezierDefaultFlatness as the flatness.
 @param line The returned relative position will be closest to this line.
 @param vectorPointer Used to return the point along the curve closest to the given line. Pass NULL if you aren't interested in this value.
 @return The relative position closest to the givien line.
 @see relativePositionClosestToVector:
 @see relativePositionClosestToLine:
 */
- (CGFloat)relativePositionClosestToLine:(NILine)line closestVector:(nullable NIVectorPointer)vectorPointer;
/**
 Returns a copy of the receiver but with all z values set to 0.
*/
@property (readonly, copy) NIBezierPath *bezierPathByCollapsingZ;
/**
 Returns an NSBezierPath with the same values as the receiver. The z values of the receiver are ignored.
*/
@property (readonly, copy) NSBezierPath *NSBezierPath; // collapses Z
/**
 Returns a reversed copy of the receiver.
*/
@property (readonly, copy) NIBezierPath *bezierPathByReversing;

/**
 Finds the intersection of the receiver with the given plane, and returns an array of NSValues that encode NIVector structs of the intersections.
 @param plane The plane with which to intersect.
 @return Returns an array of NSValues that encode NIVector structs of the intersections.
 @see intersectionsWithPlane:relativePositions:
*/
- (NSArray<NSValue *>*)intersectionsWithPlane:(NIPlane)plane; // returns NSValues containing NIVectors of the intersections.
/**
 Finds the intersection of the receiver with the given plane, and returns an array of NSValues that encode NIVector structs of the intersections.
 This method also returns an array of NSValues that encode NIVector structs that represent the relative positions of the intersections. The relative
 position is a value between 0 and 1, inclusive, that represents how far to travel along the path. The distance is calculated by using a
 flattened copy of the receiver with NIBezierDefaultFlatness as the flatness.
 @param plane The plane with which to intersect.
 @param returnedRelativePositions Used to output an array of NSValues that encode NIVector structs that represent the relative positions of the intersections. Pass in nil if you are not interested in these values.
 @return Returns an array of NSValues that encode NIVector structs of the intersections.
 @see intersectionsWithPlane:
*/
- (NSArray<NSValue *>*)intersectionsWithPlane:(NIPlane)plane relativePositions:(NSArray<NSValue *> * __nonnull * __nullable)returnedRelativePositions;

/**
 Returns the seperate subpaths of the receiver. Subpaths are segments of paths that are disconnected and separated by a Move To element.
*/
@property (readonly, copy) NSArray *subPaths;
/**
 Returns a NIBezierPath that starts at startRelativePosition and ends at endRelativePosition. The relative position is a value between 0 and 1,
 inclusive, that represents how far to travel along the path. The distance is calculated by using a flattened copy of the receiver with
 NIBezierDefaultFlatness as the flatness. The returned NIBezierPath object is flattened with NIBezierDefaultFlatness as the flatness.
 @param startRelativePosition The relative position at which to start the returned NIBezierPath object.
 @param endRelativePosition The relative position at which to end the returned NIBezierPath object.
 @return Returns a NIBezierPath that starts at startRelativePosition and ends at endRelativePosition.
*/
- (NIBezierPath *)bezierPathByClippingFromRelativePosition:(CGFloat)startRelativePosition toRelativePosition:(CGFloat)endRelativePosition;

/**
 Returns the area of the receiver after projecting to a plane with the given normal.
 @param normal The normal of the plane of which to project first.
 @return The area of the receiver after projecting to a plane with the given normal.
*/
- (CGFloat)signedAreaUsingNormal:(NIVector)normal;

/**
 @deprecated Use [self initClosedWithNodeArray:nodes style:NIBezierNodeCircularSplineStyle] instead.
 @param nodes An array of NSValues that encode NIVectors the represent the nodes the returned bezierPath must pass through. At least 2 nodes need to be defined.
 @return A smooth NIBezierPath object.
 @see initClosedWithNodeArray:style:
 @see NIBezierNodeCircularSplineStyle
 */
+ (nullable instancetype)closedSplinePathWithNodes:(NSArray<NSValue *> *)nodes __deprecated; // now implemented as a NIBezierNodeStyle

@end

/**
 A mutable version of NIBezierPath. Modifications to the path are not threadsafe. Using only NIBezierPath methods is threadsafe.
*/
@interface NIMutableBezierPath : NIBezierPath
{
}

/**
 Adds a Move To element to the path.
 @param vector The endpoint to the Move To element.
*/
- (void)moveToVector:(NIVector)vector;
/**
 Adds a Line To element to the path.
 @param vector The endpoint to the Line To element.
 */
- (void)lineToVector:(NIVector)vector;
/**
 Adds a Curve To cubic bezier spline element to the path.
 @param vector The endpoint to the Move To element.
 @param controlVector1 The first control point of the cubic bezier spline.
 @param controlVector2 The second control point of the cubic bezier spline.
 */
- (void)curveToVector:(NIVector)vector controlVector1:(NIVector)controlVector1 controlVector2:(NIVector)controlVector2;
/**
 Adds a Close element to the path.
*/
- (void)close;

/**
 Flattening a path converts all curved line elements into straight line approximations. The granularity of the approximations
 is controlled by the flatness value. The default flatness value is NIBezierDefaultFlatness.
 @param flatness The granularity of the strait line approximations.
 @see bezierPathByFlattening:
*/
- (void)flatten:(CGFloat)flatness;
/**
 Subdivides any elemenst longer than the maxElementLength of the receiver. The
 length of curved segments is approximated by line segments between the endpoints going through the control points.
 @param maxElementLength The longest allowed element length.
 @see bezierPathBySubdividing:
*/
- (void)subdivide:(CGFloat)maxElementLength;
/**
 Applies the given affine transform to all the elements in the receiver.
 @param transform The affine transform to apply.
*/
- (void)applyAffineTransform:(NIAffineTransform)transform;
- (void)applyConverter:(NIVector (^)(NIVector))converter __deprecated;
/**
 Projects all the elements of the receiver onto the given plane.
 @param plane The plane on which to project.
*/
- (void)projectToPlane:(NIPlane)plane;
/**
 Appends the given NIBezierPath object to the receiver. The path can be appended using ether a Move To element of a Line To
 element. If connectPaths is YES and the receiver ends with a Close, that Close is removed.
 @param bezierPath The path of append to the receiver.
 @param connectPaths If this value is YES the paths are connected with a Line To, otherwise the paths are connected with a Move To.
*/
- (void)appendBezierPath:(NIBezierPath *)bezierPath connectPaths:(BOOL)connectPaths;
/**
 Adds endpoints at any intersections with the given plane have. The current implementation returns a path that has been
 flattened using NIBezierDefaultFlatness, but future versions may return a path that is not flattened
 @param plane The plane with which to search for intersections.
*/
- (void)addEndpointsAtIntersectionsWithPlane:(NIPlane)plane; // will  flatten the path if it is not already flattened
/**
 Modifies the element at the given index by setting the given values. Only the parameters relevant to the element type at the
 given index are used.
 @param index The index of the element to modify.
 @param control1 The NIVector to set for control1 of the element.
 @param control2 The NIVector to set for control2 of the element.
 @param endpoint The NIVector to set for endpoint of the element.
*/
- (void)setVectorsForElementAtIndex:(NSInteger)index control1:(NIVector)control1 control2:(NIVector)control2 endpoint:(NIVector)endpoint;

@end

NS_ASSUME_NONNULL_END


