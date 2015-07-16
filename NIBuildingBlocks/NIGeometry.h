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

#ifndef _NIGEOMETRY_H_
#define _NIGEOMETRY_H_

#include <QuartzCore/CATransform3D.h>

#ifdef __OBJC__
#import <Foundation/Foundation.h>
@class NSString;
#endif

CF_EXTERN_C_BEGIN

struct NIVector {
    CGFloat x;
    CGFloat y;
    CGFloat z;
};
typedef struct NIVector NIVector;

// A NILine is an infinite line throught space
struct NILine {
    NIVector point; // the line goes through this point
    NIVector vector; // this is the direction of the line, the line is not valid if this is NIVectorZero, try to keep this of unit length... I wish I would have called this direction...
};
typedef struct NILine NILine;

extern const NILine NILineXAxis;
extern const NILine NILineYAxis;
extern const NILine NILineZAxis;
extern const NILine NILineInvalid;

struct NIPlane {
    NIVector point;
    NIVector normal;
};
typedef struct NIPlane NIPlane;

extern const NIPlane NIPlaneXZero;
extern const NIPlane NIPlaneYZero;
extern const NIPlane NIPlaneZZero;
extern const NIPlane NIPlaneInvalid;

typedef NIVector *NIVectorPointer;
typedef NIVector *NIVectorArray;

typedef NILine *NILinePointer;
typedef NILine *NILineArray;

typedef NIPlane *NIPlanePointer;
typedef NIPlane *NIPlaneArray;

typedef CATransform3D NIAffineTransform;

typedef NIAffineTransform *NIAffineTransformPointer;
typedef NIAffineTransform *NIAffineTransformArray;

extern const NIVector NIVectorZero;

extern const NIVector NIVectorXBasis;
extern const NIVector NIVectorYBasis;
extern const NIVector NIVectorZBasis;

NIVector NIVectorMake(CGFloat x, CGFloat y, CGFloat z);

bool NIVectorEqualToVector(NIVector vector1, NIVector vector2);
bool NIVectorIsCoincidentToVector(NIVector vector1, NIVector vector2); // coincident to an arbitratry tolerance
bool NIVectorIsZero(NIVector vector);
bool NIVectorIsUnit(NIVector vector);

NIVector NIVectorAdd(NIVector vector1, NIVector vector2);
NIVector NIVectorSubtract(NIVector vector1, NIVector vector2);
NIVector NIVectorScalarMultiply(NIVector vector1, CGFloat scalar);
NIVector NIVectorZeroZ(NIVector vector);

NIVector NIVectorANormalVector(NIVector vector); // returns a vector that is normal to the given vector

CGFloat NIVectorDistance(NIVector vector1, NIVector vector2);

CGFloat NIVectorDotProduct(NIVector vector1, NIVector vector2);
NIVector NIVectorCrossProduct(NIVector vector1, NIVector vector2);
NIVector NIVectorLerp(NIVector vector1, NIVector vector2, CGFloat t); // when t == 0.0 the result is vector 1, when t == 1.0 the result is vector2
CGFloat NIVectorAngleBetweenVectorsAroundVector(NIVector vector1, NIVector vector2, NIVector aroundVector); // returns [0, 2*M_PI)

CGFloat NIVectorLength(NIVector vector);
NIVector NIVectorNormalize(NIVector vector);
NIVector NIVectorProject(NIVector vector1, NIVector vector2); // project vector1 onto vector2
NIVector NIVectorProjectPerpendicularToVector(NIVector perpendicularVector, NIVector directionVector);

NIVector NIVectorRound(NIVector vector);
NIVector NIVectorInvert(NIVector vector);
NIVector NIVectorApplyTransform(NIVector vector, NIAffineTransform transform);
NIVector NIVectorApplyTransformToDirectionalVector(NIVector vector, NIAffineTransform transform); // this will not apply the translation to the vector, this is to be used when the vector does not coorespond to a point in space, but instead to a direction

NIVector NIVectorBend(NIVector vectorToBend, NIVector originalDirection, NIVector newDirection); // applies the rotation that would be needed to turn originalDirection into newDirection, to vectorToBend
bool NIVectorIsOnLine(NIVector vector, NILine line);
bool NIVectorIsOnPlane(NIVector vector, NIPlane plane);
CGFloat NIVectorDistanceToLine(NIVector vector, NILine line);
CGFloat NIVectorDistanceToPlane(NIVector vector, NIPlane plane);

NILine NILineMake(NIVector point, NIVector vector);
NILine NILineMakeFromPoints(NIVector point1, NIVector point2);
bool NILineEqualToLine(NILine line1, NILine line2);
bool NILineIsCoincidentToLine(NILine line2, NILine line1); // do the two lines represent the same line in space, to a small amount of round-off slop
bool NILineIsOnPlane(NILine line, NIPlane plane);
bool NILineIsParallelToLine(NILine line1, NILine line2);
bool NILineIsValid(NILine line);
bool NILineIntersectsPlane(NILine line, NIPlane plane);
NIVector NILineIntersectionWithPlane(NILine line, NIPlane plane);
NIVector NILinePointClosestToVector(NILine line, NIVector vector);
NILine NILineApplyTransform(NILine line, NIAffineTransform transform);
CGFloat NILineClosestPoints(NILine line1, NILine line2, NIVectorPointer line1PointPtr, NIVectorPointer line2PointPtr); // given two lines, find points on each line that are the closest to each other. Returns the distance between these two points. Note that the line that goes through these two points will be normal to both lines
CFIndex NILineIntersectionWithSphere(NILine line, NIVector sphereCenter, CGFloat sphereRadius, NIVectorPointer firstIntersection, NIVectorPointer secondIntersection); // returns the number of intersection

NIPlane NIPlaneMake(NIVector point, NIVector normal);
bool NIPlaneEqualToPlane(NIPlane plane1, NIPlane plane2);
bool NIPlaneIsCoincidentToPlane(NIPlane plane1, NIPlane plane2);
bool NIPlaneIsValid(NIPlane plane);
NIVector NIPlanePointClosestToVector(NIPlane plane, NIVector vector);
bool NIPlaneIsParallelToPlane(NIPlane plane1, NIPlane plane2);
bool NIPlaneIsBetweenVectors(NIPlane plane, NIVector vector1, NIVector vector2);
NILine NIPlaneIntersectionWithPlane(NIPlane plane1, NIPlane plane2);
NIPlane NIPlaneLeastSquaresPlaneFromPoints(NIVectorArray vectors, CFIndex numVectors); // BOGUS TODO not written yet, will give a plane, but it won't be the least squares plane
NIPlane NIPlaneApplyTransform(NIPlane plane, NIAffineTransform transform);

void NIVectorScalarMultiplyVectors(CGFloat scalar, NIVectorArray vectors, CFIndex numVectors);
void NIVectorCrossProductVectors(NIVector vector, NIVectorArray vectors, CFIndex numVectors);
void NIVectorAddVectors(NIVectorArray vectors1, const NIVectorArray vectors2, CFIndex numVectors);
void NIVectorApplyTransformToVectors(NIAffineTransform transform, NIVectorArray vectors, CFIndex numVectors);
void NIVectorCrossProductWithVectors(NIVectorArray vectors1, const NIVectorArray vectors2, CFIndex numVectors);
void NIVectorNormalizeVectors(NIVectorArray vectors, CFIndex numVectors);

CG_INLINE NSPoint NSPointFromNIVector(NIVector vector) {return NSMakePoint(vector.x, vector.y);}
CG_INLINE NIVector NIVectorMakeFromNSPoint(NSPoint point) {return NIVectorMake(point.x, point.y, 0);}

NSPoint NSPointApplyNIAffineTransform(NSPoint point, NIAffineTransform transform);
NSRect NSRectApplyNIAffineTransformBounds(NSRect rect, NIAffineTransform);

extern const NIAffineTransform NIAffineTransformIdentity;

bool NIAffineTransformIsRectilinear(NIAffineTransform t); // this is not the right term, but what is a transform that only includes scale and translation called?
NIAffineTransform NIAffineTransformTranspose(NIAffineTransform t);
CGFloat NIAffineTransformDeterminant(NIAffineTransform t);
NIAffineTransform NIAffineTransformInvert (NIAffineTransform t);
NIAffineTransform NIAffineTransformConcat (NIAffineTransform a, NIAffineTransform b);

CG_INLINE bool NIAffineTransformIsIdentity(NIAffineTransform t) {return CATransform3DIsIdentity(t);}
CG_INLINE bool NIAffineTransformIsAffine(NIAffineTransform t) {return (t.m14 == 0.0 && t.m24 == 0.0 && t.m34 == 0.0 && t.m44 == 1.0);}
CG_INLINE bool NIAffineTransformEqualToTransform(NIAffineTransform a, NIAffineTransform b) {return CATransform3DEqualToTransform(a, b);}
CG_INLINE NIAffineTransform NIAffineTransformMakeTranslation(CGFloat tx, CGFloat ty, CGFloat tz) {return CATransform3DMakeTranslation(tx, ty, tz);}
CG_INLINE NIAffineTransform NIAffineTransformMakeTranslationWithVector(NIVector vector) {return CATransform3DMakeTranslation(vector.x, vector.y, vector.z);}
CG_INLINE NIAffineTransform NIAffineTransformMakeScale(CGFloat sx, CGFloat sy, CGFloat sz) {return CATransform3DMakeScale(sx, sy, sz);}
CG_INLINE NIAffineTransform NIAffineTransformMakeRotation(CGFloat angle, CGFloat x, CGFloat y, CGFloat z) {return CATransform3DMakeRotation(angle, x, y, z);}
CG_INLINE NIAffineTransform NIAffineTransformMakeRotationAroundVector(CGFloat angle, NIVector vector) {return CATransform3DMakeRotation(angle, vector.x, vector.y, vector.z);}
CG_INLINE NIAffineTransform NIAffineTransformTranslate(NIAffineTransform t, CGFloat tx, CGFloat ty, CGFloat tz) {return CATransform3DTranslate(t, tx, ty, tz);}
CG_INLINE NIAffineTransform NIAffineTransformTranslateWithVector(NIAffineTransform t, NIVector vector) {return CATransform3DTranslate(t, vector.x, vector.y, vector.z);}
CG_INLINE NIAffineTransform NIAffineTransformScale(NIAffineTransform t, CGFloat sx, CGFloat sy, CGFloat sz) {return CATransform3DScale(t, sx, sy, sz);}
CG_INLINE NIAffineTransform NIAffineTransformRotate(NIAffineTransform t, CGFloat angle, CGFloat x, CGFloat y, CGFloat z) {return CATransform3DRotate(t, angle, x, y, z);}
CG_INLINE NIAffineTransform NIAffineTransformRotateAroundVector(NIAffineTransform t, CGFloat angle, NIVector vector) {return CATransform3DRotate(t, angle, vector.x, vector.y, vector.z);}

CFDictionaryRef NIAffineTransformCreateDictionaryRepresentation(NIAffineTransform transform);
CFDictionaryRef NIVectorCreateDictionaryRepresentation(NIVector vector);
CFDictionaryRef NILineCreateDictionaryRepresentation(NILine line);
CFDictionaryRef NIPlaneCreateDictionaryRepresentation(NIPlane plane);

bool NIAffineTransformMakeWithDictionaryRepresentation(CFDictionaryRef dict, NIAffineTransform *transform);
bool NIVectorMakeWithDictionaryRepresentation(CFDictionaryRef dict, NIVector *vector);
bool NILineMakeWithDictionaryRepresentation(CFDictionaryRef dict, NILine *line);
bool NIPlaneMakeWithDictionaryRepresentation(CFDictionaryRef dict, NIPlane *plane);

// gets openGL matrix values out of a NIAffineTransform
void NIAffineTransformGetOpenGLMatrixd(NIAffineTransform transform, double *d); // d better be 16 elements long
void NIAffineTransformGetOpenGLMatrixf(NIAffineTransform transform, float *f); // f better be 16 elements long

NIAffineTransform NIAffineTransformMakeFromOpenGLMatrixd(double *d); // d better be 16 elements long
NIAffineTransform NIAffineTransformMakeFromOpenGLMatrixf(float *f); // f better be 16 elements long

// returns the real numbered roots of ax+b
CFIndex findRealLinearRoot(CGFloat a, CGFloat b, CGFloat *root); // returns the number of roots set
// returns the real numbered roots of ax^2+bx+c
CFIndex findRealQuadraticRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat *root1, CGFloat *root2); // returns the number of roots set
// returns the real numbered roots of ax^3+bx^2+cx+d
CFIndex findRealCubicRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat d, CGFloat *root1, CGFloat *root2, CGFloat *root3); // returns the number of roots set

CF_EXTERN_C_END


#ifdef __OBJC__

NSString *NSStringFromNIAffineTransform(NIAffineTransform transform);
NSString *NSStringFromNIVector(NIVector vector);
NSString *NSStringFromNILine(NILine line);
NSString *NSStringFromNIPlane(NIPlane plane);
NSString *NIVectorCArmOrientationString(NIVector vector);

/** NSValue support. **/

@interface NSValue (NIGeometryAdditions)

+ (NSValue *)valueWithNIVector:(NIVector)vector;
- (NIVector)NIVectorValue;

+ (NSValue *)valueWithNILine:(NILine)line;
- (NILine)NILineValue;

+ (NSValue *)valueWithNIPlane:(NIPlane)plane;
- (NIPlane)NIPlaneValue;

+ (NSValue *)valueWithNIAffineTransform:(NIAffineTransform)transform;
- (NIAffineTransform)NIAffineTransformValue;

@end

/** NSCoder support. **/

@interface NSCoder (NIGeometryAdditions)

- (void)encodeNIAffineTransform:(NIAffineTransform)transform forKey:(NSString *)key;
- (void)encodeNIVector:(NIVector)vector forKey:(NSString *)key;
- (void)encodeNILine:(NILine)line forKey:(NSString *)key;
- (void)encodeNIPlane:(NIPlane)plane forKey:(NSString *)key;

- (NIAffineTransform)decodeNIAffineTransformForKey:(NSString *)key;
- (NIVector)decodeNIVectorForKey:(NSString *)key;
- (NILine)decodeNILineForKey:(NSString *)key;
- (NIPlane)decodeNIPlaneForKey:(NSString *)key;

@end


#endif /* __OBJC__ */

#endif	/* _NIGEOMETRY_H_ */



