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

#include "NIBBGeometry.h"
#include <ApplicationServices/ApplicationServices.h>
#include <math.h>
#include <Accelerate/Accelerate.h>

static const CGFloat _NIBBGeometrySmallNumber = (CGFLOAT_MIN * 1E5);

const NIBBVector NIBBVectorZero = {0.0, 0.0, 0.0};
const NIBBVector NIBBVectorXBasis = {1.0, 0.0, 0.0};
const NIBBVector NIBBVectorYBasis = {0.0, 1.0, 0.0};
const NIBBVector NIBBVectorZBasis = {0.0, 0.0, 1.0};

const NIBBAffineTransform NIBBAffineTransformIdentity = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0};
const NIBBLine NIBBLineXAxis = {{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}};
const NIBBLine NIBBLineYAxis = {{0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}};
const NIBBLine NIBBLineZAxis = {{0.0, 0.0, 0.0}, {0.0, 0.0, 1.0}};
const NIBBLine NIBBLineInvalid = {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}};
const NIBBPlane NIBBPlaneXZero = {{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}};
const NIBBPlane NIBBPlaneYZero = {{0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}};
const NIBBPlane NIBBPlaneZZero = {{0.0, 0.0, 0.0}, {0.0, 0.0, 1.0}};
const NIBBPlane NIBBPlaneInvalid = {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}};

NIBBVector NIBBVectorMake(CGFloat x, CGFloat y, CGFloat z)
{
    NIBBVector vector;
    vector.x = x,
    vector.y = y;
    vector.z = z;
    return vector;
}

bool NIBBVectorEqualToVector(NIBBVector vector1, NIBBVector vector2)
{
    return vector1.x == vector2.x && vector1.y == vector2.y && vector1.z == vector2.z;
}

bool NIBBVectorIsCoincidentToVector(NIBBVector vector1, NIBBVector vector2)
{
    return NIBBVectorDistance(vector1, vector2) < _NIBBGeometrySmallNumber;
}

bool NIBBVectorIsZero(NIBBVector vector)
{
    return NIBBVectorEqualToVector(vector, NIBBVectorZero);
}

bool NIBBVectorIsUnit(NIBBVector vector)
{
    CGFloat length = NIBBVectorLength(vector);
    return (length > 0.99999999 && length < 1.000001);
}

NIBBVector NIBBVectorAdd(NIBBVector vector1, NIBBVector vector2)
{
    NIBBVector vector;
    vector.x = vector1.x + vector2.x;
    vector.y = vector1.y + vector2.y;
    vector.z = vector1.z + vector2.z;
    return vector;
}

NIBBVector NIBBVectorSubtract(NIBBVector vector1, NIBBVector vector2)
{
    NIBBVector vector;
    vector.x = vector1.x - vector2.x;
    vector.y = vector1.y - vector2.y;
    vector.z = vector1.z - vector2.z;
    return vector;
}

NIBBVector NIBBVectorScalarMultiply(NIBBVector vector, CGFloat scalar)
{
    NIBBVector newVector;
    newVector.x = vector.x * scalar;
    newVector.y = vector.y * scalar;
    newVector.z = vector.z * scalar;
    return newVector;
}

NIBBVector NIBBVectorANormalVector(NIBBVector vector) // returns a vector that is normal to the given vector
{
    NIBBVector normal1;
    NIBBVector normal2;
    NIBBVector normal3;
    CGFloat length1;
    CGFloat length2;
    CGFloat length3;

    normal1 = NIBBVectorMake(-vector.y, vector.x, 0.0);
    normal2 = NIBBVectorMake(-vector.z, 0.0, vector.x);
    normal3 = NIBBVectorMake(0.0, -vector.z, vector.y);

    length1 = NIBBVectorLength(normal1);
    length2 = NIBBVectorLength(normal2);
    length3 = NIBBVectorLength(normal3);

    if (length1 > length2) {
        if (length1 > length3) {
            return NIBBVectorNormalize(normal1);
        } else {
            return NIBBVectorNormalize(normal3);
        }
    } else {
        if (length2 > length3) {
            return NIBBVectorNormalize(normal2);
        } else {
            return NIBBVectorNormalize(normal3);
        }
    }
}

CGFloat NIBBVectorDistance(NIBBVector vector1, NIBBVector vector2)
{
    return NIBBVectorLength(NIBBVectorSubtract(vector1, vector2));
}

CGFloat NIBBVectorDotProduct(NIBBVector vector1, NIBBVector vector2)
{
    return (vector1.x*vector2.x) + (vector1.y*vector2.y) + (vector1.z*vector2.z);

}

NIBBVector NIBBVectorCrossProduct(NIBBVector vector1, NIBBVector vector2)
{
    NIBBVector newVector;
    newVector.x = vector1.y*vector2.z - vector1.z*vector2.y;
    newVector.y = vector1.z*vector2.x - vector1.x*vector2.z;
    newVector.z = vector1.x*vector2.y - vector1.y*vector2.x;
    return newVector;
}

CGFloat NIBBVectorAngleBetweenVectorsAroundVector(NIBBVector vector1, NIBBVector vector2, NIBBVector aroundVector) // returns [0, M_PI*2)
{
    NIBBVector crossProduct;
    CGFloat angle;

    aroundVector = NIBBVectorNormalize(aroundVector);
    vector1 = NIBBVectorNormalize(NIBBVectorSubtract(NIBBVectorProject(vector1, aroundVector), vector1));
    vector2 = NIBBVectorNormalize(NIBBVectorSubtract(NIBBVectorProject(vector2, aroundVector), vector2));

    crossProduct = NIBBVectorCrossProduct(vector1, vector2);

#if CGFLOAT_IS_DOUBLE
    angle = asin(MIN(NIBBVectorLength(crossProduct), 1.0));
#else
    angle = asinf(MIN(NIBBVectorLength(crossProduct), 1.0f));
#endif

    if (NIBBVectorDotProduct(vector1, vector2) < 0.0) {
        angle = M_PI - angle;
    }

    if (NIBBVectorDotProduct(crossProduct, aroundVector) < 0.0) {
        angle = M_PI*2 - angle;
    }

    return angle;
}

CGFloat NIBBVectorLength(NIBBVector vector)
{
#if CGFLOAT_IS_DOUBLE
    return sqrt(NIBBVectorDotProduct(vector, vector));
#else
    return sqrtf(NIBBVectorDotProduct(vector, vector));
#endif
}

NIBBVector NIBBVectorNormalize(NIBBVector vector)
{
    CGFloat length;
    length = NIBBVectorLength(vector);
    if (length == 0.0) {
        return NIBBVectorZero;
    } else {
        return NIBBVectorScalarMultiply(vector, 1.0/length);
    }
}

NIBBVector NIBBVectorProject(NIBBVector vector1, NIBBVector vector2) // project vector1 onto vector2
{
    CGFloat length;
    length = NIBBVectorLength(vector2);
    if (length != 0.0) {
        return NIBBVectorScalarMultiply(vector2, NIBBVectorDotProduct(vector1, vector2) / length);
    } else {
        return NIBBVectorZero;
    }
}

NIBBVector NIBBVectorProjectPerpendicularToVector(NIBBVector perpendicularVector, NIBBVector directionVector)
{
    NIBBVector normalizedPerpendicular = NIBBVectorNormalize(perpendicularVector);
    return NIBBVectorSubtract(directionVector, NIBBVectorScalarMultiply(normalizedPerpendicular, NIBBVectorDotProduct(normalizedPerpendicular, directionVector)));
}

NIBBVector NIBBVectorInvert(NIBBVector vector)
{
    return NIBBVectorSubtract(NIBBVectorZero, vector);
}

NIBBVector NIBBVectorRound(NIBBVector vector)
{
    NIBBVector newVector;
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

NIBBVector NIBBVectorApplyTransform(NIBBVector vector, NIBBAffineTransform transform)
{
    NIBBVector newVector;

    assert(NIBBAffineTransformIsAffine(transform));

    newVector.x = (vector.x*transform.m11)+(vector.y*transform.m21)+(vector.z*transform.m31)+transform.m41;
    newVector.y = (vector.x*transform.m12)+(vector.y*transform.m22)+(vector.z*transform.m32)+transform.m42;
    newVector.z = (vector.x*transform.m13)+(vector.y*transform.m23)+(vector.z*transform.m33)+transform.m43;

    return newVector;
}

NIBBVector NIBBVectorApplyTransformToDirectionalVector(NIBBVector vector, NIBBAffineTransform transform)
{
    NIBBVector newVector;

    assert(NIBBAffineTransformIsAffine(transform));

    newVector.x = (vector.x*transform.m11)+(vector.y*transform.m21)+(vector.z*transform.m31);
    newVector.y = (vector.x*transform.m12)+(vector.y*transform.m22)+(vector.z*transform.m32);
    newVector.z = (vector.x*transform.m13)+(vector.y*transform.m23)+(vector.z*transform.m33);

    return newVector;
}

void NIBBVectorScalarMultiplyVectors(CGFloat scalar, NIBBVectorArray vectors, CFIndex numVectors)
{
#if CGFLOAT_IS_DOUBLE
    vDSP_vsmulD((CGFloat *)vectors, 1, &scalar, (CGFloat *)vectors, 1, numVectors*3);
#else
    vDSP_vsmul((CGFloat *)vectors, 1, &scalar, (CGFloat *)vectors, 1, numVectors*3);
#endif
}

void NIBBVectorCrossProductVectors(NIBBVector vector, NIBBVectorArray vectors, CFIndex numVectors)
{
    CFIndex i;

    for (i = 0; i < numVectors; i++) {
        vectors[i] = NIBBVectorCrossProduct(vector, vectors[i]);
    }
}

void NIBBVectorAddVectors(NIBBVectorArray vectors1, const NIBBVectorArray vectors2, CFIndex numVectors)
{
#if CGFLOAT_IS_DOUBLE
    vDSP_vaddD((CGFloat *)vectors1, 1, (CGFloat *)vectors2, 1, (CGFloat *)vectors1, 1, numVectors*3);
#else
    vDSP_vadd((CGFloat *)vectors1, 1, (CGFloat *)vectors2, 1, (CGFloat *)vectors1, 1, numVectors*3);
#endif
}

void NIBBVectorApplyTransformToVectors(NIBBAffineTransform transform, NIBBVectorArray vectors, CFIndex numVectors)
{
    CGFloat *transformedVectors;
    CGFloat smallTransform[9];

    assert(NIBBAffineTransformIsAffine(transform));

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

void NIBBVectorCrossProductWithVectors(NIBBVectorArray vectors1, const NIBBVectorArray vectors2, CFIndex numVectors)
{
    CFIndex i;

    for (i = 0; i < numVectors; i++) {
        vectors1[i] = NIBBVectorCrossProduct(vectors1[i], vectors2[i]);
    }
}

void NIBBVectorNormalizeVectors(NIBBVectorArray vectors, CFIndex numVectors)
{
    CFIndex i;

    for (i = 0; i < numVectors; i++) {
        vectors[i] = NIBBVectorNormalize(vectors[i]);
    }
}

NSPoint NSPointApplyNIBBAffineTransform(NSPoint point, NIBBAffineTransform transform)
{
    return NSPointFromNIBBVector(NIBBVectorApplyTransform(NIBBVectorMakeFromNSPoint(point), transform));
}

NIBBVector NIBBVectorLerp(NIBBVector vector1, NIBBVector vector2, CGFloat t)
{
    return NIBBVectorAdd(NIBBVectorScalarMultiply(vector1, 1.0 - t), NIBBVectorScalarMultiply(vector2, t));
}

NIBBVector NIBBVectorBend(NIBBVector vectorToBend, NIBBVector originalDirection, NIBBVector newDirection) // this aught to be re-written to be more numerically stable!
{
    NIBBAffineTransform rotateTransform;
    NIBBVector rotationAxis;
    NIBBVector bentVector;
    CGFloat angle;

    rotationAxis = NIBBVectorCrossProduct(NIBBVectorNormalize(originalDirection), NIBBVectorNormalize(newDirection));

#if CGFLOAT_IS_DOUBLE
    angle = asin(MIN(NIBBVectorLength(rotationAxis), 1.0));
#else
    angle = asinf(MIN(NIBBVectorLength(rotationAxis), 1.0f));
#endif

    if (NIBBVectorDotProduct(originalDirection, newDirection) < 0.0) {
        angle = M_PI - angle;
    }

    rotateTransform = NIBBAffineTransformMakeRotationAroundVector(angle, rotationAxis);

    bentVector = NIBBVectorApplyTransform(vectorToBend, rotateTransform);
    return bentVector;
}

bool NIBBVectorIsOnLine(NIBBVector vector, NIBBLine line)
{
    return NIBBVectorDistanceToLine(vector, line) < _NIBBGeometrySmallNumber;
}

bool NIBBVectorIsOnPlane(NIBBVector vector, NIBBPlane plane)
{
    NIBBVector planeNormal;
    planeNormal = NIBBVectorNormalize(plane.normal);
    return ABS(NIBBVectorDotProduct(planeNormal, NIBBVectorSubtract(vector, plane.point))) < _NIBBGeometrySmallNumber;
}

CGFloat NIBBVectorDistanceToLine(NIBBVector vector, NIBBLine line)
{
    NIBBVector translatedPoint;
    assert(NIBBLineIsValid(line));
    translatedPoint = NIBBVectorSubtract(vector, line.point);
    return NIBBVectorLength(NIBBVectorSubtract(translatedPoint, NIBBVectorProject(translatedPoint, line.vector)));
}

CGFloat NIBBVectorDistanceToPlane(NIBBVector vector, NIBBPlane plane)
{
    return ABS(NIBBVectorDotProduct(NIBBVectorSubtract(vector, plane.point), NIBBVectorNormalize(plane.normal)));
}

NIBBLine NIBBLineMake(NIBBVector point, NIBBVector vector)
{
    NIBBLine line;
    line.point = point;
    line.vector = vector;
    assert(NIBBLineIsValid(line));
    return line;
}

NIBBLine NIBBLineMakeFromPoints(NIBBVector point1, NIBBVector point2)
{
    NIBBLine line;
    line.point = point1;
    line.vector = NIBBVectorNormalize(NIBBVectorSubtract(point2, point1));
    assert(NIBBLineIsValid(line));
    return line;
}

bool NIBBLineEqualToLine(NIBBLine line1, NIBBLine line2)
{
    return NIBBVectorEqualToVector(line1.point, line2.point) && NIBBVectorEqualToVector(line1.vector, line2.vector);
}

bool NIBBLineIsCoincidentToLine(NIBBLine line1, NIBBLine line2)
{
    if (NIBBLineIsParallelToLine(line1, line2) == false) {
        return false;
    }
    return NIBBVectorIsOnLine(line1.point, line2);
}

bool NIBBLineIsOnPlane(NIBBLine line, NIBBPlane plane)
{
    if (NIBBVectorIsOnPlane(line.point, plane) == false) {
        return false;
    }
    return ABS(NIBBVectorDotProduct(line.vector, plane.normal)) < _NIBBGeometrySmallNumber;
}

bool NIBBLineIsParallelToLine(NIBBLine line1, NIBBLine line2)
{
    if (NIBBVectorLength(NIBBVectorCrossProduct(line1.vector, line2.vector)) < _NIBBGeometrySmallNumber) {
        return true;
    }
    return false;
}

bool NIBBLineIsValid(NIBBLine line)
{
    return NIBBVectorLength(line.vector) > _NIBBGeometrySmallNumber;
}

bool NIBBLineIntersectsPlane(NIBBLine line, NIBBPlane plane)
{
    if (ABS(NIBBVectorDotProduct(plane.normal, line.vector)) < _NIBBGeometrySmallNumber) {
        if (NIBBVectorIsOnPlane(line.point, plane) == false) {
            return false;
        }
    }
    return true;
}

NIBBVector NIBBLineIntersectionWithPlane(NIBBLine line, NIBBPlane plane)
{
    CGFloat numerator;
    CGFloat denominator;
    NIBBVector planeNormal;
    NIBBVector lineVector;

    planeNormal = NIBBVectorNormalize(plane.normal);
    lineVector = NIBBVectorNormalize(line.vector);

    numerator = NIBBVectorDotProduct(planeNormal, NIBBVectorSubtract(plane.point, line.point));
    denominator = NIBBVectorDotProduct(planeNormal, lineVector);

    if (ABS(denominator) < _NIBBGeometrySmallNumber) {
        if (numerator < 0.0) {
            return NIBBVectorAdd(line.point, NIBBVectorScalarMultiply(lineVector, -(CGFLOAT_MAX/1.0e10)));
        } else if (numerator > 0.0) {
            return NIBBVectorAdd(line.point, NIBBVectorScalarMultiply(lineVector, (CGFLOAT_MAX/1.0e10)));
        } else {
            return line.point;
        }
    }

    return NIBBVectorAdd(line.point, NIBBVectorScalarMultiply(lineVector, numerator/denominator));
}


NIBBVector NIBBLinePointClosestToVector(NIBBLine line, NIBBVector vector)
{
    return NIBBVectorAdd(NIBBVectorProject(NIBBVectorSubtract(vector, line.point), line.vector), line.point);
}

NIBBLine NIBBLineApplyTransform(NIBBLine line, NIBBAffineTransform transform)
{
    NIBBLine newLine;
    newLine.point = NIBBVectorApplyTransform(line.point, transform);
    newLine.vector = NIBBVectorNormalize(NIBBVectorApplyTransformToDirectionalVector(line.vector, transform));
    assert(NIBBLineIsValid(newLine));
    return newLine;
}

CGFloat NIBBLineClosestPoints(NIBBLine line1, NIBBLine line2, NIBBVectorPointer line1PointPtr, NIBBVectorPointer line2PointPtr) // given two lines, find points on each line that are the closest to each other, note that the line that goes through these two points will be normal to both lines
{
    NIBBVector p13, p43, p21, p1, p3, pa, pb;
    CGFloat d1343, d4321, d1321, d4343, d2121;
    CGFloat numerator, denominator;
    CGFloat mua, mub;

    assert(NIBBLineIsValid(line1) && NIBBLineIsValid(line2));

    if (NIBBLineIsParallelToLine(line1, line2)) {
        pa = line1.point;
        pb = NIBBVectorAdd(line2.point, NIBBVectorProject(NIBBVectorSubtract(line2.point, line1.point), line2.vector));
        return NIBBVectorDistance(pa, pb);
    } else {
        p1 = line1.point;
        p3 = line2.point;

        p13 = NIBBVectorSubtract(p1, p3);
        p21 = line1.vector;
        p43 = line2.vector;

        d1343 = NIBBVectorDotProduct(p13, p43);
        d4321 = NIBBVectorDotProduct(p43, p21);
        d1321 = NIBBVectorDotProduct(p13, p21);
        d4343 = NIBBVectorDotProduct(p43, p43);
        d2121 = NIBBVectorDotProduct(p21, p21);

        numerator = d1343*d4321 - d1321*d4343;
        denominator = d2121*d4343 - d4321*d4321;

        if (denominator == 0.0) { // as can happen if the lines were almost parallel
            pa = line1.point;
            pb = NIBBVectorAdd(line2.point, NIBBVectorProject(NIBBVectorSubtract(line2.point, line1.point), line2.vector));
            return NIBBVectorDistance(pa, pb);
        }
        mua = numerator / denominator;
        assert(d4343); // this should never happen, otherwise the line2 would not be valid
        mub = (d1343 + d4321*mua) / d4343;

        pa = NIBBVectorAdd(p1, NIBBVectorScalarMultiply(p21, mua));
        pb = NIBBVectorAdd(p3, NIBBVectorScalarMultiply(p43, mub));
    }

    if (line1PointPtr) {
        *line1PointPtr = pa;
    }
    if (line2PointPtr) {
        *line2PointPtr = pb;
    }

    return NIBBVectorDistance(pa, pb);
}

CFIndex NIBBLineIntersectionWithSphere(NIBBLine line, NIBBVector sphereCenter, CGFloat sphereRadius, NIBBVectorPointer firstIntersection, NIBBVectorPointer secondIntersection) // returns the number of intersection
{
    CGFloat u = NIBBVectorDotProduct(line.vector, NIBBVectorSubtract(line.point, sphereCenter));
    CGFloat v = NIBBVectorDistance(line.point, sphereCenter);

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
        *firstIntersection = NIBBVectorAdd(line.point, NIBBVectorScalarMultiply(line.vector, -u - root));
    }
    if (secondIntersection) {
        *secondIntersection = NIBBVectorAdd(line.point, NIBBVectorScalarMultiply(line.vector, -u + root));
    }

    return discriminant == 0 ? 1 : 2;
}


NIBBPlane NIBBPlaneMake(NIBBVector point, NIBBVector normal)
{
    NIBBPlane plane;
    plane.point = point;
    plane.normal = normal;
    return plane;
}

bool NIBBPlaneEqualToPlane(NIBBPlane plane1, NIBBPlane plane2)
{
    return NIBBVectorEqualToVector(plane1.point, plane2.point) && NIBBVectorEqualToVector(plane1.normal, plane2.normal);
}

bool NIBBPlaneIsCoincidentToPlane(NIBBPlane plane1, NIBBPlane plane2)
{
    if (NIBBVectorLength(NIBBVectorCrossProduct(plane1.normal, plane2.normal)) > _NIBBGeometrySmallNumber) {
        return false;
    }
    return NIBBVectorIsOnPlane(plane1.point, plane2);
}

bool NIBBPlaneIsValid(NIBBPlane plane)
{
    return NIBBVectorLength(plane.normal) > _NIBBGeometrySmallNumber;
}

NIBBPlane NIBBPlaneLeastSquaresPlaneFromPoints(NIBBVectorArray vectors, CFIndex numVectors) // BOGUS TODO not written yet, will give a plane, but it won't be the least squares plane
{
    NIBBPlane plane;

    if (numVectors <= 3) {
        return NIBBPlaneInvalid;
    }

    plane.point = vectors[0];
    plane.normal = NIBBVectorNormalize(NIBBVectorCrossProduct(NIBBVectorSubtract(vectors[1], vectors[0]), NIBBVectorSubtract(vectors[2], vectors[0])));

    if (NIBBVectorIsZero(plane.normal)) {
        return NIBBPlaneInvalid;
    } else {
        return plane;
    }
}


NIBBPlane NIBBPlaneApplyTransform(NIBBPlane plane, NIBBAffineTransform transform)
{
    NIBBPlane newPlane;
    NIBBAffineTransform normalTransform;

    newPlane.point = NIBBVectorApplyTransform(plane.point, transform);
    normalTransform = transform;
    normalTransform.m41 = 0.0; normalTransform.m42 = 0.0; normalTransform.m43 = 0.0;

    newPlane.normal = NIBBVectorNormalize(NIBBVectorApplyTransform(plane.normal, NIBBAffineTransformTranspose(NIBBAffineTransformInvert(normalTransform))));
    assert(NIBBPlaneIsValid(newPlane));
    return newPlane;
}

NIBBVector NIBBPlanePointClosestToVector(NIBBPlane plane, NIBBVector vector)
{
    NIBBVector planeNormal;
    planeNormal = NIBBVectorNormalize(plane.normal);
    return NIBBVectorAdd(vector, NIBBVectorScalarMultiply(planeNormal, NIBBVectorDotProduct(planeNormal, NIBBVectorSubtract(plane.point, vector))));
}

bool NIBBPlaneIsParallelToPlane(NIBBPlane plane1, NIBBPlane plane2)
{
    return NIBBVectorLength(NIBBVectorCrossProduct(plane1.normal, plane2.normal)) <= _NIBBGeometrySmallNumber;
}

bool NIBBPlaneIsBetweenVectors(NIBBPlane plane, NIBBVector vector1, NIBBVector vector2)
{
    return NIBBVectorDotProduct(plane.normal, NIBBVectorSubtract(vector2, plane.point)) < 0.0 != NIBBVectorDotProduct(plane.normal, NIBBVectorSubtract(vector1, plane.point)) < 0.0;
}

NIBBLine NIBBPlaneIntersectionWithPlane(NIBBPlane plane1, NIBBPlane plane2)
{
    NIBBLine line;
    NIBBLine intersectionLine;

    line.vector = NIBBVectorNormalize(NIBBVectorCrossProduct(plane1.normal, plane2.normal));

    if (NIBBVectorIsZero(line.vector)) { // if the planes do not intersect, return halfway-reasonable BS
        line.vector = NIBBVectorNormalize(NIBBVectorCrossProduct(plane1.normal, NIBBVectorMake(1.0, 0.0, 0.0)));
        if (NIBBVectorIsZero(line.vector)) {
            line.vector = NIBBVectorNormalize(NIBBVectorCrossProduct(plane1.normal, NIBBVectorMake(0.0, 1.0, 0.0)));
        }
        line.point = plane1.point;
        return line;
    }

    intersectionLine.point = plane1.point;
    intersectionLine.vector = NIBBVectorNormalize(NIBBVectorSubtract(plane2.normal, NIBBVectorProject(plane2.normal, plane1.normal)));
    line.point = NIBBLineIntersectionWithPlane(intersectionLine, plane2);
    return line;
}


bool NIBBAffineTransformIsRectilinear(NIBBAffineTransform t) // this is not the right term, but what is a transform that only includes scale and translation called?
{
    return (                t.m12 == 0.0 && t.m13 == 0.0 && t.m14 == 0.0 &&
            t.m21 == 0.0 &&                 t.m23 == 0.0 && t.m24 == 0.0 &&
            t.m31 == 0.0 && t.m32 == 0.0 &&                 t.m34 == 0.0 &&
            t.m44 == 1.0);
}

NIBBAffineTransform NIBBAffineTransformTranspose(NIBBAffineTransform t)
{
    NIBBAffineTransform transpose;

    transpose.m11 = t.m11; transpose.m12 = t.m21; transpose.m13 = t.m31; transpose.m14 = t.m41;
    transpose.m21 = t.m12; transpose.m22 = t.m22; transpose.m23 = t.m32; transpose.m24 = t.m42;
    transpose.m31 = t.m13; transpose.m32 = t.m23; transpose.m33 = t.m33; transpose.m34 = t.m43;
    transpose.m41 = t.m14; transpose.m42 = t.m24; transpose.m43 = t.m34; transpose.m44 = t.m44;
    return transpose;
}

CGFloat NIBBAffineTransformDeterminant(NIBBAffineTransform t)
{
    assert(NIBBAffineTransformIsAffine(t));

    return t.m11*t.m22*t.m33 + t.m21*t.m32*t.m13 + t.m31*t.m12*t.m23 - t.m11*t.m32*t.m23 - t.m21*t.m12*t.m33 - t.m31*t.m22*t.m13;
}

NIBBAffineTransform NIBBAffineTransformInvert(NIBBAffineTransform t)
{
    BOOL isAffine;
    NIBBAffineTransform inverse;

    isAffine = NIBBAffineTransformIsAffine(t);
    inverse = CATransform3DInvert(t);

    if (isAffine) { // in some cases CATransform3DInvert returns a matrix that does not have exactly these values even if the input matrix did have these values
        inverse.m14 = 0.0;
        inverse.m24 = 0.0;
        inverse.m34 = 0.0;
        inverse.m44 = 1.0;
    }
    return inverse;
}

NIBBAffineTransform NIBBAffineTransformConcat(NIBBAffineTransform a, NIBBAffineTransform b)
{
    BOOL affine;
    NIBBAffineTransform concat;

    affine = NIBBAffineTransformIsAffine(a) && NIBBAffineTransformIsAffine(b);
    concat = CATransform3DConcat(a, b);

    if (affine) { // in some cases CATransform3DConcat returns a matrix that does not have exactly these values even if the input matrix did have these values
        concat.m14 = 0.0;
        concat.m24 = 0.0;
        concat.m34 = 0.0;
        concat.m44 = 1.0;
    }
    return concat;
}

NSString *NSStringFromNIBBAffineTransform(NIBBAffineTransform transform)
{
    return [NSString stringWithFormat:@"{{%8.2f, %8.2f, %8.2f, %8.2f}\n {%8.2f, %8.2f, %8.2f, %8.2f}\n {%8.2f, %8.2f, %8.2f, %8.2f}\n {%8.2f, %8.2f, %8.2f, %8.2f}}",
            transform.m11, transform.m12, transform.m13, transform.m14, transform.m21, transform.m22, transform.m23, transform.m24,
            transform.m31, transform.m32, transform.m33, transform.m34, transform.m41, transform.m42, transform.m43, transform.m44];
}

NSString *NSStringFromNIBBVector(NIBBVector vector)
{
    return [NSString stringWithFormat:@"{%f, %f, %f}", vector.x, vector.y, vector.z];
}

NSString *NSStringFromNIBBLine(NIBBLine line)
{
    return [NSString stringWithFormat:@"{%@, %@}", NSStringFromNIBBVector(line.point), NSStringFromNIBBVector(line.vector)];
}

NSString *NSStringFromNIBBPlane(NIBBPlane plane)
{
    return [NSString stringWithFormat:@"{%@, %@}", NSStringFromNIBBVector(plane.point), NSStringFromNIBBVector(plane.normal)];
}

NSString *NIBBVectorCArmOrientationString(NIBBVector vector)
{
    NIBBVector normalizedVector = NIBBVectorNormalize(vector);
    NSMutableString *string = [NSMutableString string];

    NIBBVector aoProjectedVector = NIBBVectorNormalize(NIBBVectorProjectPerpendicularToVector(NIBBVectorMake(0, 0, 1), normalizedVector));

#if CGFLOAT_IS_DOUBLE
    CGFloat aoAngle = acos(NIBBVectorDotProduct(aoProjectedVector, NIBBVectorMake(0, -1, 0)));
#else
    CGFloat aoAngle = acosf(NIBBVectorDotProduct(aoProjectedVector, NIBBVectorMake(0, -1, 0)));
#endif
    if (normalizedVector.x > 0) {
        [string appendFormat:@"LAO %.2f, ", aoAngle * (180.0/M_PI)];
    } else {
        [string appendFormat:@"RAO %.2f, ", aoAngle * (180.0/M_PI)];
    }

#if CGFLOAT_IS_DOUBLE
    CGFloat crAngle = acos(NIBBVectorDotProduct(normalizedVector, aoProjectedVector));
#else
    CGFloat crAngle = acosf(NIBBVectorDotProduct(normalizedVector, aoProjectedVector));
#endif
    if (normalizedVector.z > 0) {
        [string appendFormat:@"CR %.2f", crAngle * (180.0/M_PI)];
    } else {
        [string appendFormat:@"CA %.2f", crAngle * (180.0/M_PI)];
    }

    return string;
}

CFDictionaryRef NIBBAffineTransformCreateDictionaryRepresentation(NIBBAffineTransform transform)
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

CFDictionaryRef NIBBVectorCreateDictionaryRepresentation(NIBBVector vector)
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

CFDictionaryRef NIBBLineCreateDictionaryRepresentation(NIBBLine line)
{
    CFDictionaryRef pointDict;
    CFDictionaryRef vectorDict;
    CFDictionaryRef lineDict;

    pointDict = NIBBVectorCreateDictionaryRepresentation(line.point);
    vectorDict = NIBBVectorCreateDictionaryRepresentation(line.vector);
    lineDict = (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:(id)pointDict, @"point", (id)vectorDict, @"vector", nil];
    CFRelease(pointDict);
    CFRelease(vectorDict);
    return lineDict;
}

CFDictionaryRef NIBBPlaneCreateDictionaryRepresentation(NIBBPlane plane)
{
    CFDictionaryRef pointDict;
    CFDictionaryRef normalDict;
    CFDictionaryRef lineDict;

    pointDict = NIBBVectorCreateDictionaryRepresentation(plane.point);
    normalDict = NIBBVectorCreateDictionaryRepresentation(plane.normal);
    lineDict = (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:(id)pointDict, @"point", (id)normalDict, @"normal", nil];
    CFRelease(pointDict);
    CFRelease(normalDict);
    return lineDict;
}

bool NIBBAffineTransformMakeWithDictionaryRepresentation(CFDictionaryRef dict, NIBBAffineTransform *transform)
{
    CFStringRef keys[16];
    CFNumberRef numbers[16];
    CGFloat* tranformPtrs[16];
    NIBBAffineTransform tempTransform;

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

bool NIBBVectorMakeWithDictionaryRepresentation(CFDictionaryRef dict, NIBBVector *vector)
{
    CFNumberRef x;
    CFNumberRef y;
    CFNumberRef z;
    NIBBVector tempVector;

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

bool NIBBLineMakeWithDictionaryRepresentation(CFDictionaryRef dict, NIBBLine *line)
{
    NIBBLine tempLine;
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

    if (NIBBVectorMakeWithDictionaryRepresentation(pointDict, &(tempLine.point)) == false) {
        return false;
    }
    if (NIBBVectorMakeWithDictionaryRepresentation(vectorDict, &(tempLine.vector)) == false) {
        return false;
    }

    if (line) {
        *line = tempLine;
    }
    return true;
}

bool NIBBPlaneMakeWithDictionaryRepresentation(CFDictionaryRef dict, NIBBPlane *plane)
{
    NIBBPlane tempPlane;
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

    if (NIBBVectorMakeWithDictionaryRepresentation(pointDict, &(tempPlane.point)) == false) {
        return false;
    }
    if (NIBBVectorMakeWithDictionaryRepresentation(normalDict, &(tempPlane.normal)) == false) {
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
        theta = acos(R/sqrt(Q3));
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
        theta = acosf(R/sqrtf(Q3));
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

void NIBBAffineTransformGetOpenGLMatrixd(NIBBAffineTransform transform, double *d) // d better be 16 elements long
{
    d[0] =  transform.m11; d[1] =  transform.m12; d[2] =  transform.m13; d[3] =  transform.m14;
    d[4] =  transform.m21; d[5] =  transform.m22; d[6] =  transform.m23; d[7] =  transform.m24;
    d[8] =  transform.m31; d[9] =  transform.m32; d[10] = transform.m33; d[11] = transform.m34;
    d[12] = transform.m41; d[13] = transform.m42; d[14] = transform.m43; d[15] = transform.m44;
}

void NIBBAffineTransformGetOpenGLMatrixf(NIBBAffineTransform transform, float *f) // f better be 16 elements long
{
    f[0] =  transform.m11; f[1] =  transform.m12; f[2] =  transform.m13; f[3] =  transform.m14;
    f[4] =  transform.m21; f[5] =  transform.m22; f[6] =  transform.m23; f[7] =  transform.m24;
    f[8] =  transform.m31; f[9] =  transform.m32; f[10] = transform.m33; f[11] = transform.m34;
    f[12] = transform.m41; f[13] = transform.m42; f[14] = transform.m43; f[15] = transform.m44;
}

NIBBAffineTransform NIBBAffineTransformMakeFromOpenGLMatrixd(double *d) // d better be 16 elements long
{
    NIBBAffineTransform transform;
    transform.m11 = d[0];  transform.m12 = d[1];  transform.m13 = d[2];  transform.m14 = d[3];
    transform.m21 = d[4];  transform.m22 = d[5];  transform.m23 = d[6];  transform.m24 = d[7];
    transform.m31 = d[8];  transform.m32 = d[9];  transform.m33 = d[10]; transform.m34 = d[11];
    transform.m41 = d[12]; transform.m42 = d[13]; transform.m43 = d[14]; transform.m44 = d[15];
    return transform;
}

NIBBAffineTransform NIBBAffineTransformMakeFromOpenGLMatrixf(float *f) // f better be 16 elements long
{
    NIBBAffineTransform transform;
    transform.m11 = f[0];  transform.m12 = f[1];  transform.m13 = f[2];  transform.m14 = f[3];
    transform.m21 = f[4];  transform.m22 = f[5];  transform.m23 = f[6];  transform.m24 = f[7];
    transform.m31 = f[8];  transform.m32 = f[9];  transform.m33 = f[10]; transform.m34 = f[11];
    transform.m41 = f[12]; transform.m42 = f[13]; transform.m43 = f[14]; transform.m44 = f[15];
    return transform;
}

@implementation NSValue (NIBBGeometryAdditions)

+ (NSValue *)valueWithNIBBVector:(NIBBVector)vector
{
    return [NSValue valueWithBytes:&vector objCType:@encode(NIBBVector)];
}

- (NIBBVector)NIBBVectorValue
{
    NIBBVector vector;
    assert(strcmp([self objCType], @encode(NIBBVector)) == 0);
    [self getValue:&vector];
    return vector;
}

+ (NSValue *)valueWithNIBBLine:(NIBBLine)line
{
    return [NSValue valueWithBytes:&line objCType:@encode(NIBBLine)];
}

- (NIBBLine)NIBBLineValue
{
    NIBBLine line;
    assert(strcmp([self objCType], @encode(NIBBLine)) == 0);
    [self getValue:&line];
    return line;
}

+ (NSValue *)valueWithNIBBPlane:(NIBBPlane)plane
{
    return [NSValue valueWithBytes:&plane objCType:@encode(NIBBPlane)];

}

- (NIBBPlane)NIBBPlaneValue
{
    NIBBPlane plane;
    assert(strcmp([self objCType], @encode(NIBBPlane)) == 0);
    [self getValue:&plane];
    return plane;
}

+ (NSValue *)valueWithNIBBAffineTransform:(NIBBAffineTransform)transform
{
    return [NSValue valueWithBytes:&transform objCType:@encode(NIBBAffineTransform)];
}

- (NIBBAffineTransform)NIBBAffineTransformValue
{
    NIBBAffineTransform transform;
    assert(strcmp([self objCType], @encode(NIBBAffineTransform)) == 0);
    [self getValue:&transform];
    return transform;
}

@end

@implementation NSCoder (NIBBGeometryAdditions)

- (void)encodeNIBBAffineTransform:(NIBBAffineTransform)transform forKey:(NSString *)key
{
    NSDictionary *dict = (NSDictionary *)NIBBAffineTransformCreateDictionaryRepresentation(transform);
    [self encodeObject:dict forKey:key];
    [dict release];
}

- (void)encodeNIBBVector:(NIBBVector)vector forKey:(NSString *)key
{
    NSDictionary *dict = (NSDictionary *)NIBBVectorCreateDictionaryRepresentation(vector);
    [self encodeObject:dict forKey:key];
    [dict release];
}

- (void)encodeNIBBLine:(NIBBLine)line forKey:(NSString *)key
{
    NSDictionary *dict = (NSDictionary *)NIBBLineCreateDictionaryRepresentation(line);
    [self encodeObject:dict forKey:key];
    [dict release];
}

- (void)encodeNIBBPlane:(NIBBPlane)plane forKey:(NSString *)key
{
    NSDictionary *dict = (NSDictionary *)NIBBPlaneCreateDictionaryRepresentation(plane);
    [self encodeObject:dict forKey:key];
    [dict release];
}

- (NIBBAffineTransform)decodeNIBBAffineTransformForKey:(NSString *)key
{
    NIBBAffineTransform transform = NIBBAffineTransformIdentity;
    NSDictionary *dict = [self decodeObjectOfClass:[NSDictionary class] forKey:key];
    if (dict == nil) {
        [NSException raise:@"OSIDecode" format:@"No Dictionary when decoding NIBBAffineTranform"];
    }

    if (NIBBAffineTransformMakeWithDictionaryRepresentation((CFDictionaryRef)dict, &transform) == NO) {
        [NSException raise:@"OSIDecode" format:@"Dictionary did not contain an NIBBAffineTranform"];
    }
    return transform;
}

- (NIBBVector)decodeNIBBVectorForKey:(NSString *)key
{
    NIBBVector vector = NIBBVectorZero;
    NSDictionary *dict = [self decodeObjectOfClass:[NSDictionary class] forKey:key];
    if (dict == nil) {
        [NSException raise:@"OSIDecode" format:@"No Dictionary when decoding NIBBVector"];
    }

    if (NIBBVectorMakeWithDictionaryRepresentation((CFDictionaryRef)dict, &vector) == NO) {
        [NSException raise:@"OSIDecode" format:@"Dictionary did not contain an NIBBVector"];
    }
    return vector;
}

- (NIBBLine)decodeNIBBLineForKey:(NSString *)key
{
    NIBBLine line = NIBBLineInvalid;
    NSDictionary *dict = [self decodeObjectOfClass:[NSDictionary class] forKey:key];
    if (dict == nil) {
        [NSException raise:@"OSIDecode" format:@"No Dictionary when decoding NIBBLine"];
    }
    
    if (NIBBLineMakeWithDictionaryRepresentation((CFDictionaryRef)dict, &line) == NO) {
        [NSException raise:@"OSIDecode" format:@"Dictionary did not contain an NIBBLine"];
    }
    return line;
}


- (NIBBPlane)decodeNIBBPlaneForKey:(NSString *)key
{
    NIBBPlane plane = NIBBPlaneInvalid;
    NSDictionary *dict = [self decodeObjectOfClass:[NSDictionary class] forKey:key];
    if (dict == nil) {
        [NSException raise:@"OSIDecode" format:@"No Dictionary when decoding NIBBPlane"];
    }
    
    if (NIBBPlaneMakeWithDictionaryRepresentation((CFDictionaryRef)dict, &plane) == NO) {
        [NSException raise:@"OSIDecode" format:@"Dictionary did not contain an NIBBPlane"];
    }
    return plane;
}


@end










