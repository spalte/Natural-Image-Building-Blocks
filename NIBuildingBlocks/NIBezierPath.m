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

#import "NIBezierPath.h"
#import "NIGeometry.h"
#import "NIBezierCore.h"
#import "NIBezierCoreAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface _NIBezierCoreSteward : NSObject
{
    NIBezierCoreRef _bezierCore;
}

- (instancetype)initWithNIBezierCore:(NIBezierCoreRef)bezierCore;
- (NIBezierCoreRef)NIBezierCore;

@end

@implementation _NIBezierCoreSteward

- (instancetype)initWithNIBezierCore:(NIBezierCoreRef)bezierCore
{
    if ( (self = [super init]) ) {
        _bezierCore	= NIBezierCoreRetain(bezierCore);
    }
    return self;
}

- (NIBezierCoreRef)NIBezierCore
{
    return _bezierCore;
}

- (void)dealloc
{
    NIBezierCoreRelease(_bezierCore);
    _bezierCore = nil;
    [super dealloc];
}

@end


@implementation NIBezierPath

- (nullable instancetype)init
{
    if ( (self = [super init]) ) {
        _bezierCore = NIBezierCoreCreateMutable();
    }
    return self;
}

- (nullable instancetype)initWithBezierPath:(NIBezierPath *)bezierPath
{
    if ( (self = [self init]) ) {
        NIBezierCoreRelease(_bezierCore);
        _bezierCore = NIBezierCoreCreateMutableCopy([bezierPath NIBezierCore]);
        @synchronized (bezierPath) {
            _length = bezierPath->_length;
        }
    }
    return self;
}

- (nullable instancetype)initWithNSBezierPath:(NSBezierPath *)bezierPath
{
    if ( (self = [self init]) ) {
        NIBezierCoreRelease(_bezierCore);
        _bezierCore = NIBezierCoreCreateMutableWithNSBezierPath(bezierPath);
    }
    return self;
}

- (nullable instancetype)initWithDictionaryRepresentation:(NSDictionary *)dict
{
    if ( (self = [self init]) ) {
        NIBezierCoreRelease(_bezierCore);
        _bezierCore = NIBezierCoreCreateMutableWithDictionaryRepresentation((CFDictionaryRef)dict);
        if (_bezierCore == nil) {
            [self autorelease];
            return nil;
        }
    }
    return self;
}

- (nullable instancetype)initWithNIBezierCore:(NIBezierCoreRef)bezierCore
{
    if ( (self = [self init]) ) {
        NIBezierCoreRelease(_bezierCore);
        _bezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
    }
    return self;
}

- (nullable instancetype)initWithNodeArray:(NSArray *)nodes style:(NIBezierNodeStyle)style // array of NIVectors in NSValues;
{
    NIVectorArray vectorArray;
    NSInteger i;

    if ( (self = [self init]) ) {
        if ([nodes count] >= 2) {
            vectorArray = malloc(sizeof(NIVector) * [nodes count]);

            for (i = 0; i < [nodes count]; i++) {
                vectorArray[i] = [[nodes objectAtIndex:i] NIVectorValue];
            }

            NIBezierCoreRelease(_bezierCore);
            _bezierCore = NIBezierCoreCreateMutableCurveWithNodes(vectorArray, [nodes count], style);

            free(vectorArray);
        } else if ([nodes count] == 0) {
            NIBezierCoreRelease(_bezierCore);
            _bezierCore = NIBezierCoreCreateMutable();
        } else {
            NIBezierCoreRelease(_bezierCore);
            _bezierCore = NIBezierCoreCreateMutable();
            NIBezierCoreAddSegment(_bezierCore, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, [[nodes objectAtIndex:0] NIVectorValue]);
            if ([nodes count] > 1) {
                NIBezierCoreAddSegment(_bezierCore, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, [[nodes objectAtIndex:1] NIVectorValue]);
            }
        }

        if (_bezierCore == NULL) {
            [self autorelease];
            self = nil;
        }
    }
    return self;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder
{
    if ([decoder allowsKeyedCoding]) {
        NSDictionary *bezierDict;

        bezierDict = [decoder decodeObjectOfClass:[NSDictionary class] forKey:@"bezierPathDictionaryRepresentation"];

        if ( (self = [self initWithDictionaryRepresentation:bezierDict]) ) {
        }
    } else {
        [NSException raise:NSInvalidUnarchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }
    return self;
}

- (instancetype)copyWithZone:(nullable NSZone *)zone
{
    NIMutableBezierPath *bezierPath;

    bezierPath = [[NIMutableBezierPath allocWithZone:zone] initWithBezierPath:self];
    return bezierPath;
}

- (instancetype)mutableCopyWithZone:(nullable NSZone *)zone
{
    NIMutableBezierPath *bezierPath;

    bezierPath = [[NIMutableBezierPath allocWithZone:zone] initWithBezierPath:self];
    return bezierPath;
}

+ (nullable instancetype)bezierPath
{
    return [[[[self class] alloc] init] autorelease];
}

+ (nullable instancetype)bezierPathWithBezierPath:(NIBezierPath *)bezierPath
{
    return [[[[self class] alloc] initWithBezierPath:bezierPath] autorelease];
}

+ (nullable instancetype)bezierPathWithNSBezierPath:(NSBezierPath *)bezierPath
{
    return [[[[self class] alloc] initWithNSBezierPath:bezierPath] autorelease];
}

+ (nullable instancetype)bezierPathNIBezierCore:(NIBezierCoreRef)bezierCore __deprecated
{
    return [self bezierPathWithNIBezierCore:bezierCore];
}

+ (nullable instancetype)bezierPathWithNIBezierCore:(NIBezierCoreRef)bezierCore
{
    return [[[[self class] alloc] initWithNIBezierCore:bezierCore] autorelease];
}

+ (nullable instancetype)bezierPathCircleWithCenter:(NIVector)center radius:(CGFloat)radius normal:(NIVector)normal
{
    NIVector planeVector = NIVectorANormalVector(normal);
    NIVector planeVector2 = NIVectorCrossProduct(normal, planeVector);
    NIMutableBezierPath *bezierPath = [NIMutableBezierPath bezierPath];

    NIVector corner1 = NIVectorAdd(center, NIVectorScalarMultiply(planeVector, radius));
    NIVector corner2 = NIVectorAdd(center, NIVectorScalarMultiply(planeVector2, radius));
    NIVector corner3 = NIVectorAdd(center, NIVectorScalarMultiply(planeVector, -radius));
    NIVector corner4 = NIVectorAdd(center, NIVectorScalarMultiply(planeVector2, -radius));

    [bezierPath moveToVector:corner1];
    [bezierPath curveToVector:corner2
               controlVector1:NIVectorAdd(corner1, NIVectorScalarMultiply(planeVector2, radius*0.551784))
               controlVector2:NIVectorAdd(corner2, NIVectorScalarMultiply(planeVector, radius*0.551784))];
    [bezierPath curveToVector:corner3
               controlVector1:NIVectorAdd(corner2, NIVectorScalarMultiply(planeVector, radius*-0.551784))
               controlVector2:NIVectorAdd(corner3, NIVectorScalarMultiply(planeVector2, radius*0.551784))];
    [bezierPath curveToVector:corner4
               controlVector1:NIVectorAdd(corner3, NIVectorScalarMultiply(planeVector2, radius*-0.551784))
               controlVector2:NIVectorAdd(corner4, NIVectorScalarMultiply(planeVector, radius*-0.551784))];
    [bezierPath curveToVector:corner1
               controlVector1:NIVectorAdd(corner4, NIVectorScalarMultiply(planeVector, radius*0.551784))
               controlVector2:NIVectorAdd(corner1, NIVectorScalarMultiply(planeVector2, radius*-0.551784))];
    [bezierPath close];
    return bezierPath;
}

- (void)dealloc
{
    NIBezierCoreRelease(_bezierCore);
    _bezierCore = nil;
    NIBezierCoreRandomAccessorRelease(_bezierCoreRandomAccessor);
    _bezierCoreRandomAccessor = nil;

    [super dealloc];
}

- (BOOL)isEqualToBezierPath:(NIBezierPath *)bezierPath
{
    if (self == bezierPath) {
        return YES;
    }

    return NIBezierCoreEqualToBezierCore(_bezierCore, [bezierPath NIBezierCore]);
}

- (BOOL)isEqual:(id)anObject
{
    if ([anObject isKindOfClass:[NIBezierPath class]]) {
        return [self isEqualToBezierPath:(NIBezierPath *)anObject];
    }
    return NO;
}

- (NSUInteger)hash
{
    return NIBezierCoreSegmentCount(_bezierCore);
}

- (NSString *)description
{
    return [(NSString *)NIBezierCoreCopyDescription(_bezierCore) autorelease];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
    NIVector endpoint;
    NSValue *endpointValue;

    if(state->state == 0) {
        [self length];
        state->mutationsPtr = (unsigned long *)&(self->_length);
    }

    if (state->state >= [self elementCount]) {
        return 0;
    }

    [self elementAtIndex:state->state control1:NULL control2:NULL endpoint:&endpoint];
    endpointValue = [NSValue valueWithNIVector:endpoint];
    state->itemsPtr = &endpointValue;
    state->state++;
    return 1;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject:[self dictionaryRepresentation] forKey:@"bezierPathDictionaryRepresentation"];
    } else {
        [NSException raise:NSInvalidArchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }
}

- (NIBezierPath *)bezierPathByFlattening:(CGFloat)flatness
{
    NIMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath flatten:flatness];
    return newBezierPath;
}

- (NIBezierPath *)bezierPathBySubdividing:(CGFloat)maxSegmentLength;
{
    NIMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath subdivide:maxSegmentLength];
    return newBezierPath;
}

- (NIBezierPath *)bezierPathByApplyingTransform:(NIAffineTransform)transform
{
    NIMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath applyAffineTransform:transform];
    return newBezierPath;
}

- (NIBezierPath *)bezierPathByApplyingConverter:(NIVector (^)(NIVector))converter __deprecated {
    NIMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath applyConverter:converter];
    return newBezierPath;
}

- (NIBezierPath *)bezierPathByAddingEndpointsAtIntersectionsWithPlane:(NIPlane)plane // will flatten the path if it is not already flattened
{
    NIMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath addEndpointsAtIntersectionsWithPlane:plane];
    return newBezierPath;
}

- (NIBezierPath *)bezierPathByAppendingBezierPath:(NIBezierPath *)bezierPath connectPaths:(BOOL)connectPaths;
{
    if (bezierPath == NULL) {
        [NSException raise:NSInvalidArgumentException format:@"*** %s: nil argument", __PRETTY_FUNCTION__];
    }

    NIMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath appendBezierPath:bezierPath connectPaths:connectPaths];
    return newBezierPath;
}

- (NIBezierPath *)bezierPathByProjectingToPlane:(NIPlane)plane;
{
    NIMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath projectToPlane:plane];
    return newBezierPath;
}

- (nullable NIBezierPath *)outlineBezierPathAtDistance:(CGFloat)distance initialNormal:(NIVector)initalNormal spacing:(CGFloat)spacing;
{
    NIBezierPath *outlinePath;
    NIBezierCoreRef outlineCore;

    if (NIBezierCoreSubpathCount(_bezierCore) != 1) {
        return nil;
    }

    outlineCore = NIBezierCoreCreateOutline(_bezierCore, distance, spacing, initalNormal);
    outlinePath = [[NIBezierPath alloc] initWithNIBezierCore:outlineCore];
    NIBezierCoreRelease(outlineCore);
    return [outlinePath autorelease];
}

- (nullable NIBezierPath *)outlineBezierPathAtDistance:(CGFloat)distance projectionNormal:(NIVector)projectionNormal spacing:(CGFloat)spacing
{
    NIBezierPath *outlinePath;
    NIBezierCoreRef outlineCore;

    if (NIBezierCoreSubpathCount(_bezierCore) != 1) {
        return nil;
    }

    outlineCore = NIBezierCoreCreateOutlineWithNormal(_bezierCore, distance, spacing, projectionNormal);
    outlinePath = [[NIBezierPath alloc] initWithNIBezierCore:outlineCore];
    NIBezierCoreRelease(outlineCore);
    return [outlinePath autorelease];
}


- (NSInteger)elementCount
{
    return NIBezierCoreSegmentCount(_bezierCore);
}

- (CGFloat)length
{
    @synchronized (self) {
        if (_length	== 0.0) {
            _length = NIBezierCoreLength(_bezierCore);
        }
    }
    return _length;
}

- (CGFloat)lengthThroughElementAtIndex:(NSInteger)element
{
    return NIBezierCoreLengthToSegmentAtIndex(_bezierCore, element, NIBezierDefaultFlatness);
}

- (NIBezierCoreRef)NIBezierCore
{
    _NIBezierCoreSteward *bezierCoreSteward;
    NIBezierCoreRef copy;
    copy = NIBezierCoreCreateCopy(_bezierCore);
    bezierCoreSteward = [[_NIBezierCoreSteward alloc] initWithNIBezierCore:copy];
    NIBezierCoreRelease(copy);
    [bezierCoreSteward autorelease];
    return [bezierCoreSteward NIBezierCore];
}

- (NSBezierPath *)NSBezierPath
{
    NSBezierPath *newBezierPath = [NSBezierPath bezierPath];
    NSUInteger elementCount = [self elementCount];
    NSUInteger i;
    NIBezierPathElement pathElement;
    NIVector control1;
    NIVector control2;
    NIVector endPoint;

    for (i = 0; i < elementCount; i++) {
        pathElement = [self elementAtIndex:i control1:&control1 control2:&control2 endpoint:&endPoint];

        switch (pathElement) {
            case NIMoveToBezierPathElement:
                [newBezierPath moveToPoint:NSPointFromNIVector(endPoint)];
                break;
            case NILineToBezierPathElement:
                [newBezierPath lineToPoint:NSPointFromNIVector(endPoint)];
                break;
            case NICurveToBezierPathElement:
                [newBezierPath curveToPoint:NSPointFromNIVector(endPoint) controlPoint1:NSPointFromNIVector(control1) controlPoint2:NSPointFromNIVector(control2)];
                break;
            case NICloseBezierPathElement:
                [newBezierPath closePath];
                break;
        }
    }

    return newBezierPath;
}

- (NSDictionary *)dictionaryRepresentation
{
    return [(NSDictionary *)NIBezierCoreCreateDictionaryRepresentation(_bezierCore) autorelease];
}

- (NIVector)vectorAtStart
{
    return NIBezierCoreVectorAtStart(_bezierCore);
}

- (NIVector)vectorAtEnd
{
    return NIBezierCoreVectorAtEnd(_bezierCore);
}

- (NIVector)tangentAtStart
{
    return NIBezierCoreTangentAtStart(_bezierCore);
}

- (NIVector)tangentAtEnd
{
    return NIBezierCoreTangentAtEnd(_bezierCore);
}

- (NIVector)normalAtEndWithInitialNormal:(NIVector)initialNormal
{
    if (NIBezierCoreSubpathCount(_bezierCore) != 1) {
        return NIVectorZero;
    }

    return NIBezierCoreNormalAtEndWithInitialNormal(_bezierCore, initialNormal);
}

- (BOOL)isPlanar
{
    return NIBezierCoreIsPlanar(_bezierCore, NULL);
}

- (BOOL)isClosed
{
    NSInteger elementCount = [self elementCount];
    if (elementCount && [self elementAtIndex:elementCount - 1] == NICloseBezierPathElement) {
        return YES;
    } else {
        return NO;
    }
}

- (NIPlane)leastSquaresPlane
{
    return NIBezierCoreLeastSquaresPlane(_bezierCore);
}

- (NIPlane)topBoundingPlaneForNormal:(NIVector)normal
{
    NIPlane plane;

    NIBezierCoreGetBoundingPlanesForNormal(_bezierCore, normal, &plane, NULL);
    return plane;
}

- (NIPlane)bottomBoundingPlaneForNormal:(NIVector)normal
{
    NIPlane plane;

    NIBezierCoreGetBoundingPlanesForNormal(_bezierCore, normal, NULL, &plane);
    return plane;
}

- (NIBezierPathElement)elementAtIndex:(NSInteger)index
{
    return [self elementAtIndex:index control1:NULL control2:NULL endpoint:NULL];
}

- (NIBezierPathElement)elementAtIndex:(NSInteger)index control1:(nullable NIVectorPointer)control1 control2:(nullable NIVectorPointer)control2 endpoint:(nullable NIVectorPointer)endpoint; // Warning: differs from NSBezierPath in that controlVector2 is always the end
{
    NIBezierCoreSegmentType segmentType;
    NIVector control1Vector;
    NIVector control2Vector;
    NIVector endpointVector;

    @synchronized (self) {
        if (_bezierCoreRandomAccessor == NULL) {
            _bezierCoreRandomAccessor = NIBezierCoreRandomAccessorCreateWithMutableBezierCore(_bezierCore);
        }
    }

    segmentType = NIBezierCoreRandomAccessorGetSegmentAtIndex(_bezierCoreRandomAccessor, index, &control1Vector,  &control2Vector, &endpointVector);

    switch (segmentType) {
        case NIMoveToBezierCoreSegmentType:
            if (endpoint) {
                *endpoint = endpointVector;
            }
            return NIMoveToBezierPathElement;
        case NILineToBezierCoreSegmentType:
            if (endpoint) {
                *endpoint = endpointVector;
            }
            return NILineToBezierPathElement;
        case NICurveToBezierCoreSegmentType:
            if (control1) {
                *control1 = control1Vector;
            }
            if (control2) {
                *control2 = control2Vector;
            }
            if (endpoint) {
                *endpoint = endpointVector;
            }
            return NICurveToBezierPathElement;
        case NICloseBezierCoreSegmentType:
            if (endpoint) {
                *endpoint = endpointVector;
            }
            return NICloseBezierPathElement;
        default:
            assert(0);
            return 0;
    }
}

- (NIVector)vectorAtRelativePosition:(CGFloat)relativePosition // RelativePosition is in [0, 1]
{
    NIVector vector;

    if (NIBezierCoreGetVectorInfo(_bezierCore, 0, relativePosition * [self length], NIVectorZero, &vector, NULL, NULL, 1)) {
        return vector;
    } else {
        return [self vectorAtEnd];
    }
}

- (NIVector)tangentAtRelativePosition:(CGFloat)relativePosition
{
    NIVector tangent;

    if (NIBezierCoreGetVectorInfo(_bezierCore, 0, relativePosition * [self length], NIVectorZero, NULL, &tangent, NULL, 1)) {
        return tangent;
    } else {
        return [self tangentAtEnd];
    }
}

- (NIVector)normalAtRelativePosition:(CGFloat)relativePosition initialNormal:(NIVector)initialNormal
{
    NIVector normal;

    if (NIBezierCoreSubpathCount(_bezierCore) != 1) {
        return NIVectorZero;
    }

    if (NIBezierCoreGetVectorInfo(_bezierCore, 0, relativePosition * [self length], initialNormal, NULL, NULL, &normal, 1)) {
        return normal;
    } else {
        return [self normalAtEndWithInitialNormal:initialNormal];
    }
}

- (CGFloat)relativePositionClosestToVector:(NIVector)vector
{
    return NIBezierCoreRelativePositionClosestToVector(_bezierCore, vector, NULL, NULL);
}

- (CGFloat)relativePositionClosestToLine:(NILine)line;
{
    return NIBezierCoreRelativePositionClosestToLine(_bezierCore, line, NULL, NULL);
}

- (CGFloat)relativePositionClosestToLine:(NILine)line closestVector:(nullable NIVectorPointer)vectorPointer;
{
    return NIBezierCoreRelativePositionClosestToLine(_bezierCore, line, vectorPointer, NULL);
}

- (NIBezierPath *)bezierPathByCollapsingZ
{
    NIMutableBezierPath *collapsedBezierPath;
    NIAffineTransform collapseTransform;

    collapsedBezierPath = [self mutableCopy];

    collapseTransform = NIAffineTransformIdentity;
    collapseTransform.m33 = 0.0;

    [collapsedBezierPath applyAffineTransform:collapseTransform];

    return [collapsedBezierPath autorelease];
}

- (NIBezierPath *)bezierPathByReversing
{
    NIBezierCoreRef reversedBezierCore;
    NIMutableBezierPath *reversedBezierPath;

    reversedBezierCore = NIBezierCoreCreateCopyByReversing(_bezierCore);
    reversedBezierPath = [NIMutableBezierPath bezierPathWithNIBezierCore:reversedBezierCore];
    NIBezierCoreRelease(reversedBezierCore);
    return reversedBezierPath;
}

- (NSArray*)intersectionsWithPlane:(NIPlane)plane; // returns NSValues containing NIVectors of the intersections.
{
    return [self intersectionsWithPlane:plane relativePositions:NULL];
}

- (NSArray*)intersectionsWithPlane:(NIPlane)plane relativePositions:(NSArray * __nonnull * __nullable)returnedRelativePositions;
{
    NIMutableBezierPath *flattenedPath;
    NIBezierCoreRef bezierCore;
    NSInteger intersectionCount;
    NSInteger i;
    NSMutableArray *intersectionArray;
    NSMutableArray *relativePositionArray;
    CGFloat *relativePositions;
    NIVector *intersections;

    if (NIBezierCoreHasCurve(_bezierCore)) {
        flattenedPath = [self mutableCopy];
        [flattenedPath subdivide:NIBezierDefaultSubdivideSegmentLength];
        [flattenedPath flatten:NIBezierDefaultFlatness];

        bezierCore = NIBezierCoreRetain([flattenedPath NIBezierCore]);
        [flattenedPath release];
    } else {
        bezierCore = NIBezierCoreRetain(_bezierCore);
    }

    intersectionCount = NIBezierCoreCountIntersectionsWithPlane(bezierCore, plane);
    intersections = malloc(intersectionCount * sizeof(NIVector));
    relativePositions = malloc(intersectionCount * sizeof(CGFloat));

    intersectionCount = NIBezierCoreIntersectionsWithPlane(bezierCore, plane, intersections, relativePositions, intersectionCount);

    intersectionArray = [NSMutableArray arrayWithCapacity:intersectionCount];
    relativePositionArray = [NSMutableArray arrayWithCapacity:intersectionCount];
    for (i = 0; i < intersectionCount; i++) {
        [intersectionArray addObject:[NSValue valueWithNIVector:intersections[i]]];
        [relativePositionArray addObject:[NSNumber numberWithDouble:relativePositions[i]]];
    }

    free(relativePositions);
    free(intersections);
    NIBezierCoreRelease(bezierCore);

    if (returnedRelativePositions) {
        *returnedRelativePositions = relativePositionArray;
    }
    return intersectionArray;
}

- (NSArray *)subPaths
{
    NSMutableArray *subPaths = [NSMutableArray array];
    CFArrayRef cfSubPaths = NIBezierCoreCopySubpaths(_bezierCore);
    NSUInteger i;

    for (i = 0; i < CFArrayGetCount(cfSubPaths); i++) {
        [subPaths addObject:[NIBezierPath bezierPathWithNIBezierCore:CFArrayGetValueAtIndex(cfSubPaths, i)]];
    }

    CFRelease(cfSubPaths);
    return subPaths;
}

- (NIBezierPath *)bezierPathByClippingFromRelativePosition:(CGFloat)startRelativePosition toRelativePosition:(CGFloat)endRelativePosition
{
    NIBezierCoreRef clippedBezierCore;
    NIMutableBezierPath *clippedBezierPath;

    clippedBezierCore = NIBezierCoreCreateCopyByClipping(_bezierCore, startRelativePosition, endRelativePosition);
    clippedBezierPath = [NIMutableBezierPath bezierPathWithNIBezierCore:clippedBezierCore];
    NIBezierCoreRelease(clippedBezierCore);
    return clippedBezierPath;
}

- (CGFloat)signedAreaUsingNormal:(NIVector)normal
{
    return NIBezierCoreSignedAreaUsingNormal(_bezierCore, normal);
}


@end

@interface NIMutableBezierPath ()

- (void)_clearRandomAccessor;

@end


@implementation NIMutableBezierPath

- (void)moveToVector:(NIVector)vector
{
    [self _clearRandomAccessor];
    NIBezierCoreAddSegment(_bezierCore, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, vector);
}

- (void)lineToVector:(NIVector)vector
{
    [self _clearRandomAccessor];
    NIBezierCoreAddSegment(_bezierCore, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, vector);
}

- (void)curveToVector:(NIVector)vector controlVector1:(NIVector)controlVector1 controlVector2:(NIVector)controlVector2
{
    [self _clearRandomAccessor];
    NIBezierCoreAddSegment(_bezierCore, NICurveToBezierCoreSegmentType, controlVector1, controlVector2, vector);
}

- (void)close
{
    [self _clearRandomAccessor];
    NIBezierCoreAddSegment(_bezierCore, NICloseBezierCoreSegmentType, NIVectorZero, NIVectorZero, NIVectorZero);
}

- (void)flatten:(CGFloat)flatness
{
    [self _clearRandomAccessor];
    NIBezierCoreFlatten(_bezierCore, flatness);
}

- (void)subdivide:(CGFloat)maxSegmentLength;
{
    [self _clearRandomAccessor];
    NIBezierCoreSubdivide(_bezierCore, maxSegmentLength);
}

- (void)applyAffineTransform:(NIAffineTransform)transform
{
    [self _clearRandomAccessor];
    NIBezierCoreApplyTransform(_bezierCore, transform);
}

- (void)applyConverter:(NIVector (^)(NIVector))converter __deprecated {
    [self _clearRandomAccessor];
    NIBezierCoreApplyConverter(_bezierCore, converter);
}

- (void)projectToPlane:(NIPlane)plane
{
    NIMutableBezierCoreRef newBezierCore;

    [self _clearRandomAccessor];
    newBezierCore = NIBezierCoreCreateMutableCopyProjectedToPlane(_bezierCore, plane);
    NIBezierCoreRelease(_bezierCore);
    _bezierCore = newBezierCore;
}

- (void)appendBezierPath:(NIBezierPath *)bezierPath connectPaths:(BOOL)connectPaths
{
    [self _clearRandomAccessor];
    NIBezierCoreAppendBezierCore(_bezierCore, [bezierPath NIBezierCore], connectPaths);
}

- (void)addEndpointsAtIntersectionsWithPlane:(NIPlane)plane // will flatten the path if it is not already flattened
{
    NIMutableBezierCoreRef newBezierCore;

    [self _clearRandomAccessor];
    newBezierCore = NIBezierCoreCreateMutableCopyWithEndpointsAtPlaneIntersections(_bezierCore, plane);
    NIBezierCoreRelease(_bezierCore);
    _bezierCore = newBezierCore;
}

- (void)_clearRandomAccessor
{
    NIBezierCoreRandomAccessorRelease(_bezierCoreRandomAccessor);
    _bezierCoreRandomAccessor = NULL;
    _length = 0.0;
}

- (void)setVectorsForElementAtIndex:(NSInteger)index control1:(NIVector)control1 control2:(NIVector)control2 endpoint:(NIVector)endpoint
{
    [self elementAtIndex:index]; // just to make sure that the _bezierCoreRandomAccessor has been initialized
    NIBezierCoreRandomAccessorSetVectorsForSegementAtIndex(_bezierCoreRandomAccessor, index, control1, control2, endpoint);
}

@end

@implementation NIBezierPath (MoveMe)

// http://www.codeproject.com/Articles/33776/Draw-Closed-Smooth-Curve-with-Bezier-Spline
+ (nullable instancetype)closedSplinePathWithNodes:(NSArray *)ka {
    size_t const n = ka.count;

    if (n <= 2)
        return nil;

    NIVector k[n];
    for (NSUInteger i = 0; i < n; ++i)
        k[i] = [ka[i] NIVectorValue];

    NIVector a[n], b[n], c[n];
    for (NSUInteger i = 0; i < n; ++i) {
        a[i] = c[i] = NIVectorOne; b[i] = NIVectorMake(4, 4, 4);
    }

    NIVector rhs[n]; // right hand side
    for (size_t i = 0; i < n; ++i)
        rhs[i] = NIVectorAdd(NIVectorScalarMultiply(k[i], 4), NIVectorScalarMultiply(k[(i+1)%n], 2));

    NIVector cp1[n];
    cyclicSolve(n, a, b, c, NIVectorOne, NIVectorOne, rhs, cp1);

    NIMutableBezierPath *path = [NIMutableBezierPath bezierPath];
    [path moveToVector:k[n-1]];
    for (int i = 0; i < n; ++i)
        [path curveToVector:k[i]
             controlVector1:cp1[(i? i-1 : n-1)]
             controlVector2:NIVectorSubtract(NIVectorScalarMultiply(k[i], 2), cp1[i])];
    [path close];

    return path;
}

// solves the cyclic set of linear equations, of the form
/// b0 c0  0 · · · · · · ß
///	a1 b1 c1 · · · · · · ·
///  · · · · · · · · · · ·
///  · · · a[n-2] b[n-2] c[n-2]
/// α  · · · · 0  a[n-1] b[n-1]
// This is a tridiagonal system, except for the matrix elements a and ß in the corners
static void cyclicSolve(const size_t n, const NIVector *a, const NIVector *b, const NIVector *c, const NIVector alpha, const NIVector beta, const NIVector *rhs, NIVector* x) {
    NIVector gamma = NIVectorInvert(b[0]), bb[n];

    // set up the diagonal of the modified tridiagonal system
    bb[0] = NIVectorSubtract(b[0], gamma);
    for (size_t i = 1; i < n-1; ++i)
        bb[i] = b[i];
    bb[n-1] = NIVectorSubtract(b[n-1], NIVectorDivide(NIVectorMultiply(alpha, beta), gamma));

    // solve A·x = r
    tridiagonalSolve(n, a, bb, c, rhs, x);

    // setup u
    NIVector u[n];
    u[0] = gamma;
    for (size_t i = 1; i < n-1; ++i)
        u[i] = NIVectorZero;
    u[n-1] = alpha;

    // solve A·z = u
    NIVector z[n];
    tridiagonalSolve(n, a, bb, c, u, z);

    // form v·x/(1+v·z)
    NIVector fact = NIVectorDivide(NIVectorAdd(x[0], NIVectorDivide(NIVectorMultiply(beta, x[n-1]), gamma)), NIVectorAdd(NIVectorOne, NIVectorAdd(z[0], NIVectorDivide(NIVectorMultiply(beta, z[n-1]), gamma))));

    // get the solution
    for (size_t i = 0; i < n; ++i)
        x[i] = NIVectorSubtract(x[i], NIVectorMultiply(fact, z[i]));
}

static void tridiagonalSolve(const size_t n, const NIVector *a, const NIVector *b, const NIVector *c, const NIVector *r, NIVector *u) {
    assert(b[0].x != 0 && b[0].y != 0 && b[0].z != 0);

    NIVector gam[n]; // workspace
    NIVector bet = b[0];
    u[0] = NIVectorDivide(r[0], bet);
    for (size_t i = 1; i < n; ++i) { // decomposition and forward substitution
        gam[i] = NIVectorDivide(c[i-1], bet);
        bet = NIVectorSubtract(b[i], NIVectorMultiply(a[i], gam[i]));
        assert(bet.x != 0 && bet.y != 0 && bet.z != 0);
        u[i] = NIVectorDivide(NIVectorSubtract(r[i], NIVectorMultiply(a[i], u[i-1])), bet);
    }

    for (size_t i = 1; i < n; ++i)
        u[n-i-1] = NIVectorSubtract(u[n-i-1], NIVectorMultiply(gam[n-i], u[n-i])); // backsubstitution
}

// this was my take on open splines...
//+ (void)spline:(NSArray<NSValue/*NIVector*/ *> *)ksa :(NSArray<NSValue/*NIVector*/ *> **)rcp1s :(NSArray<NSValue/*NIVector*/ *> **)rcp2s { // this produces an open bezier spline, based on http://www.codeproject.com/Articles/31859/Draw-a-Smooth-Curve-through-a-Set-of-D-Points-wit - check http://www.codeproject.com/Articles/33776/Draw-Closed-Smooth-Curve-with-Bezier-Spline for closed version..
//    assert(rcp1s != NULL && rcp2s != NULL);
//
//    if (ksa.count < 2) {
//        *rcp1s = *rcp2s = nil;
//        return;
//    }
//
////if (n == 2) {
////    [path moveToVector:k[0]];
////    NIVector cp1 = NIVectorScalarDivide(NIVectorAdd(NIVectorScalarMultiply(k[0], 2), k[1]), 3); // 3*p1 = 2*p0 + p3
////    [path curveToVector:k[1] controlVector1:cp1 controlVector2:NIVectorSubtract(NIVectorScalarMultiply(cp1, 2), k[0])]; // p2 = 2*p1 – p0
////    [path close];
////    return path;
////}
//
//    NSUInteger n = ksa.count;
//
//    NIVector ks[n];
//    for (NSUInteger i = 0; i < n; ++i)
//        ks[i] = [ksa[i] NIVectorValue];
//
//    --n;
//    NIVector t[n];
//
//    t[0] = NIVectorAdd(ks[0], NIVectorScalarMultiply(ks[1], 2));
//    for (NSUInteger i = 1; i < n-1; ++i)
//        t[i] = NIVectorAdd(NIVectorScalarMultiply(ks[i], 4), NIVectorScalarMultiply(ks[i+1], 2));
//    t[n-1] = NIVectorScalarDivide(NIVectorAdd(NIVectorScalarMultiply(ks[n-1], 8), ks[n]), 2);
//
//    NIVector r[n], tmp[n], b = NIVectorMake(2, 2, 2);
//
//    r[0] = NIVectorDivide(t[0], b);
//    for (NSUInteger i = 1; i < n; ++i) { // decomposition and forward substitution
//        tmp[i] = NIVectorDivide(NIVectorOne, b);
//        CGFloat bb = (i < n-1 ? 4.0 : 3.5);
//        b = NIVectorMake(bb-tmp[i].x, bb-tmp[i].y, bb-tmp[i].z);
//        r[i] = NIVectorDivide(NIVectorSubtract(t[i], r[i-1]), b);
//    }
//
//    for (NSUInteger i = 1; i < n; ++i) // backsubstitution
//        r[n-i-1] = NIVectorSubtract(r[n-i-1], NIVectorMultiply(tmp[n-i], r[n-i]));
//
//    NSMutableArray* cp1s = [NSMutableArray array];
//    NSMutableArray* cp2s = [NSMutableArray array];
//    *rcp1s = cp1s; *rcp2s = cp2s;
//
//    for (NSUInteger i = 0; i < n; ++i) {
//        [cp1s addObject:[NSValue valueWithNIVector:r[i]]];
//        if (i < n-1)
//            [cp2s addObject:[NSValue valueWithNIVector:NIVectorSubtract(NIVectorScalarMultiply(ks[i+1], 2), r[i+1])]];
//        else [cp2s addObject:[NSValue valueWithNIVector:NIVectorScalarMultiply(NIVectorAdd(ks[n], r[n-1]), .5)]];
//    }
//}

@end

NS_ASSUME_NONNULL_END













