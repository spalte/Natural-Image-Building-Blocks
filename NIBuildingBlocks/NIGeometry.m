//  Copyright (c) 2017 Spaltenstein Natural Image
//  Copyright (c) 2017 volz.io
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


#include "NIGeometry.h"
#include <ApplicationServices/ApplicationServices.h>
#include <math.h>
#include <Accelerate/Accelerate.h>

static const CGFloat _NIGeometrySmallNumber = (CGFLOAT_MIN * 1E5);

const NIVector NIVectorZero = {0.0, 0.0, 0.0};
const NIVector NIVectorOne = {1.0, 1.0, 1.0};
const NIVector NIVectorXBasis = {1.0, 0.0, 0.0};
const NIVector NIVectorYBasis = {0.0, 1.0, 0.0};
const NIVector NIVectorZBasis = {0.0, 0.0, 1.0};

const NIAffineTransform NIAffineTransformIdentity = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0};
const NILine NILineXAxis = {{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}};
const NILine NILineYAxis = {{0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}};
const NILine NILineZAxis = {{0.0, 0.0, 0.0}, {0.0, 0.0, 1.0}};
const NILine NILineInvalid = {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}};
const NIPlane NIPlaneXZero = {{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}};
const NIPlane NIPlaneYZero = {{0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}};
const NIPlane NIPlaneZZero = {{0.0, 0.0, 0.0}, {0.0, 0.0, 1.0}};
const NIPlane NIPlaneInvalid = {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}};

NIVector NIVectorMake(CGFloat x, CGFloat y, CGFloat z)
{
    NIVector vector;
    vector.x = x,
    vector.y = y;
    vector.z = z;
    return vector;
}

bool NIVectorEqualToVector(NIVector vector1, NIVector vector2)
{
    return vector1.x == vector2.x && vector1.y == vector2.y && vector1.z == vector2.z;
}

bool NIVectorIsCoincidentToVector(NIVector vector1, NIVector vector2)
{
    return NIVectorDistance(vector1, vector2) < _NIGeometrySmallNumber;
}

bool NIVectorIsZero(NIVector vector)
{
    return NIVectorEqualToVector(vector, NIVectorZero);
}

bool NIVectorIsUnit(NIVector vector)
{
    CGFloat length = NIVectorLength(vector);
    return (length > 0.99999999 && length < 1.000001);
}

NIVector NIVectorAdd(NIVector vector1, NIVector vector2)
{
    NIVector vector;
    vector.x = vector1.x + vector2.x;
    vector.y = vector1.y + vector2.y;
    vector.z = vector1.z + vector2.z;
    return vector;
}

NIVector NIVectorSubtract(NIVector vector1, NIVector vector2)
{
    NIVector vector;
    vector.x = vector1.x - vector2.x;
    vector.y = vector1.y - vector2.y;
    vector.z = vector1.z - vector2.z;
    return vector;
}

NIVector NIVectorMultiply(NIVector vector1, NIVector vector2)
{
    NIVector newVector;
    newVector.x = vector1.x * vector2.x;
    newVector.y = vector1.y * vector2.y;
    newVector.z = vector1.z * vector2.z;
    return newVector;
}

NIVector NIVectorDivide(NIVector vector1, NIVector vector2)
{
    NIVector newVector;
    newVector.x = vector1.x / vector2.x;
    newVector.y = vector1.y / vector2.y;
    newVector.z = vector1.z / vector2.z;
    return newVector;
}

NIVector NIVectorScalarMultiply(NIVector vector, CGFloat scalar)
{
    NIVector newVector;
    newVector.x = vector.x * scalar;
    newVector.y = vector.y * scalar;
    newVector.z = vector.z * scalar;
    return newVector;
}

NIVector NIVectorScalarDivide(NIVector vector, CGFloat scalar)
{
    return NIVectorScalarMultiply(vector, 1./scalar);
}

NIVector NIVectorZeroZ(NIVector vector)
{
    vector.z = 0;
    return vector;
}

CGFloat NIVectorComponentsSum(NIVector vector)
{
    return vector.x + vector.y + vector.z;
}

CGFloat NIVectorComponentsProduct(NIVector vector)
{
    return vector.x * vector.y * vector.z;
}

NIVector NIVectorANormalVector(NIVector vector) // returns a vector that is normal to the given vector
{
    NIVector normal1;
    NIVector normal2;
    NIVector normal3;
    CGFloat length1;
    CGFloat length2;
    CGFloat length3;

    normal1 = NIVectorMake(-vector.y, vector.x, 0.0);
    normal2 = NIVectorMake(-vector.z, 0.0, vector.x);
    normal3 = NIVectorMake(0.0, -vector.z, vector.y);

    length1 = NIVectorLength(normal1);
    length2 = NIVectorLength(normal2);
    length3 = NIVectorLength(normal3);

    if (length1 > length2) {
        if (length1 > length3) {
            return NIVectorNormalize(normal1);
        } else {
            return NIVectorNormalize(normal3);
        }
    } else {
        if (length2 > length3) {
            return NIVectorNormalize(normal2);
        } else {
            return NIVectorNormalize(normal3);
        }
    }
}

CGFloat NIVectorDistance(NIVector vector1, NIVector vector2)
{
    return NIVectorLength(NIVectorSubtract(vector1, vector2));
}

CGFloat NIVectorDotProduct(NIVector vector1, NIVector vector2)
{
    return (vector1.x*vector2.x) + (vector1.y*vector2.y) + (vector1.z*vector2.z);

}

NIVector NIVectorCrossProduct(NIVector vector1, NIVector vector2)
{
    NIVector newVector;
    newVector.x = vector1.y*vector2.z - vector1.z*vector2.y;
    newVector.y = vector1.z*vector2.x - vector1.x*vector2.z;
    newVector.z = vector1.x*vector2.y - vector1.y*vector2.x;
    return newVector;
}

CGFloat NIVectorAngleBetweenVectors(NIVector vector1, NIVector vector2) {
#if CGFLOAT_IS_DOUBLE
    return atan2(NIVectorLength(NIVectorCrossProduct(vector1, vector2)), NIVectorDotProduct(vector1, vector2));
#else
    return atan2f(NIVectorLength(NIVectorCrossProduct(vector1, vector2)), NIVectorDotProduct(vector1, vector2));
#endif
}

CGFloat NIVectorAngleBetweenVectorsAroundVector(NIVector vector1, NIVector vector2, NIVector aroundVector) // returns [0, M_PI*2)
{
    NIVector crossProduct;
    CGFloat angle;

    aroundVector = NIVectorNormalize(aroundVector);
    vector1 = NIVectorSubtract(vector1, NIVectorScalarMultiply(aroundVector, NIVectorDotProduct(vector1, aroundVector)));
    vector2 = NIVectorSubtract(vector2, NIVectorScalarMultiply(aroundVector, NIVectorDotProduct(vector2, aroundVector)));

    crossProduct = NIVectorCrossProduct(vector1, vector2);

#if CGFLOAT_IS_DOUBLE
    angle = atan2(NIVectorLength(crossProduct), NIVectorDotProduct(vector1, vector2));
#else
    angle = atan2f(NIVectorLength(crossProduct), NIVectorDotProduct(vector1, vector2));
#endif

    if (NIVectorDotProduct(crossProduct, aroundVector) < 0.0) {
        angle = M_PI*2 - angle;
    }

    return angle;
}

CGFloat NIVectorLength(NIVector vector)
{
#if CGFLOAT_IS_DOUBLE
    return sqrt(NIVectorDotProduct(vector, vector));
#else
    return sqrtf(NIVectorDotProduct(vector, vector));
#endif
}

NIVector NIVectorNormalize(NIVector vector)
{
    CGFloat length;
    length = NIVectorLength(vector);
    if (length == 0.0) {
        return NIVectorZero;
    } else {
        return NIVectorScalarMultiply(vector, 1.0/length);
    }
}

NIVector NIVectorProject(NIVector vector1, NIVector vector2) // project vector1 onto vector2
{
    CGFloat length;
    length = NIVectorLength(vector2);
    if (length != 0.0) {
        return NIVectorScalarMultiply(vector2, NIVectorDotProduct(vector1, vector2) / length);
    } else {
        return NIVectorZero;
    }
}

NIVector NIVectorProjectPerpendicularToVector(NIVector perpendicularVector, NIVector directionVector)
{
    NIVector normalizedPerpendicular = NIVectorNormalize(perpendicularVector);
    return NIVectorSubtract(directionVector, NIVectorScalarMultiply(normalizedPerpendicular, NIVectorDotProduct(normalizedPerpendicular, directionVector)));
}

NIVector NIVectorInvert(NIVector vector)
{
    return NIVectorSubtract(NIVectorZero, vector);
}

NIVector NIVectorRound(NIVector vector)
{
    NIVector newVector;
#if CGFLOAT_IS_DOUBLE
    newVector.x = round(vector.x);
    newVector.y = round(vector.y);
    newVector.z = round(vector.z);
#else
    newVector.x = roundf(vector.x);
    newVector.y = roundf(vector.y);
    newVector.z = roundf(vector.z);
#endif
    return newVector;
}

NIVector NIVectorApplyTransform(NIVector vector, NIAffineTransform transform)
{
    NIVector newVector;

    assert(NIAffineTransformIsAffine(transform));

    newVector.x = (vector.x*transform.m11)+(vector.y*transform.m21)+(vector.z*transform.m31)+transform.m41;
    newVector.y = (vector.x*transform.m12)+(vector.y*transform.m22)+(vector.z*transform.m32)+transform.m42;
    newVector.z = (vector.x*transform.m13)+(vector.y*transform.m23)+(vector.z*transform.m33)+transform.m43;

    return newVector;
}

NIVector NIVectorApplyTransformToDirectionalVector(NIVector vector, NIAffineTransform transform)
{
    NIVector newVector;

    assert(NIAffineTransformIsAffine(transform));

    newVector.x = (vector.x*transform.m11)+(vector.y*transform.m21)+(vector.z*transform.m31);
    newVector.y = (vector.x*transform.m12)+(vector.y*transform.m22)+(vector.z*transform.m32);
    newVector.z = (vector.x*transform.m13)+(vector.y*transform.m23)+(vector.z*transform.m33);

    return newVector;
}

void NIVectorScalarMultiplyVectors(CGFloat scalar, NIVectorArray vectors, CFIndex numVectors)
{
#if CGFLOAT_IS_DOUBLE
    vDSP_vsmulD((CGFloat *)vectors, 1, &scalar, (CGFloat *)vectors, 1, numVectors*3);
#else
    vDSP_vsmul((CGFloat *)vectors, 1, &scalar, (CGFloat *)vectors, 1, numVectors*3);
#endif
}

void NIVectorCrossProductVectors(NIVector vector, NIVectorArray vectors, CFIndex numVectors)
{
    CFIndex i;

    for (i = 0; i < numVectors; i++) {
        vectors[i] = NIVectorCrossProduct(vector, vectors[i]);
    }
}

void NIVectorAddVectors(NIVectorArray vectors1, const NIVectorArray vectors2, CFIndex numVectors)
{
#if CGFLOAT_IS_DOUBLE
    vDSP_vaddD((CGFloat *)vectors1, 1, (CGFloat *)vectors2, 1, (CGFloat *)vectors1, 1, numVectors*3);
#else
    vDSP_vadd((CGFloat *)vectors1, 1, (CGFloat *)vectors2, 1, (CGFloat *)vectors1, 1, numVectors*3);
#endif
}

void NIVectorApplyTransformToVectors(NIAffineTransform transform, NIVectorArray vectors, CFIndex numVectors)
{
    CGFloat *transformedVectors;
    CGFloat smallTransform[9];

    assert(NIAffineTransformIsAffine(transform));

    transformedVectors = malloc(numVectors * sizeof(CGFloat) * 3);
    smallTransform[0] = transform.m11;
    smallTransform[1] = transform.m12;
    smallTransform[2] = transform.m13;
    smallTransform[3] = transform.m21;
    smallTransform[4] = transform.m22;
    smallTransform[5] = transform.m23;
    smallTransform[6] = transform.m31;
    smallTransform[7] = transform.m32;
    smallTransform[8] = transform.m33;

#if CGFLOAT_IS_DOUBLE
    vDSP_mmulD((CGFloat *)vectors, 1, smallTransform, 1, (CGFloat *)transformedVectors, 1, numVectors, 3, 3);
    vDSP_vsaddD(transformedVectors, 3, &transform.m41, (CGFloat *)vectors, 3, numVectors);
    vDSP_vsaddD(transformedVectors + 1, 3, &transform.m42, ((CGFloat *)vectors) + 1, 3, numVectors);
    vDSP_vsaddD(transformedVectors + 2, 3, &transform.m43, ((CGFloat *)vectors) + 2, 3, numVectors);
#else
    vDSP_mmul((CGFloat *)vectors, 1, smallTransform, 1, (CGFloat *)transformedVectors, 1, numVectors, 3, 3);
    vDSP_vsadd(transformedVectors, 3, &transform.m41, (CGFloat *)vectors, 3, numVectors);
    vDSP_vsadd(transformedVectors + 1, 3, &transform.m42, ((CGFloat *)vectors) + 1, 3, numVectors);
    vDSP_vsadd(transformedVectors + 2, 3, &transform.m43, ((CGFloat *)vectors) + 2, 3, numVectors);
#endif

    free(transformedVectors);
}

void NIVectorCrossProductWithVectors(NIVectorArray vectors1, const NIVectorArray vectors2, CFIndex numVectors)
{
    CFIndex i;

    for (i = 0; i < numVectors; i++) {
        vectors1[i] = NIVectorCrossProduct(vectors1[i], vectors2[i]);
    }
}

void NIVectorNormalizeVectors(NIVectorArray vectors, CFIndex numVectors)
{
    CFIndex i;

    for (i = 0; i < numVectors; i++) {
        vectors[i] = NIVectorNormalize(vectors[i]);
    }
}

NSPoint NSPointApplyNIAffineTransform(NSPoint point, NIAffineTransform transform)
{
    return NSPointFromNIVector(NIVectorApplyTransform(NIVectorMakeFromNSPoint(point), transform));
}

NIVector NIVectorLerp(NIVector vector1, NIVector vector2, CGFloat t)
{
    return NIVectorAdd(NIVectorScalarMultiply(vector1, 1.0 - t), NIVectorScalarMultiply(vector2, t));
}

NIVector NIVectorBend(NIVector vectorToBend, NIVector originalDirection, NIVector newDirection) // this aught to be re-written to be more numerically stable!
{
    NIAffineTransform rotateTransform;
    NIVector rotationAxis;
    NIVector bentVector;
    CGFloat angle;

    rotationAxis = NIVectorCrossProduct(NIVectorNormalize(originalDirection), NIVectorNormalize(newDirection));

#if CGFLOAT_IS_DOUBLE
    angle = asin(MIN(NIVectorLength(rotationAxis), 1.0));
#else
    angle = asinf(MIN(NIVectorLength(rotationAxis), 1.0f));
#endif

    if (NIVectorDotProduct(originalDirection, newDirection) < 0.0) {
        angle = M_PI - angle;
    }

    rotateTransform = NIAffineTransformMakeRotationAroundVector(angle, rotationAxis);

    bentVector = NIVectorApplyTransform(vectorToBend, rotateTransform);
    return bentVector;
}

bool NIVectorIsOnLine(NIVector vector, NILine line)
{
    return NIVectorDistanceToLine(vector, line) < _NIGeometrySmallNumber;
}

bool NIVectorIsOnPlane(NIVector vector, NIPlane plane)
{
    NIVector planeNormal;
    planeNormal = NIVectorNormalize(plane.normal);
    return ABS(NIVectorDotProduct(planeNormal, NIVectorSubtract(vector, plane.point))) < _NIGeometrySmallNumber;
}

CGFloat NIVectorDistanceToLine(NIVector vector, NILine line)
{
    NIVector translatedPoint;
    assert(NILineIsValid(line));
    translatedPoint = NIVectorSubtract(vector, line.point);
    return NIVectorLength(NIVectorSubtract(translatedPoint, NIVectorProject(translatedPoint, line.vector)));
}

CGFloat NIVectorDistanceToPlane(NIVector vector, NIPlane plane)
{
    return ABS(NIVectorDotProduct(NIVectorSubtract(vector, plane.point), NIVectorNormalize(plane.normal)));
}

NILine NILineMake(NIVector point, NIVector vector)
{
    NILine line;
    line.point = point;
    line.vector = vector;
    assert(NILineIsValid(line));
    return line;
}

NILine NILineMakeFromPoints(NIVector point1, NIVector point2)
{
    NILine line;
    line.point = point1;
    line.vector = NIVectorNormalize(NIVectorSubtract(point2, point1));
    assert(NILineIsValid(line));
    return line;
}

bool NILineEqualToLine(NILine line1, NILine line2)
{
    return NIVectorEqualToVector(line1.point, line2.point) && NIVectorEqualToVector(line1.vector, line2.vector);
}

bool NILineIsCoincidentToLine(NILine line1, NILine line2)
{
    if (NILineIsParallelToLine(line1, line2) == false) {
        return false;
    }
    return NIVectorIsOnLine(line1.point, line2);
}

bool NILineIsOnPlane(NILine line, NIPlane plane)
{
    if (NIVectorIsOnPlane(line.point, plane) == false) {
        return false;
    }
    return ABS(NIVectorDotProduct(line.vector, plane.normal)) < _NIGeometrySmallNumber;
}

bool NILineIsParallelToLine(NILine line1, NILine line2)
{
    if (NIVectorLength(NIVectorCrossProduct(line1.vector, line2.vector)) < _NIGeometrySmallNumber) {
        return true;
    }
    return false;
}

bool NILineIsValid(NILine line)
{
    return NIVectorLength(line.vector) > _NIGeometrySmallNumber;
}

bool NILineIntersectsPlane(NILine line, NIPlane plane)
{
    if (ABS(NIVectorDotProduct(plane.normal, line.vector)) < _NIGeometrySmallNumber) {
        if (NIVectorIsOnPlane(line.point, plane) == false) {
            return false;
        }
    }
    return true;
}

NIVector NILineIntersectionWithPlane(NILine line, NIPlane plane)
{
    CGFloat numerator;
    CGFloat denominator;
    NIVector planeNormal;
    NIVector lineVector;

    planeNormal = NIVectorNormalize(plane.normal);
    lineVector = NIVectorNormalize(line.vector);

    numerator = NIVectorDotProduct(planeNormal, NIVectorSubtract(plane.point, line.point));
    denominator = NIVectorDotProduct(planeNormal, lineVector);

    if (ABS(denominator) < _NIGeometrySmallNumber) {
        if (numerator < 0.0) {
            return NIVectorAdd(line.point, NIVectorScalarMultiply(lineVector, -(CGFLOAT_MAX/1.0e10)));
        } else if (numerator > 0.0) {
            return NIVectorAdd(line.point, NIVectorScalarMultiply(lineVector, (CGFLOAT_MAX/1.0e10)));
        } else {
            return line.point;
        }
    }

    return NIVectorAdd(line.point, NIVectorScalarMultiply(lineVector, numerator/denominator));
}


NIVector NILinePointClosestToVector(NILine line, NIVector vector)
{
    return NIVectorAdd(NIVectorProject(NIVectorSubtract(vector, line.point), line.vector), line.point);
}

NILine NILineApplyTransform(NILine line, NIAffineTransform transform)
{
    NILine newLine;
    newLine.point = NIVectorApplyTransform(line.point, transform);
    newLine.vector = NIVectorNormalize(NIVectorApplyTransformToDirectionalVector(line.vector, transform));
    assert(NILineIsValid(newLine));
    return newLine;
}

CGFloat NILineClosestPoints(NILine line1, NILine line2, NIVectorPointer line1PointPtr, NIVectorPointer line2PointPtr) // given two lines, find points on each line that are the closest to each other, note that the line that goes through these two points will be normal to both lines
{
    NIVector p13, p43, p21, p1, p3, pa, pb;
    CGFloat d1343, d4321, d1321, d4343, d2121;
    CGFloat numerator, denominator;
    CGFloat mua, mub;

    assert(NILineIsValid(line1) && NILineIsValid(line2));

    if (NILineIsParallelToLine(line1, line2)) {
        pa = line1.point;
        pb = NIVectorAdd(line2.point, NIVectorProject(NIVectorSubtract(line2.point, line1.point), line2.vector));
        return NIVectorDistance(pa, pb);
    } else {
        p1 = line1.point;
        p3 = line2.point;

        p13 = NIVectorSubtract(p1, p3);
        p21 = line1.vector;
        p43 = line2.vector;

        d1343 = NIVectorDotProduct(p13, p43);
        d4321 = NIVectorDotProduct(p43, p21);
        d1321 = NIVectorDotProduct(p13, p21);
        d4343 = NIVectorDotProduct(p43, p43);
        d2121 = NIVectorDotProduct(p21, p21);

        numerator = d1343*d4321 - d1321*d4343;
        denominator = d2121*d4343 - d4321*d4321;

        if (denominator == 0.0) { // as can happen if the lines were almost parallel
            pa = line1.point;
            pb = NIVectorAdd(line2.point, NIVectorProject(NIVectorSubtract(line2.point, line1.point), line2.vector));
            return NIVectorDistance(pa, pb);
        }
        mua = numerator / denominator;
        assert(d4343); // this should never happen, otherwise the line2 would not be valid
        mub = (d1343 + d4321*mua) / d4343;

        pa = NIVectorAdd(p1, NIVectorScalarMultiply(p21, mua));
        pb = NIVectorAdd(p3, NIVectorScalarMultiply(p43, mub));
    }

    if (line1PointPtr) {
        *line1PointPtr = pa;
    }
    if (line2PointPtr) {
        *line2PointPtr = pb;
    }

    return NIVectorDistance(pa, pb);
}

CFIndex NILineIntersectionWithSphere(NILine line, NIVector sphereCenter, CGFloat sphereRadius, NIVectorPointer firstIntersection, NIVectorPointer secondIntersection) // returns the number of intersection
{
    CGFloat u = NIVectorDotProduct(line.vector, NIVectorSubtract(line.point, sphereCenter));
    CGFloat v = NIVectorDistance(line.point, sphereCenter);

    CGFloat discriminant = (u*u) - (v*v) + (sphereRadius*sphereRadius);

    if (discriminant < 0) {
        return 0;
    }

#if CGFLOAT_IS_DOUBLE
    CGFloat root = sqrt(discriminant);
#else
    CGFloat root = sqrtf(discriminant);
#endif

    if (firstIntersection) {
        *firstIntersection = NIVectorAdd(line.point, NIVectorScalarMultiply(line.vector, -u - root));
    }
    if (secondIntersection) {
        *secondIntersection = NIVectorAdd(line.point, NIVectorScalarMultiply(line.vector, -u + root));
    }

    return discriminant == 0 ? 1 : 2;
}


NIPlane NIPlaneMake(NIVector point, NIVector normal)
{
    NIPlane plane;
    plane.point = point;
    plane.normal = normal;
    return plane;
}

bool NIPlaneEqualToPlane(NIPlane plane1, NIPlane plane2)
{
    return NIVectorEqualToVector(plane1.point, plane2.point) && NIVectorEqualToVector(plane1.normal, plane2.normal);
}

bool NIPlaneIsCoincidentToPlane(NIPlane plane1, NIPlane plane2)
{
    if (NIVectorLength(NIVectorCrossProduct(plane1.normal, plane2.normal)) > _NIGeometrySmallNumber) {
        return false;
    }
    return NIVectorIsOnPlane(plane1.point, plane2);
}

bool NIPlaneIsValid(NIPlane plane)
{
    return NIVectorLength(plane.normal) > _NIGeometrySmallNumber;
}

NIPlane NIPlaneLeastSquaresPlaneFromPoints(NIVectorArray vectors, CFIndex numVectors)
{
#define N 3
#define LDA N
    
    if (numVectors < 3)
        return NIPlaneInvalid;
    
    if (numVectors == 3) {
        NIVector cp = NIVectorCrossProduct(NIVectorSubtract(vectors[0], vectors[1]), NIVectorSubtract(vectors[0], vectors[2]));
        if (NIVectorLength(cp) == 0)
            return NIPlaneInvalid;
        return NIPlaneMake(vectors[0], NIVectorNormalize(cp));
    }
    
    // calculate center of mass
    __CLPK_doublereal c[3] = {0,0,0};
    for (CFIndex i = 0; i < numVectors; ++i) {
        c[0] += vectors[i].x; c[1] += vectors[i].y; c[2] += vectors[i].z; }
    c[0] /= numVectors; c[1] /= numVectors; c[2] /= numVectors;
    
    // assemble covariance matrix - column-wise matrix indexes: [ 0 3 6 ]
    //                                                          [ x 4 7 ]
    //                                                          [ x x 8 ]
    __CLPK_doublereal a[LDA*N] = {0,0,0,0,0,0,0,0,0}; // input covariance, output eigenvectors
    for (CFIndex i = 0; i < numVectors; ++i) {
        __CLPK_doublereal d[3] = {vectors[i].x-c[0], vectors[i].y-c[1], vectors[i].z-c[2]};
        a[0] += d[0]*d[0];
        a[3] += d[0]*d[1];
        a[4] += d[1]*d[1];
        a[6] += d[0]*d[2];
        a[7] += d[1]*d[2];
        a[8] += d[2]*d[2];
    }
    
    // compute eigenvalues and eigenvectors
    
    __CLPK_integer n = N, lda = LDA, info = 0, lwork = -1, liwork = -1, iwkopt;
    __CLPK_doublereal w[N]; // the output eigenvalues
    __CLPK_doublereal wkopt;
    
    dsyevd("V", "U", &n, a, &lda, w, &wkopt, &lwork, &iwkopt, &liwork, &info);
    
    lwork = (int)wkopt;
    __CLPK_doublereal* work = (__CLPK_doublereal*)calloc(lwork, sizeof(__CLPK_doublereal));
    liwork = iwkopt;
    __CLPK_integer* iwork = (__CLPK_integer*)calloc(liwork, sizeof(__CLPK_integer));
    
    dsyevd("V", "U", &n, a, &lda, w, work, &lwork, iwork, &liwork, &info);
    
    free(iwork);
    free(work);
    
    // return the plane
    
    if (info != 0 || (w[0] <= 0 && w[1] <= 0)) // lapack error OR points are aligned
        return NIPlaneInvalid;
    
    if(w[0] == w[1] && w[1] == w[2]) // degenerate case - return a default horizontal plane that goes through the centroid
        return NIPlaneMake(NIVectorMake(c[0], c[1], c[2]), NIVectorZBasis);

    return NIPlaneMake(NIVectorMake(c[0], c[1], c[2]), NIVectorNormalize(NIVectorMake(a[0], a[1], a[2])));
    
#undef N
#undef LDA
}


NIPlane NIPlaneApplyTransform(NIPlane plane, NIAffineTransform transform)
{
    NIPlane newPlane;
    NIAffineTransform normalTransform;

    newPlane.point = NIVectorApplyTransform(plane.point, transform);
    normalTransform = transform;
    normalTransform.m41 = 0.0; normalTransform.m42 = 0.0; normalTransform.m43 = 0.0;

    newPlane.normal = NIVectorNormalize(NIVectorApplyTransform(plane.normal, NIAffineTransformTranspose(NIAffineTransformInvert(normalTransform))));
    assert(NIPlaneIsValid(newPlane));
    return newPlane;
}

NIVector NIPlanePointClosestToVector(NIPlane plane, NIVector vector)
{
    NIVector planeNormal;
    planeNormal = NIVectorNormalize(plane.normal);
    return NIVectorAdd(vector, NIVectorScalarMultiply(planeNormal, NIVectorDotProduct(planeNormal, NIVectorSubtract(plane.point, vector))));
}

bool NIPlaneIsParallelToPlane(NIPlane plane1, NIPlane plane2)
{
    return NIVectorLength(NIVectorCrossProduct(plane1.normal, plane2.normal)) <= _NIGeometrySmallNumber;
}

bool NIPlaneIsBetweenVectors(NIPlane plane, NIVector vector1, NIVector vector2)
{
    return NIVectorDotProduct(plane.normal, NIVectorSubtract(vector2, plane.point)) < 0.0 != NIVectorDotProduct(plane.normal, NIVectorSubtract(vector1, plane.point)) < 0.0;
}

NILine NIPlaneIntersectionWithPlane(NIPlane plane1, NIPlane plane2)
{
    NILine line;
    NILine intersectionLine;

    line.vector = NIVectorNormalize(NIVectorCrossProduct(plane1.normal, plane2.normal));

    if (NIVectorIsZero(line.vector)) { // if the planes do not intersect, return halfway-reasonable BS
        line.vector = NIVectorNormalize(NIVectorCrossProduct(plane1.normal, NIVectorMake(1.0, 0.0, 0.0)));
        if (NIVectorIsZero(line.vector)) {
            line.vector = NIVectorNormalize(NIVectorCrossProduct(plane1.normal, NIVectorMake(0.0, 1.0, 0.0)));
        }
        line.point = plane1.point;
        return line;
    }

    intersectionLine.point = plane1.point;
    intersectionLine.vector = NIVectorNormalize(NIVectorSubtract(plane2.normal, NIVectorProject(plane2.normal, plane1.normal)));
    line.point = NILineIntersectionWithPlane(intersectionLine, plane2);
    return line;
}


bool NIAffineTransformIsRectilinear(NIAffineTransform t) // this is not the right term, but what is a transform that only includes scale and translation called?
{
    return (                t.m12 == 0.0 && t.m13 == 0.0 && t.m14 == 0.0 &&
            t.m21 == 0.0 &&                 t.m23 == 0.0 && t.m24 == 0.0 &&
            t.m31 == 0.0 && t.m32 == 0.0 &&                 t.m34 == 0.0 &&
            t.m44 == 1.0);
}

NIAffineTransform NIAffineTransformTranspose(NIAffineTransform t)
{
    NIAffineTransform transpose;

    transpose.m11 = t.m11; transpose.m12 = t.m21; transpose.m13 = t.m31; transpose.m14 = t.m41;
    transpose.m21 = t.m12; transpose.m22 = t.m22; transpose.m23 = t.m32; transpose.m24 = t.m42;
    transpose.m31 = t.m13; transpose.m32 = t.m23; transpose.m33 = t.m33; transpose.m34 = t.m43;
    transpose.m41 = t.m14; transpose.m42 = t.m24; transpose.m43 = t.m34; transpose.m44 = t.m44;
    return transpose;
}

CGFloat NIAffineTransformDeterminant(NIAffineTransform t)
{
    assert(NIAffineTransformIsAffine(t));

    return t.m11*t.m22*t.m33 + t.m21*t.m32*t.m13 + t.m31*t.m12*t.m23 - t.m11*t.m32*t.m23 - t.m21*t.m12*t.m33 - t.m31*t.m22*t.m13;
}

NIAffineTransform NIAffineTransformInvert(NIAffineTransform t)
{
    BOOL isAffine;
    NIAffineTransform inverse;

    isAffine = NIAffineTransformIsAffine(t);
    inverse = CATransform3DInvert(t);

    if (isAffine) { // in some cases CATransform3DInvert returns a matrix that does not have exactly these values even if the input matrix did have these values
        inverse.m14 = 0.0;
        inverse.m24 = 0.0;
        inverse.m34 = 0.0;
        inverse.m44 = 1.0;
    }
    return inverse;
}

NIAffineTransform NIAffineTransformConcat(NIAffineTransform a, NIAffineTransform b)
{
    BOOL affine;
    NIAffineTransform concat;

    affine = NIAffineTransformIsAffine(a) && NIAffineTransformIsAffine(b);
    concat = CATransform3DConcat(a, b);

    if (affine) { // in some cases CATransform3DConcat returns a matrix that does not have exactly these values even if the input matrix did have these values
        concat.m14 = 0.0;
        concat.m24 = 0.0;
        concat.m34 = 0.0;
        concat.m44 = 1.0;
    }
    return concat;
}

NSString *NSStringFromNIAffineTransform(NIAffineTransform transform)
{
    return [NSString stringWithFormat:@"{{%8.2f, %8.2f, %8.2f, %8.2f}\n {%8.2f, %8.2f, %8.2f, %8.2f}\n {%8.2f, %8.2f, %8.2f, %8.2f}\n {%8.2f, %8.2f, %8.2f, %8.2f}}",
            transform.m11, transform.m12, transform.m13, transform.m14, transform.m21, transform.m22, transform.m23, transform.m24,
            transform.m31, transform.m32, transform.m33, transform.m34, transform.m41, transform.m42, transform.m43, transform.m44];
}

NSString *NSStringFromNIVector(NIVector vector)
{
    return [NSString stringWithFormat:@"{%f, %f, %f}", vector.x, vector.y, vector.z];
}

NSString *NSStringFromNILine(NILine line)
{
    return [NSString stringWithFormat:@"{%@, %@}", NSStringFromNIVector(line.point), NSStringFromNIVector(line.vector)];
}

NSString *NSStringFromNIPlane(NIPlane plane)
{
    return [NSString stringWithFormat:@"{%@, %@}", NSStringFromNIVector(plane.point), NSStringFromNIVector(plane.normal)];
}

NSString *NIVectorCArmOrientationString(NIVector vector)
{
    NIVector normalizedVector = NIVectorNormalize(vector);
    NSMutableString *string = [NSMutableString string];

    NIVector aoProjectedVector = NIVectorNormalize(NIVectorProjectPerpendicularToVector(NIVectorZBasis, normalizedVector));

    CGFloat aoAngle = NIVectorAngleBetweenVectors(aoProjectedVector, NIVectorMake(0, -1, 0));
    if (normalizedVector.x > 0) {
        [string appendFormat:@"LAO %.2f, ", aoAngle * (180.0/M_PI)];
    } else {
        [string appendFormat:@"RAO %.2f, ", aoAngle * (180.0/M_PI)];
    }

    CGFloat crAngle = NIVectorAngleBetweenVectors(normalizedVector, aoProjectedVector);
    if (normalizedVector.z > 0) {
        [string appendFormat:@"CR %.2f", crAngle * (180.0/M_PI)];
    } else {
        [string appendFormat:@"CA %.2f", crAngle * (180.0/M_PI)];
    }

    return string;
}

CFDictionaryRef NIAffineTransformCreateDictionaryRepresentation(NIAffineTransform transform)
{
    CFDictionaryRef dict;
    CFStringRef keys[16];
    CFNumberRef numbers[16];

    int i;
    int j;

    for (i = 0; i < 4; i++) {
        for (j = 0; j < 4; j++) {
            CFStringRef label = CFStringCreateWithFormat (NULL, NULL, CFSTR("m%d%d"), i+1, j+1);
            keys[(i*4)+j] = label;
        }
    }

    numbers[0] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m11));
    numbers[1] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m12));
    numbers[2] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m13));
    numbers[3] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m14));
    numbers[4] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m21));
    numbers[5] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m22));
    numbers[6] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m23));
    numbers[7] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m24));
    numbers[8] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m31));
    numbers[9] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m32));
    numbers[10] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m33));
    numbers[11] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m34));
    numbers[12] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m41));
    numbers[13] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m42));
    numbers[14] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m43));
    numbers[15] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(transform.m44));

    dict = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)numbers, 16, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    for (i = 0; i < 16; i++) {
        CFRelease(keys[i]);
        CFRelease(numbers[i]);
    }

    return dict;
}

CFDictionaryRef NIVectorCreateDictionaryRepresentation(NIVector vector)
{
    CFDictionaryRef dict;
    CFStringRef keys[3];
    CFNumberRef numbers[3];

    keys[0] = CFSTR("x");
    keys[1] = CFSTR("y");
    keys[2] = CFSTR("z");

    numbers[0] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(vector.x));
    numbers[1] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(vector.y));
    numbers[2] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(vector.z));

    dict = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)numbers, 3, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    CFRelease(numbers[0]);
    CFRelease(numbers[1]);
    CFRelease(numbers[2]);

    return dict;
}

CFDictionaryRef NILineCreateDictionaryRepresentation(NILine line)
{
    CFDictionaryRef pointDict;
    CFDictionaryRef vectorDict;
    CFDictionaryRef lineDict;

    pointDict = NIVectorCreateDictionaryRepresentation(line.point);
    vectorDict = NIVectorCreateDictionaryRepresentation(line.vector);
    lineDict = (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:(id)pointDict, @"point", (id)vectorDict, @"vector", nil];
    CFRelease(pointDict);
    CFRelease(vectorDict);
    return lineDict;
}

CFDictionaryRef NIPlaneCreateDictionaryRepresentation(NIPlane plane)
{
    CFDictionaryRef pointDict;
    CFDictionaryRef normalDict;
    CFDictionaryRef lineDict;

    pointDict = NIVectorCreateDictionaryRepresentation(plane.point);
    normalDict = NIVectorCreateDictionaryRepresentation(plane.normal);
    lineDict = (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:(id)pointDict, @"point", (id)normalDict, @"normal", nil];
    CFRelease(pointDict);
    CFRelease(normalDict);
    return lineDict;
}

bool NIAffineTransformMakeWithDictionaryRepresentation(CFDictionaryRef dict, NIAffineTransform *transform)
{
    CFStringRef keys[16];
    CFNumberRef numbers[16];
    CGFloat* tranformPtrs[16];
    NIAffineTransform tempTransform;

    memset(keys, 0, sizeof(CFStringRef) * 16);
    memset(numbers, 0, sizeof(CFNumberRef) * 16);

    int i;
    int j;

    for (i = 0; i < 4; i++) {
        for (j = 0; j < 4; j++) {
            CFStringRef label = CFStringCreateWithFormat (NULL, NULL, CFSTR("m%d%d"), i+1, j+1);
            keys[(i*4)+j] = label;
        }
    }

    tranformPtrs[0] = &(tempTransform.m11);
    tranformPtrs[1] = &(tempTransform.m12);
    tranformPtrs[2] = &(tempTransform.m13);
    tranformPtrs[3] = &(tempTransform.m14);
    tranformPtrs[4] = &(tempTransform.m21);
    tranformPtrs[5] = &(tempTransform.m22);
    tranformPtrs[6] = &(tempTransform.m23);
    tranformPtrs[7] = &(tempTransform.m24);
    tranformPtrs[8] = &(tempTransform.m31);
    tranformPtrs[9] = &(tempTransform.m32);
    tranformPtrs[10] = &(tempTransform.m33);
    tranformPtrs[11] = &(tempTransform.m34);
    tranformPtrs[12] = &(tempTransform.m41);
    tranformPtrs[13] = &(tempTransform.m42);
    tranformPtrs[14] = &(tempTransform.m43);
    tranformPtrs[15] = &(tempTransform.m44);

    for (i = 0; i < 16; i++) {
        numbers[i] = CFDictionaryGetValue(dict, keys[i]);
        CFRelease(keys[i]);
        if (numbers[i] == NULL || CFGetTypeID(numbers[i]) != CFNumberGetTypeID()) {
            for (j = i+1; j < 16; j++) {
                CFRelease(keys[j]);
            }
            return false;
        }
    }

    for (i = 0; i < 16; i++) {
        CFNumberGetValue(numbers[i], kCFNumberCGFloatType, tranformPtrs[i]);
    }

    if (transform) {
        *transform = tempTransform;
    }

    return true;
}

bool NIVectorMakeWithDictionaryRepresentation(CFDictionaryRef dict, NIVector *vector)
{
    CFNumberRef x;
    CFNumberRef y;
    CFNumberRef z;
    NIVector tempVector;

    if (dict == NULL) {
        return false;
    }

    x = CFDictionaryGetValue(dict, CFSTR("x"));
    y = CFDictionaryGetValue(dict, CFSTR("y"));
    z = CFDictionaryGetValue(dict, CFSTR("z"));

    if (x == NULL || CFGetTypeID(x) != CFNumberGetTypeID() ||
        y == NULL || CFGetTypeID(y) != CFNumberGetTypeID() ||
        z == NULL || CFGetTypeID(z) != CFNumberGetTypeID()) {
        return false;
    }

    CFNumberGetValue(x, kCFNumberCGFloatType, &(tempVector.x));
    CFNumberGetValue(y, kCFNumberCGFloatType, &(tempVector.y));
    CFNumberGetValue(z, kCFNumberCGFloatType, &(tempVector.z));

    //	if (CFNumberGetValue(x, kCFNumberCGFloatType, &(tempVector.x)) == false) {
    //		return false;    NO ! CFNumberGetValue can return false, if the value was saved in float 64 bit, and then converted to a lossy 32 bit : this situation happens if the path was created in an OsiriX 64-bit version, then loaded in OsiriX 32-bit
    // If the argument type differs from the return type, and the conversion is lossy or the return value is out of range, then this function passes back an approximate value in valuePtr and returns false.
    //	}
    //	if (CFNumberGetValue(y, kCFNumberCGFloatType, &(tempVector.y)) == false) {
    //		return false;
    //	}
    //	if (CFNumberGetValue(z, kCFNumberCGFloatType, &(tempVector.z)) == false) {
    //		return false;
    //	}

    if (vector) {
        *vector = tempVector;
    }

    return true;
}

bool NILineMakeWithDictionaryRepresentation(CFDictionaryRef dict, NILine *line)
{
    NILine tempLine;
    CFDictionaryRef pointDict;
    CFDictionaryRef vectorDict;

    if (dict == NULL) {
        return false;
    }

    pointDict = CFDictionaryGetValue(dict, @"point");
    vectorDict = CFDictionaryGetValue(dict, @"vector");

    if (pointDict == NULL || CFGetTypeID(pointDict) != CFDictionaryGetTypeID() ||
        vectorDict == NULL || CFGetTypeID(vectorDict) != CFDictionaryGetTypeID()) {
        return false;
    }

    if (NIVectorMakeWithDictionaryRepresentation(pointDict, &(tempLine.point)) == false) {
        return false;
    }
    if (NIVectorMakeWithDictionaryRepresentation(vectorDict, &(tempLine.vector)) == false) {
        return false;
    }

    if (line) {
        *line = tempLine;
    }
    return true;
}

bool NIPlaneMakeWithDictionaryRepresentation(CFDictionaryRef dict, NIPlane *plane)
{
    NIPlane tempPlane;
    CFDictionaryRef pointDict;
    CFDictionaryRef normalDict;

    if (dict == NULL) {
        return false;
    }

    pointDict = CFDictionaryGetValue(dict, @"point");
    normalDict = CFDictionaryGetValue(dict, @"normal");

    if (pointDict == NULL || CFGetTypeID(pointDict) != CFDictionaryGetTypeID() ||
        normalDict == NULL || CFGetTypeID(normalDict) != CFDictionaryGetTypeID()) {
        return false;
    }

    if (NIVectorMakeWithDictionaryRepresentation(pointDict, &(tempPlane.point)) == false) {
        return false;
    }
    if (NIVectorMakeWithDictionaryRepresentation(normalDict, &(tempPlane.normal)) == false) {
        return false;
    }

    if (plane) {
        *plane = tempPlane;
    }
    return true;
}

// returns the real numbered roots of ax+b
CFIndex findRealLinearRoot(CGFloat a, CGFloat b, CGFloat *root) // returns the number of roots set
{
    assert(root);

    if (a == 0) {
        return 0;
    }

    *root = -b/a;
    return 1;
}

// returns the real numbered roots of ax^2+bx+c
CFIndex findRealQuadraticRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat *root1, CGFloat *root2) // returns the number of roots set
{
    CGFloat discriminant;
    CGFloat q;

    assert(root1);
    assert(root2);

    if (a == 0) {
        return findRealLinearRoot(b, c, root1);
    }

    discriminant = b*b - 4.0*a*c;

    if (discriminant < 0.0) {
        return 0;
    } else if (discriminant == 0) {
        *root1 = b / (a * -2.0);
        return 1;
    }

#if CGFLOAT_IS_DOUBLE
    if (b == 0) {
        *root1 = sqrt(c/a);
        *root2 = -*root1;
        return 2;
    }
    q = (b + copysign(sqrt(discriminant), b)) * 0.5;
#else
    if (b == 0) {
        *root1 = sqrtf(c/a);
        *root2 = *root1 * -1.0;
        return 2;
    }
    q = (b + copysignf(sqrtf(discriminant), b)) * 0.5f;
#endif
    *root1 = q / a;
    *root2 = c / q;

    return 2;
}

// returns the real numbered roots of ax^3+bx^2+cx+d
CFIndex findRealCubicRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat d, CGFloat *root1, CGFloat *root2, CGFloat *root3) // returns the number of roots set
{
    CGFloat Q;
    CGFloat R;
    CGFloat A;
    CGFloat B;
    CGFloat theta;
    CGFloat R2;
    CGFloat Q3;
    CGFloat sqrtQ_2;
    CGFloat b_3;

    if (a == 0) {
        return findRealQuadraticRoots(b, c, d, root1, root2);
    }

    b /= a;
    c /= a;
    d /= a;

    Q = (b*b - 3.0*c)/9.0;
    R = (2.0*b*b*b - 9.0*b*c + 27.0*d)/54.0;

    R2 = R*R;
    Q3 = Q*Q*Q;
    b_3 = b/3.0;

    if (R2 < Q3) {
#if CGFLOAT_IS_DOUBLE
        theta = acos(MAX(MIN(R/sqrt(Q3), 1.0), -1.0));
        sqrtQ_2 = -2.0*sqrt(Q);

        *root1 = sqrtQ_2*cos(theta/3.0)-b_3;
        *root2 = sqrtQ_2*cos((theta + 2.0*M_PI)/3.0)-b_3;
        if (theta == 0.0) {
            return 2;
        } else {
            *root3 = sqrtQ_2*cos((theta - 2.0*M_PI)/3.0)-b_3;
            return 3;
        }
#else
        theta = acosf(MAX(MIN(R/sqrtf(Q3), 1.0f), -1.0f));
        sqrtQ_2 = -2.0*sqrtf(Q);

        *root1 = sqrtQ_2*cosf(theta/3.0)-b_3;
        *root2 = sqrtQ_2*cosf((theta + 2.0*M_PI)/3.0)-b_3;
        if (theta == 0.0) {
            return 2;
        } else {
            *root3 = sqrtQ_2*cosf((theta - 2.0*M_PI)/3.0)-b_3;
            return 3;
        }
#endif
        return 3;
    }

#if CGFLOAT_IS_DOUBLE
    A = -1.0*copysign(pow(fabs(R)+sqrt(R2-Q3), 1.0/3.0), R);
#else
    A = -1.0*copysignf(powf(fabsf(R)+sqrtf(R2-Q3), 1.0/3.0), R);
#endif
    if (A == 0) {
        B = 0;
    } else {
        B = Q/A;
    }

    *root1 = (A+B)-b_3;
    return 1;
}

void NIAffineTransformGetOpenGLMatrixd(NIAffineTransform transform, double *d) // d better be 16 elements long
{
    d[0] =  transform.m11; d[1] =  transform.m12; d[2] =  transform.m13; d[3] =  transform.m14;
    d[4] =  transform.m21; d[5] =  transform.m22; d[6] =  transform.m23; d[7] =  transform.m24;
    d[8] =  transform.m31; d[9] =  transform.m32; d[10] = transform.m33; d[11] = transform.m34;
    d[12] = transform.m41; d[13] = transform.m42; d[14] = transform.m43; d[15] = transform.m44;
}

void NIAffineTransformGetOpenGLMatrixf(NIAffineTransform transform, float *f) // f better be 16 elements long
{
    f[0] =  transform.m11; f[1] =  transform.m12; f[2] =  transform.m13; f[3] =  transform.m14;
    f[4] =  transform.m21; f[5] =  transform.m22; f[6] =  transform.m23; f[7] =  transform.m24;
    f[8] =  transform.m31; f[9] =  transform.m32; f[10] = transform.m33; f[11] = transform.m34;
    f[12] = transform.m41; f[13] = transform.m42; f[14] = transform.m43; f[15] = transform.m44;
}

NIAffineTransform NIAffineTransformMakeFromOpenGLMatrixd(double *d) // d better be 16 elements long
{
    NIAffineTransform transform;
    transform.m11 = d[0];  transform.m12 = d[1];  transform.m13 = d[2];  transform.m14 = d[3];
    transform.m21 = d[4];  transform.m22 = d[5];  transform.m23 = d[6];  transform.m24 = d[7];
    transform.m31 = d[8];  transform.m32 = d[9];  transform.m33 = d[10]; transform.m34 = d[11];
    transform.m41 = d[12]; transform.m42 = d[13]; transform.m43 = d[14]; transform.m44 = d[15];
    return transform;
}

NIAffineTransform NIAffineTransformMakeFromOpenGLMatrixf(float *f) // f better be 16 elements long
{
    NIAffineTransform transform;
    transform.m11 = f[0];  transform.m12 = f[1];  transform.m13 = f[2];  transform.m14 = f[3];
    transform.m21 = f[4];  transform.m22 = f[5];  transform.m23 = f[6];  transform.m24 = f[7];
    transform.m31 = f[8];  transform.m32 = f[9];  transform.m33 = f[10]; transform.m34 = f[11];
    transform.m41 = f[12]; transform.m42 = f[13]; transform.m43 = f[14]; transform.m44 = f[15];
    return transform;
}

@implementation NSAffineTransform (NIGeometry)

+ (instancetype)transformWithNIAffineTransform:(NIAffineTransform)t {
    return [[[self.class alloc] initWithNIAffineTransform:t] autorelease];
}

- (id)initWithNIAffineTransform:(NIAffineTransform)t {
    if ((self = [self init])) {
        CGAffineTransform cgat = CATransform3DGetAffineTransform(t);
        NSAffineTransformStruct ts = {cgat.a, cgat.b, cgat.c, cgat.d, cgat.tx, cgat.ty};
        self.transformStruct = ts;
    }
    
    return self;
}

@end

@implementation NSValue (NIGeometryAdditions)

+ (NSValue *)valueWithNIVector:(NIVector)vector
{
    return [NSValue valueWithBytes:&vector objCType:@encode(NIVector)];
}

- (NIVector)NIVectorValue
{
    NIVector vector;
    assert(strcmp([self objCType], @encode(NIVector)) == 0);
    [self getValue:&vector];
    return vector;
}

+ (NSValue *)valueWithNILine:(NILine)line
{
    return [NSValue valueWithBytes:&line objCType:@encode(NILine)];
}

- (NILine)NILineValue
{
    NILine line;
    assert(strcmp([self objCType], @encode(NILine)) == 0);
    [self getValue:&line];
    return line;
}

+ (NSValue *)valueWithNIPlane:(NIPlane)plane
{
    return [NSValue valueWithBytes:&plane objCType:@encode(NIPlane)];

}

- (NIPlane)NIPlaneValue
{
    NIPlane plane;
    assert(strcmp([self objCType], @encode(NIPlane)) == 0);
    [self getValue:&plane];
    return plane;
}

+ (NSValue *)valueWithNIAffineTransform:(NIAffineTransform)transform
{
    return [NSValue valueWithBytes:&transform objCType:@encode(NIAffineTransform)];
}

- (NIAffineTransform)NIAffineTransformValue
{
    NIAffineTransform transform;
    assert(strcmp([self objCType], @encode(NIAffineTransform)) == 0 || strcmp([self objCType], @encode(CATransform3D)) == 0);
    [self getValue:&transform];
    return transform;
}

@end

@implementation NSCoder (NIGeometryAdditions)

- (void)encodeNIAffineTransform:(NIAffineTransform)transform forKey:(NSString *)key
{
    if ([self allowsKeyedCoding]) {
        NSDictionary *dict = (NSDictionary *)NIAffineTransformCreateDictionaryRepresentation(transform);
        [self encodeObject:dict forKey:key];
        [dict release];
    } else {
        [NSException raise:NSInvalidArchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }
}

- (void)encodeNIVector:(NIVector)vector forKey:(NSString *)key
{
    if ([self allowsKeyedCoding]) {
        NSDictionary *dict = (NSDictionary *)NIVectorCreateDictionaryRepresentation(vector);
        [self encodeObject:dict forKey:key];
        [dict release];
    } else {
        [NSException raise:NSInvalidArchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }
}

- (void)encodeNILine:(NILine)line forKey:(NSString *)key
{
    if ([self allowsKeyedCoding]) {
        NSDictionary *dict = (NSDictionary *)NILineCreateDictionaryRepresentation(line);
        [self encodeObject:dict forKey:key];
        [dict release];
    } else {
        [NSException raise:NSInvalidArchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }
}

- (void)encodeNIPlane:(NIPlane)plane forKey:(NSString *)key
{
    if ([self allowsKeyedCoding]) {
        NSDictionary *dict = (NSDictionary *)NIPlaneCreateDictionaryRepresentation(plane);
        [self encodeObject:dict forKey:key];
        [dict release];
    } else {
        [NSException raise:NSInvalidArchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }
}

- (NIAffineTransform)decodeNIAffineTransformForKey:(NSString *)key
{
    NIAffineTransform transform = NIAffineTransformIdentity;
    if ([self allowsKeyedCoding]) {
        NSDictionary *dict = [self decodeObjectOfClasses:[NSSet setWithObjects:[NSDictionary class], [NSString class], [NSNumber class], nil] forKey:key];
        if (dict == nil) {
            [NSException raise:@"NIDecode" format:@"No Dictionary when decoding NIAffineTranform"];
        }

        if (NIAffineTransformMakeWithDictionaryRepresentation((CFDictionaryRef)dict, &transform) == NO) {
            [NSException raise:@"NIDecode" format:@"Dictionary did not contain an NIAffineTranform"];
        }
    } else {
        [NSException raise:NSInvalidUnarchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }

    return transform;
}

- (NIVector)decodeNIVectorForKey:(NSString *)key
{
    NIVector vector = NIVectorZero;
    if ([self allowsKeyedCoding]) {
        NSDictionary *dict = [self decodeObjectOfClasses:[NSSet setWithObjects:[NSDictionary class], [NSString class], [NSNumber class], nil] forKey:key];
        if (dict == nil) {
            [NSException raise:@"NIDecode" format:@"No Dictionary when decoding NIVector"];
        }

        if (NIVectorMakeWithDictionaryRepresentation((CFDictionaryRef)dict, &vector) == NO) {
            [NSException raise:@"NIDecode" format:@"Dictionary did not contain an NIVector"];
        }
    } else {
        [NSException raise:NSInvalidUnarchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }

    return vector;
}

- (NILine)decodeNILineForKey:(NSString *)key
{
    NILine line = NILineInvalid;
    if ([self allowsKeyedCoding]) {
        NSDictionary *dict = [self decodeObjectOfClasses:[NSSet setWithObjects:[NSDictionary class], [NSString class], [NSNumber class], nil] forKey:key];
        if (dict == nil) {
            [NSException raise:@"NIDecode" format:@"No Dictionary when decoding NILine"];
        }
        
        if (NILineMakeWithDictionaryRepresentation((CFDictionaryRef)dict, &line) == NO) {
            [NSException raise:@"NIDecode" format:@"Dictionary did not contain an NILine"];
        }
    } else {
        [NSException raise:NSInvalidUnarchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }

    return line;
}


- (NIPlane)decodeNIPlaneForKey:(NSString *)key
{
    NIPlane plane = NIPlaneInvalid;
    if ([self allowsKeyedCoding]) {
        NSDictionary *dict = [self decodeObjectOfClasses:[NSSet setWithObjects:[NSDictionary class], [NSString class], [NSNumber class], nil] forKey:key];
        if (dict == nil) {
            [NSException raise:@"NIDecode" format:@"No Dictionary when decoding NIPlane"];
        }
        
        if (NIPlaneMakeWithDictionaryRepresentation((CFDictionaryRef)dict, &plane) == NO) {
            [NSException raise:@"NIDecode" format:@"Dictionary did not contain an NIPlane"];
        }
    } else {
        [NSException raise:NSInvalidUnarchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }

    return plane;
}


@end










