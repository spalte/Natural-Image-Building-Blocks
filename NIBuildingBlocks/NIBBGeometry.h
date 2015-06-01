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

#ifndef _NIBBGEOMETRY_H_
#define _NIBBGEOMETRY_H_

#include <QuartzCore/CATransform3D.h>

#ifdef __OBJC__
#import <Foundation/Foundation.h>
@class NSString;
#endif

CF_EXTERN_C_BEGIN

struct NIBBVector {
    CGFloat x;
    CGFloat y;
    CGFloat z;
};
typedef struct NIBBVector NIBBVector;

// A NIBBLine is an infinite line throught space
struct NIBBLine {
    NIBBVector point; // the line goes through this point
    NIBBVector vector; // this is the direction of the line, the line is not valid if this is NIBBVectorZero, try to keep this of unit length... I wish I would have called this direction...
};
typedef struct NIBBLine NIBBLine;

extern const NIBBLine NIBBLineXAxis;
extern const NIBBLine NIBBLineYAxis;
extern const NIBBLine NIBBLineZAxis;
extern const NIBBLine NIBBLineInvalid;

struct NIBBPlane {
    NIBBVector point;
    NIBBVector normal;
};
typedef struct NIBBPlane NIBBPlane;

extern const NIBBPlane NIBBPlaneXZero;
extern const NIBBPlane NIBBPlaneYZero;
extern const NIBBPlane NIBBPlaneZZero;
extern const NIBBPlane NIBBPlaneInvalid;

typedef NIBBVector *NIBBVectorPointer;
typedef NIBBVector *NIBBVectorArray;

typedef NIBBLine *NIBBLinePointer;
typedef NIBBLine *NIBBLineArray;

typedef NIBBPlane *NIBBPlanePointer;
typedef NIBBPlane *NIBBPlaneArray;

typedef CATransform3D NIBBAffineTransform;

typedef NIBBAffineTransform *NIBBAffineTransformPointer;
typedef NIBBAffineTransform *NIBBAffineTransformArray;

extern const NIBBVector NIBBVectorZero;

extern const NIBBVector NIBBVectorXBasis;
extern const NIBBVector NIBBVectorYBasis;
extern const NIBBVector NIBBVectorZBasis;

NIBBVector NIBBVectorMake(CGFloat x, CGFloat y, CGFloat z);

bool NIBBVectorEqualToVector(NIBBVector vector1, NIBBVector vector2);
bool NIBBVectorIsCoincidentToVector(NIBBVector vector1, NIBBVector vector2); // coincident to an arbitratry tolerance
bool NIBBVectorIsZero(NIBBVector vector);
bool NIBBVectorIsUnit(NIBBVector vector);

NIBBVector NIBBVectorAdd(NIBBVector vector1, NIBBVector vector2);
NIBBVector NIBBVectorSubtract(NIBBVector vector1, NIBBVector vector2);
NIBBVector NIBBVectorScalarMultiply(NIBBVector vector1, CGFloat scalar);

NIBBVector NIBBVectorANormalVector(NIBBVector vector); // returns a vector that is normal to the given vector

CGFloat NIBBVectorDistance(NIBBVector vector1, NIBBVector vector2);

CGFloat NIBBVectorDotProduct(NIBBVector vector1, NIBBVector vector2);
NIBBVector NIBBVectorCrossProduct(NIBBVector vector1, NIBBVector vector2);
NIBBVector NIBBVectorLerp(NIBBVector vector1, NIBBVector vector2, CGFloat t); // when t == 0.0 the result is vector 1, when t == 1.0 the result is vector2
CGFloat NIBBVectorAngleBetweenVectorsAroundVector(NIBBVector vector1, NIBBVector vector2, NIBBVector aroundVector); // returns [0, 2*M_PI)

CGFloat NIBBVectorLength(NIBBVector vector);
NIBBVector NIBBVectorNormalize(NIBBVector vector);
NIBBVector NIBBVectorProject(NIBBVector vector1, NIBBVector vector2); // project vector1 onto vector2
NIBBVector NIBBVectorProjectPerpendicularToVector(NIBBVector perpendicularVector, NIBBVector directionVector);

NIBBVector NIBBVectorRound(NIBBVector vector);
NIBBVector NIBBVectorInvert(NIBBVector vector);
NIBBVector NIBBVectorApplyTransform(NIBBVector vector, NIBBAffineTransform transform);
NIBBVector NIBBVectorApplyTransformToDirectionalVector(NIBBVector vector, NIBBAffineTransform transform); // this will not apply the translation to the vector, this is to be used when the vector does not coorespond to a point in space, but instead to a direction

NIBBVector NIBBVectorBend(NIBBVector vectorToBend, NIBBVector originalDirection, NIBBVector newDirection); // applies the rotation that would be needed to turn originalDirection into newDirection, to vectorToBend
bool NIBBVectorIsOnLine(NIBBVector vector, NIBBLine line);
bool NIBBVectorIsOnPlane(NIBBVector vector, NIBBPlane plane);
CGFloat NIBBVectorDistanceToLine(NIBBVector vector, NIBBLine line);
CGFloat NIBBVectorDistanceToPlane(NIBBVector vector, NIBBPlane plane);

NIBBLine NIBBLineMake(NIBBVector point, NIBBVector vector);
NIBBLine NIBBLineMakeFromPoints(NIBBVector point1, NIBBVector point2);
bool NIBBLineEqualToLine(NIBBLine line1, NIBBLine line2);
bool NIBBLineIsCoincidentToLine(NIBBLine line2, NIBBLine line1); // do the two lines represent the same line in space, to a small amount of round-off slop
bool NIBBLineIsOnPlane(NIBBLine line, NIBBPlane plane);
bool NIBBLineIsParallelToLine(NIBBLine line1, NIBBLine line2);
bool NIBBLineIsValid(NIBBLine line);
bool NIBBLineIntersectsPlane(NIBBLine line, NIBBPlane plane);
NIBBVector NIBBLineIntersectionWithPlane(NIBBLine line, NIBBPlane plane);
NIBBVector NIBBLinePointClosestToVector(NIBBLine line, NIBBVector vector);
NIBBLine NIBBLineApplyTransform(NIBBLine line, NIBBAffineTransform transform);
CGFloat NIBBLineClosestPoints(NIBBLine line1, NIBBLine line2, NIBBVectorPointer line1PointPtr, NIBBVectorPointer line2PointPtr); // given two lines, find points on each line that are the closest to each other. Returns the distance between these two points. Note that the line that goes through these two points will be normal to both lines
CFIndex NIBBLineIntersectionWithSphere(NIBBLine line, NIBBVector sphereCenter, CGFloat sphereRadius, NIBBVectorPointer firstIntersection, NIBBVectorPointer secondIntersection); // returns the number of intersection

NIBBPlane NIBBPlaneMake(NIBBVector point, NIBBVector normal);
bool NIBBPlaneEqualToPlane(NIBBPlane plane1, NIBBPlane plane2);
bool NIBBPlaneIsCoincidentToPlane(NIBBPlane plane1, NIBBPlane plane2);
bool NIBBPlaneIsValid(NIBBPlane plane);
NIBBVector NIBBPlanePointClosestToVector(NIBBPlane plane, NIBBVector vector);
bool NIBBPlaneIsParallelToPlane(NIBBPlane plane1, NIBBPlane plane2);
bool NIBBPlaneIsBetweenVectors(NIBBPlane plane, NIBBVector vector1, NIBBVector vector2);
NIBBLine NIBBPlaneIntersectionWithPlane(NIBBPlane plane1, NIBBPlane plane2);
NIBBPlane NIBBPlaneLeastSquaresPlaneFromPoints(NIBBVectorArray vectors, CFIndex numVectors); // BOGUS TODO not written yet, will give a plane, but it won't be the least squares plane
NIBBPlane NIBBPlaneApplyTransform(NIBBPlane plane, NIBBAffineTransform transform);

void NIBBVectorScalarMultiplyVectors(CGFloat scalar, NIBBVectorArray vectors, CFIndex numVectors);
void NIBBVectorCrossProductVectors(NIBBVector vector, NIBBVectorArray vectors, CFIndex numVectors);
void NIBBVectorAddVectors(NIBBVectorArray vectors1, const NIBBVectorArray vectors2, CFIndex numVectors);
void NIBBVectorApplyTransformToVectors(NIBBAffineTransform transform, NIBBVectorArray vectors, CFIndex numVectors);
void NIBBVectorCrossProductWithVectors(NIBBVectorArray vectors1, const NIBBVectorArray vectors2, CFIndex numVectors);
void NIBBVectorNormalizeVectors(NIBBVectorArray vectors, CFIndex numVectors);

CG_INLINE NSPoint NSPointFromNIBBVector(NIBBVector vector) {return NSMakePoint(vector.x, vector.y);}
CG_INLINE NIBBVector NIBBVectorMakeFromNSPoint(NSPoint point) {return NIBBVectorMake(point.x, point.y, 0);}

NSPoint NSPointApplyNIBBAffineTransform(NSPoint point, NIBBAffineTransform transform);
NSRect NSRectApplyNIBBAffineTransformBounds(NSRect rect, NIBBAffineTransform);

extern const NIBBAffineTransform NIBBAffineTransformIdentity;

bool NIBBAffineTransformIsRectilinear(NIBBAffineTransform t); // this is not the right term, but what is a transform that only includes scale and translation called?
NIBBAffineTransform NIBBAffineTransformTranspose(NIBBAffineTransform t);
CGFloat NIBBAffineTransformDeterminant(NIBBAffineTransform t);
NIBBAffineTransform NIBBAffineTransformInvert (NIBBAffineTransform t);
NIBBAffineTransform NIBBAffineTransformConcat (NIBBAffineTransform a, NIBBAffineTransform b);

CG_INLINE bool NIBBAffineTransformIsIdentity(NIBBAffineTransform t) {return CATransform3DIsIdentity(t);}
CG_INLINE bool NIBBAffineTransformIsAffine(NIBBAffineTransform t) {return (t.m14 == 0.0 && t.m24 == 0.0 && t.m34 == 0.0 && t.m44 == 1.0);}
CG_INLINE bool NIBBAffineTransformEqualToTransform(NIBBAffineTransform a, NIBBAffineTransform b) {return CATransform3DEqualToTransform(a, b);}
CG_INLINE NIBBAffineTransform NIBBAffineTransformMakeTranslation(CGFloat tx, CGFloat ty, CGFloat tz) {return CATransform3DMakeTranslation(tx, ty, tz);}
CG_INLINE NIBBAffineTransform NIBBAffineTransformMakeTranslationWithVector(NIBBVector vector) {return CATransform3DMakeTranslation(vector.x, vector.y, vector.z);}
CG_INLINE NIBBAffineTransform NIBBAffineTransformMakeScale(CGFloat sx, CGFloat sy, CGFloat sz) {return CATransform3DMakeScale(sx, sy, sz);}
CG_INLINE NIBBAffineTransform NIBBAffineTransformMakeRotation(CGFloat angle, CGFloat x, CGFloat y, CGFloat z) {return CATransform3DMakeRotation(angle, x, y, z);}
CG_INLINE NIBBAffineTransform NIBBAffineTransformMakeRotationAroundVector(CGFloat angle, NIBBVector vector) {return CATransform3DMakeRotation(angle, vector.x, vector.y, vector.z);}
CG_INLINE NIBBAffineTransform NIBBAffineTransformTranslate(NIBBAffineTransform t, CGFloat tx, CGFloat ty, CGFloat tz) {return CATransform3DTranslate(t, tx, ty, tz);}
CG_INLINE NIBBAffineTransform NIBBAffineTransformTranslateWithVector(NIBBAffineTransform t, NIBBVector vector) {return CATransform3DTranslate(t, vector.x, vector.y, vector.z);}
CG_INLINE NIBBAffineTransform NIBBAffineTransformScale(NIBBAffineTransform t, CGFloat sx, CGFloat sy, CGFloat sz) {return CATransform3DScale(t, sx, sy, sz);}
CG_INLINE NIBBAffineTransform NIBBAffineTransformRotate(NIBBAffineTransform t, CGFloat angle, CGFloat x, CGFloat y, CGFloat z) {return CATransform3DRotate(t, angle, x, y, z);}
CG_INLINE NIBBAffineTransform NIBBAffineTransformRotateAroundVector(NIBBAffineTransform t, CGFloat angle, NIBBVector vector) {return CATransform3DRotate(t, angle, vector.x, vector.y, vector.z);}

CFDictionaryRef NIBBAffineTransformCreateDictionaryRepresentation(NIBBAffineTransform transform);
CFDictionaryRef NIBBVectorCreateDictionaryRepresentation(NIBBVector vector);
CFDictionaryRef NIBBLineCreateDictionaryRepresentation(NIBBLine line);
CFDictionaryRef NIBBPlaneCreateDictionaryRepresentation(NIBBPlane plane);

bool NIBBAffineTransformMakeWithDictionaryRepresentation(CFDictionaryRef dict, NIBBAffineTransform *transform);
bool NIBBVectorMakeWithDictionaryRepresentation(CFDictionaryRef dict, NIBBVector *vector);
bool NIBBLineMakeWithDictionaryRepresentation(CFDictionaryRef dict, NIBBLine *line);
bool NIBBPlaneMakeWithDictionaryRepresentation(CFDictionaryRef dict, NIBBPlane *plane);

// gets openGL matrix values out of a NIBBAffineTransform
void NIBBAffineTransformGetOpenGLMatrixd(NIBBAffineTransform transform, double *d); // d better be 16 elements long
void NIBBAffineTransformGetOpenGLMatrixf(NIBBAffineTransform transform, float *f); // f better be 16 elements long

NIBBAffineTransform NIBBAffineTransformMakeFromOpenGLMatrixd(double *d); // d better be 16 elements long
NIBBAffineTransform NIBBAffineTransformMakeFromOpenGLMatrixf(float *f); // f better be 16 elements long

// returns the real numbered roots of ax+b
CFIndex findRealLinearRoot(CGFloat a, CGFloat b, CGFloat *root); // returns the number of roots set
// returns the real numbered roots of ax^2+bx+c
CFIndex findRealQuadraticRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat *root1, CGFloat *root2); // returns the number of roots set
// returns the real numbered roots of ax^3+bx^2+cx+d
CFIndex findRealCubicRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat d, CGFloat *root1, CGFloat *root2, CGFloat *root3); // returns the number of roots set

CF_EXTERN_C_END


#ifdef __OBJC__

NSString *NSStringFromNIBBAffineTransform(NIBBAffineTransform transform);
NSString *NSStringFromNIBBVector(NIBBVector vector);
NSString *NSStringFromNIBBLine(NIBBLine line);
NSString *NSStringFromNIBBPlane(NIBBPlane plane);
NSString *NIBBVectorCArmOrientationString(NIBBVector vector);

/** NSValue support. **/

@interface NSValue (NIBBGeometryAdditions)

+ (NSValue *)valueWithNIBBVector:(NIBBVector)vector;
- (NIBBVector)NIBBVectorValue;

+ (NSValue *)valueWithNIBBLine:(NIBBLine)line;
- (NIBBLine)NIBBLineValue;

+ (NSValue *)valueWithNIBBPlane:(NIBBPlane)plane;
- (NIBBPlane)NIBBPlaneValue;

+ (NSValue *)valueWithNIBBAffineTransform:(NIBBAffineTransform)transform;
- (NIBBAffineTransform)NIBBAffineTransformValue;

@end

/** NSCoder support. **/

@interface NSCoder (NIBBGeometryAdditions)

- (void)encodeNIBBAffineTransform:(NIBBAffineTransform)transform forKey:(NSString *)key;
- (void)encodeNIBBVector:(NIBBVector)vector forKey:(NSString *)key;
- (void)encodeNIBBLine:(NIBBLine)line forKey:(NSString *)key;
- (void)encodeNIBBPlane:(NIBBPlane)plane forKey:(NSString *)key;

- (NIBBAffineTransform)decodeNIBBAffineTransformForKey:(NSString *)key;
- (NIBBVector)decodeNIBBVectorForKey:(NSString *)key;
- (NIBBLine)decodeNIBBLineForKey:(NSString *)key;
- (NIBBPlane)decodeNIBBPlaneForKey:(NSString *)key;

@end


#endif /* __OBJC__ */

#endif	/* _NIBBGEOMETRY_H_ */



