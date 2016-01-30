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

#ifndef _NIBEZIERCORE_ADDITIONS_H_
#define _NIBEZIERCORE_ADDITIONS_H_

#include "NIBezierCore.h"

// NIBezierCore functions that don't need any access to the actual implementation details of the NIBezierCore

CF_EXTERN_C_BEGIN

enum NIBezierNodeStyle {
    NIBezierNodeOpenEndsStyle, // the direction of the end segements point out. this is the style used by the NI View
    NIBezierNodeEndsMeetStyle, // the direction of the end segements point to each other. this is the style that mimics what open ROIs do
};
typedef enum NIBezierNodeStyle NIBezierNodeStyle;

NIBezierCoreRef NIBezierCoreCreateCurveWithNodes(NIVectorArray vectors, CFIndex numVectors, NIBezierNodeStyle style);
NIMutableBezierCoreRef NIBezierCoreCreateMutableCurveWithNodes(NIVectorArray vectors, CFIndex numVectors, NIBezierNodeStyle style);

NIVector NIBezierCoreVectorAtStart(NIBezierCoreRef bezierCore);
NIVector NIBezierCoreVectorAtEnd(NIBezierCoreRef bezierCore);

NIVector NIBezierCoreTangentAtStart(NIBezierCoreRef bezierCore);
NIVector NIBezierCoreTangentAtEnd(NIBezierCoreRef bezierCore);
NIVector NIBezierCoreNormalAtEndWithInitialNormal(NIBezierCoreRef bezierCore, NIVector initialNormal);

CGFloat NIBezierCoreRelativePositionClosestToVector(NIBezierCoreRef bezierCore, NIVector vector, NIVectorPointer closestVector, CGFloat *distance); // a relative position is a value between [0, 1]
CGFloat NIBezierCoreRelativePositionClosestToLine(NIBezierCoreRef bezierCore, NILine line, NIVectorPointer closestVector, CGFloat *distance);

CFIndex NIBezierCoreGetVectorInfo(NIBezierCoreRef bezierCore, CGFloat spacing, CGFloat startingPoint, NIVector initialNormal,  // returns evenly spaced vectors, tangents and normals starting at startingPoint
                    NIVectorArray vectors, NIVectorArray tangents, NIVectorArray normals, CFIndex numVectors); // fills numVectors in the vector arrays, returns the actual number of vectors that were set in the arrays

// for stretched NI
CFIndex NIBezierCoreGetProjectedVectorInfo(NIBezierCoreRef bezierCore, CGFloat spacing, CGFloat startingDistance, NIVector projectionDirection,
                                           NIVectorArray vectors, NIVectorArray tangents, NIVectorArray normals, CGFloat *relativePositions, CFIndex numVectors);

NIBezierCoreRef NIBezierCoreCreateOutline(NIBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIVector initialNormal); // distance from the center, spacing is the distance between ponts on the curve that are sampled to generate the outline
NIMutableBezierCoreRef NIBezierCoreCreateMutableOutline(NIBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIVector initialNormal);

NIBezierCoreRef NIBezierCoreCreateOutlineWithNormal(NIBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIVector projectionNormal);
NIMutableBezierCoreRef NIBezierCoreCreateMutableOutlineWithNormal(NIBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIVector projectionNormal);


CGFloat NIBezierCoreLengthToSegmentAtIndex(NIBezierCoreRef bezierCore, CFIndex index, CGFloat flatness); // the length up to and including the segment at index
CFIndex NIBezierCoreSegmentLengths(NIBezierCoreRef bezierCore, CGFloat *lengths, CFIndex numLengths, CGFloat flatness); // returns the number of lengths set

CFIndex NIBezierCoreCountIntersectionsWithPlane(NIBezierCoreRef bezierCore, NIPlane plane);
CFIndex NIBezierCoreIntersectionsWithPlane(NIBezierCoreRef bezierCore, NIPlane plane, NIVectorArray intersections, CGFloat *relativePositions, CFIndex numVectors);

NIMutableBezierCoreRef NIBezierCoreCreateMutableCopyWithEndpointsAtPlaneIntersections(NIBezierCoreRef bezierCore, NIPlane plane); // creates a NIBezierCore that is sure to have an endpoint every time the bezier core intersects the plane. If the input bezier is not already flattened, this routine will flatten it first

NIBezierCoreRef NIBezierCoreCreateCopyProjectedToPlane(NIBezierCoreRef bezierCore, NIPlane plane);
NIMutableBezierCoreRef NIBezierCoreCreateMutableCopyProjectedToPlane(NIBezierCoreRef bezierCore, NIPlane plane);

NIPlane NIBezierCoreLeastSquaresPlane(NIBezierCoreRef bezierCore);
CGFloat NIBezierCoreMeanDistanceToPlane(NIBezierCoreRef bezierCore, NIPlane plane);
bool NIBezierCoreIsPlanar(NIBezierCoreRef bezierCore, NIPlanePointer bezierCorePlane); // pass NULL for bezierCorePlane if you don't care

bool NIBezierCoreGetBoundingPlanesForNormal(NIBezierCoreRef bezierCore, NIVector normal, NIPlanePointer topPlanePtr, NIPlanePointer bottomPlanePtr); // returns true on success

NIBezierCoreRef NIBezierCoreCreateCopyByReversing(NIBezierCoreRef bezierCore);
NIMutableBezierCoreRef NIBezierCoreCreateMutableCopyByReversing(NIBezierCoreRef bezierCore);

CFArrayRef NIBezierCoreCopySubpaths(NIBezierCoreRef bezierCore);
NIBezierCoreRef NIBezierCoreCreateCopyByClipping(NIBezierCoreRef bezierCore, CGFloat startRelativePosition, CGFloat endRelativePosition);
NIMutableBezierCoreRef NIBezierCoreCreateMutableCopyByClipping(NIBezierCoreRef bezierCore, CGFloat startRelativePosition, CGFloat endRelativePosition);
CGFloat NIBezierCoreSignedAreaUsingNormal(NIBezierCoreRef bezierCore, NIVector normal);

__attribute__((deprecated("Converter only makes sense with affine transforms. If the transform is affine, use NIBezierCoreApplyTransform")))
void NIBezierCoreApplyConverter(NIMutableBezierCoreRef bezierCore, NIVector(^converter)(NIVector vector));

CF_EXTERN_C_END

#endif // _NIBEZIERCORE_ADDITIONS_H_