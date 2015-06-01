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

#ifndef _NIBBBEZIERCORE_ADDITIONS_H_
#define _NIBBBEZIERCORE_ADDITIONS_H_

#include "NIBBBezierCore.h"

// NIBBBezierCore functions that don't need any access to the actual implementation details of the NIBBBezierCore

CF_EXTERN_C_BEGIN

enum NIBBBezierNodeStyle {
    NIBBBezierNodeOpenEndsStyle, // the direction of the end segements point out. this is the style used by the NIBB View
    NIBBBezierNodeEndsMeetStyle, // the direction of the end segements point to each other. this is the style that mimics what open ROIs do
};
typedef enum NIBBBezierNodeStyle NIBBBezierNodeStyle;

NIBBBezierCoreRef NIBBBezierCoreCreateCurveWithNodes(NIBBVectorArray vectors, CFIndex numVectors, NIBBBezierNodeStyle style);
NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableCurveWithNodes(NIBBVectorArray vectors, CFIndex numVectors, NIBBBezierNodeStyle style);

NIBBVector NIBBBezierCoreVectorAtStart(NIBBBezierCoreRef bezierCore);
NIBBVector NIBBBezierCoreVectorAtEnd(NIBBBezierCoreRef bezierCore);

NIBBVector NIBBBezierCoreTangentAtStart(NIBBBezierCoreRef bezierCore);
NIBBVector NIBBBezierCoreTangentAtEnd(NIBBBezierCoreRef bezierCore);
NIBBVector NIBBBezierCoreNormalAtEndWithInitialNormal(NIBBBezierCoreRef bezierCore, NIBBVector initialNormal);

CGFloat NIBBBezierCoreRelativePositionClosestToVector(NIBBBezierCoreRef bezierCore, NIBBVector vector, NIBBVectorPointer closestVector, CGFloat *distance); // a relative position is a value between [0, 1]
CGFloat NIBBBezierCoreRelativePositionClosestToLine(NIBBBezierCoreRef bezierCore, NIBBLine line, NIBBVectorPointer closestVector, CGFloat *distance);

CFIndex NIBBBezierCoreGetVectorInfo(NIBBBezierCoreRef bezierCore, CGFloat spacing, CGFloat startingPoint, NIBBVector initialNormal,  // returns evenly spaced vectors, tangents and normals starting at startingPoint
                    NIBBVectorArray vectors, NIBBVectorArray tangents, NIBBVectorArray normals, CFIndex numVectors); // fills numVectors in the vector arrays, returns the actual number of vectors that were set in the arrays

// for stretched NIBB
CFIndex NIBBBezierCoreGetProjectedVectorInfo(NIBBBezierCoreRef bezierCore, CGFloat spacing, CGFloat startingDistance, NIBBVector projectionDirection,
                                           NIBBVectorArray vectors, NIBBVectorArray tangents, NIBBVectorArray normals, CGFloat *relativePositions, CFIndex numVectors);

NIBBBezierCoreRef NIBBBezierCoreCreateOutline(NIBBBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIBBVector initialNormal); // distance from the center, spacing is the distance between ponts on the curve that are sampled to generate the outline
NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableOutline(NIBBBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIBBVector initialNormal);

NIBBBezierCoreRef NIBBBezierCoreCreateOutlineWithNormal(NIBBBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIBBVector projectionNormal);
NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableOutlineWithNormal(NIBBBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIBBVector projectionNormal);


CGFloat NIBBBezierCoreLengthToSegmentAtIndex(NIBBBezierCoreRef bezierCore, CFIndex index, CGFloat flatness); // the length up to and including the segment at index
CFIndex NIBBBezierCoreSegmentLengths(NIBBBezierCoreRef bezierCore, CGFloat *lengths, CFIndex numLengths, CGFloat flatness); // returns the number of lengths set

CFIndex NIBBBezierCoreCountIntersectionsWithPlane(NIBBBezierCoreRef bezierCore, NIBBPlane plane);
CFIndex NIBBBezierCoreIntersectionsWithPlane(NIBBBezierCoreRef bezierCore, NIBBPlane plane, NIBBVectorArray intersections, CGFloat *relativePositions, CFIndex numVectors);

NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableCopyWithEndpointsAtPlaneIntersections(NIBBBezierCoreRef bezierCore, NIBBPlane plane); // creates a NIBBBezierCore that is sure to have an endpoint every time the bezier core intersects the plane. If the input bezier is not already flattened, this routine will flatten it first

NIBBBezierCoreRef NIBBBezierCoreCreateCopyProjectedToPlane(NIBBBezierCoreRef bezierCore, NIBBPlane plane);
NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableCopyProjectedToPlane(NIBBBezierCoreRef bezierCore, NIBBPlane plane);

NIBBPlane NIBBBezierCoreLeastSquaresPlane(NIBBBezierCoreRef bezierCore);
CGFloat NIBBBezierCoreMeanDistanceToPlane(NIBBBezierCoreRef bezierCore, NIBBPlane plane);
bool NIBBBezierCoreIsPlanar(NIBBBezierCoreRef bezierCore, NIBBPlanePointer bezierCorePlane); // pass NULL for bezierCorePlane if you don't care

bool NIBBBezierCoreGetBoundingPlanesForNormal(NIBBBezierCoreRef bezierCore, NIBBVector normal, NIBBPlanePointer topPlanePtr, NIBBPlanePointer bottomPlanePtr); // returns true on success

NIBBBezierCoreRef NIBBBezierCoreCreateCopyByReversing(NIBBBezierCoreRef bezierCore);
NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableCopyByReversing(NIBBBezierCoreRef bezierCore);

CFArrayRef NIBBBezierCoreCopySubpaths(NIBBBezierCoreRef bezierCore);
NIBBBezierCoreRef NIBBBezierCoreCreateCopyByClipping(NIBBBezierCoreRef bezierCore, CGFloat startRelativePosition, CGFloat endRelativePosition);
NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableCopyByClipping(NIBBBezierCoreRef bezierCore, CGFloat startRelativePosition, CGFloat endRelativePosition);
CGFloat NIBBBezierCoreSignedAreaUsingNormal(NIBBBezierCoreRef bezierCore, NIBBVector normal);

CF_EXTERN_C_END

#endif // _NIBBBEZIERCORE_ADDITIONS_H_