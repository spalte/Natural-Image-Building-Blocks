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

#import "NIBBBezierPath.h"
#import "NIBBGeometry.h"
#import "NIBBBezierCore.h"
#import "NIBBBezierCoreAdditions.h"

@interface _NIBBBezierCoreSteward : NSObject
{
	NIBBBezierCoreRef _bezierCore;
}

- (id)initWithNIBBBezierCore:(NIBBBezierCoreRef)bezierCore;
- (NIBBBezierCoreRef)NIBBBezierCore;

@end

@implementation _NIBBBezierCoreSteward

- (id)initWithNIBBBezierCore:(NIBBBezierCoreRef)bezierCore
{
	if ( (self = [super init]) ) {
		_bezierCore	= NIBBBezierCoreRetain(bezierCore);
	}
	return self;
}

- (NIBBBezierCoreRef)NIBBBezierCore
{
	return _bezierCore;
}

- (void)dealloc
{
	NIBBBezierCoreRelease(_bezierCore);
	_bezierCore = nil;
	[super dealloc];
}
				  
@end



@implementation NIBBBezierPath

- (id)init
{
    if ( (self = [super init]) ) {
        _bezierCore = NIBBBezierCoreCreateMutable();
    }
    return self;
}

- (id)initWithBezierPath:(NIBBBezierPath *)bezierPath
{
    if ( (self = [super init]) ) {
        _bezierCore = NIBBBezierCoreCreateMutableCopy([bezierPath NIBBBezierCore]);
        @synchronized (bezierPath) {
            _length = bezierPath->_length;
        }
    }
    return self;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict
{
	if ( (self = [super init]) ) {
		_bezierCore = NIBBBezierCoreCreateMutableWithDictionaryRepresentation((CFDictionaryRef)dict);
		if (_bezierCore == nil) {
			[self autorelease];
			return nil;
		}
	}
	return self;
}

- (id)initWithNIBBBezierCore:(NIBBBezierCoreRef)bezierCore
{
    if ( (self = [super init]) ) {
        _bezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
    }
    return self;
}

- (id)initWithNodeArray:(NSArray *)nodes style:(NIBBBezierNodeStyle)style // array of NIBBVectors in NSValues;
{
    NIBBVectorArray vectorArray;
    NSInteger i;
    
    if ( (self = [super init]) ) {
		if ([nodes count] >= 2) {
			vectorArray = malloc(sizeof(NIBBVector) * [nodes count]);
			
			for (i = 0; i < [nodes count]; i++) {
				vectorArray[i] = [[nodes objectAtIndex:i] NIBBVectorValue];
			}
			
			_bezierCore = NIBBBezierCoreCreateMutableCurveWithNodes(vectorArray, [nodes count], style);
			
			free(vectorArray);
		} else if ([nodes count] == 0) {
			_bezierCore = NIBBBezierCoreCreateMutable();
		} else {
			_bezierCore = NIBBBezierCoreCreateMutable();
			NIBBBezierCoreAddSegment(_bezierCore, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, [[nodes objectAtIndex:0] NIBBVectorValue]);
			if ([nodes count] > 1) {
				NIBBBezierCoreAddSegment(_bezierCore, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, [[nodes objectAtIndex:1] NIBBVectorValue]);
			}
		}

        
        if (_bezierCore == NULL) {
            [self autorelease];
            self = nil;
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	NSDictionary *bezierDict;
	
	bezierDict = [decoder decodeObjectForKey:@"bezierPathDictionaryRepresentation"];
	
	if ( (self = [self initWithDictionaryRepresentation:bezierDict]) ) {
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    NIBBMutableBezierPath *bezierPath;
    
    bezierPath = [[NIBBMutableBezierPath allocWithZone:zone] initWithBezierPath:self];
    return bezierPath;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    NIBBMutableBezierPath *bezierPath;
    
    bezierPath = [[NIBBMutableBezierPath allocWithZone:zone] initWithBezierPath:self];
    return bezierPath;
}

+ (id)bezierPath
{
    return [[[[self class] alloc] init] autorelease];
}

+ (id)bezierPathWithBezierPath:(NIBBBezierPath *)bezierPath
{
    return [[[[self class] alloc] initWithBezierPath:bezierPath] autorelease];
}

+ (id)bezierPathNIBBBezierCore:(NIBBBezierCoreRef)bezierCore
{
    return [[[[self class] alloc] initWithNIBBBezierCore:bezierCore] autorelease];
}

+ (id)bezierPathCircleWithCenter:(NIBBVector)center radius:(CGFloat)radius normal:(NIBBVector)normal
{
    NIBBVector planeVector = NIBBVectorANormalVector(normal);
    NIBBVector planeVector2 = NIBBVectorCrossProduct(normal, planeVector);
    NIBBMutableBezierPath *bezierPath = [NIBBMutableBezierPath bezierPath];
    
    NIBBVector corner1 = NIBBVectorAdd(center, NIBBVectorScalarMultiply(planeVector, radius));
    NIBBVector corner2 = NIBBVectorAdd(center, NIBBVectorScalarMultiply(planeVector2, radius));
    NIBBVector corner3 = NIBBVectorAdd(center, NIBBVectorScalarMultiply(planeVector, -radius));
    NIBBVector corner4 = NIBBVectorAdd(center, NIBBVectorScalarMultiply(planeVector2, -radius));
    
    [bezierPath moveToVector:corner1];
    [bezierPath curveToVector:corner2
               controlVector1:NIBBVectorAdd(corner1, NIBBVectorScalarMultiply(planeVector2, radius*0.551784))
               controlVector2:NIBBVectorAdd(corner2, NIBBVectorScalarMultiply(planeVector, radius*0.551784))];
    [bezierPath curveToVector:corner3
               controlVector1:NIBBVectorAdd(corner2, NIBBVectorScalarMultiply(planeVector, radius*-0.551784))
               controlVector2:NIBBVectorAdd(corner3, NIBBVectorScalarMultiply(planeVector2, radius*0.551784))];
    [bezierPath curveToVector:corner4
               controlVector1:NIBBVectorAdd(corner3, NIBBVectorScalarMultiply(planeVector2, radius*-0.551784))
               controlVector2:NIBBVectorAdd(corner4, NIBBVectorScalarMultiply(planeVector, radius*-0.551784))];
    [bezierPath curveToVector:corner1
               controlVector1:NIBBVectorAdd(corner4, NIBBVectorScalarMultiply(planeVector, radius*0.551784))
               controlVector2:NIBBVectorAdd(corner1, NIBBVectorScalarMultiply(planeVector2, radius*-0.551784))];
    [bezierPath close];
    return bezierPath;
}

- (void)dealloc
{
    NIBBBezierCoreRelease(_bezierCore);
    _bezierCore = nil;
    NIBBBezierCoreRandomAccessorRelease(_bezierCoreRandomAccessor);
    _bezierCoreRandomAccessor = nil;
    
    [super dealloc];
}

- (BOOL)isEqualToBezierPath:(NIBBBezierPath *)bezierPath
{
    if (self == bezierPath) {
        return YES;
    }
    
    return NIBBBezierCoreEqualToBezierCore(_bezierCore, [bezierPath NIBBBezierCore]);
}

- (BOOL)isEqual:(id)anObject
{
    if ([anObject isKindOfClass:[NIBBBezierPath class]]) {
        return [self isEqualToBezierPath:(NIBBBezierPath *)anObject];
    }
    return NO;
}

- (NSUInteger)hash
{
    return NIBBBezierCoreSegmentCount(_bezierCore);
}

- (NSString *)description
{
	return [(NSString *)NIBBBezierCoreCopyDescription(_bezierCore) autorelease];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
	NIBBVector endpoint;
    NSValue *endpointValue;
	
    if(state->state == 0) {
        [self length];
        state->mutationsPtr = (unsigned long *)&(self->_length);
    }
    
    if (state->state >= [self elementCount]) {
        return 0;
    }
    
    [self elementAtIndex:state->state control1:NULL control2:NULL endpoint:&endpoint];
    endpointValue = [NSValue valueWithNIBBVector:endpoint];
    state->itemsPtr = &endpointValue;
    state->state++;
    return 1;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:[self dictionaryRepresentation] forKey:@"bezierPathDictionaryRepresentation"];
}

- (NIBBBezierPath *)bezierPathByFlattening:(CGFloat)flatness
{
    NIBBMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath flatten:flatness];
    return newBezierPath;
}

- (NIBBBezierPath *)bezierPathBySubdividing:(CGFloat)maxSegmentLength;
{
    NIBBMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath subdivide:maxSegmentLength];
    return newBezierPath;
}

- (NIBBBezierPath *)bezierPathByApplyingTransform:(NIBBAffineTransform)transform
{
    NIBBMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath applyAffineTransform:transform];
    return newBezierPath;
}

- (NIBBBezierPath *)bezierPathByAddingEndpointsAtIntersectionsWithPlane:(NIBBPlane)plane // will flatten the path if it is not already flattened
{
    NIBBMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath addEndpointsAtIntersectionsWithPlane:plane];
    return newBezierPath;
}    

- (NIBBBezierPath *)bezierPathByAppendingBezierPath:(NIBBBezierPath *)bezierPath connectPaths:(BOOL)connectPaths;
{
    NIBBMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath appendBezierPath:bezierPath connectPaths:connectPaths];
    return newBezierPath;
}

- (NIBBBezierPath *)bezierPathByProjectingToPlane:(NIBBPlane)plane;
{
    NIBBMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath projectToPlane:plane];
    return newBezierPath;
}

- (NIBBBezierPath *)outlineBezierPathAtDistance:(CGFloat)distance initialNormal:(NIBBVector)initalNormal spacing:(CGFloat)spacing;
{
    NIBBBezierPath *outlinePath;
    NIBBBezierCoreRef outlineCore;
    
	if (NIBBBezierCoreSubpathCount(_bezierCore) != 1) {
		return nil;
	}
	
    outlineCore = NIBBBezierCoreCreateOutline(_bezierCore, distance, spacing, initalNormal);
    outlinePath = [[NIBBBezierPath alloc] initWithNIBBBezierCore:outlineCore];
    NIBBBezierCoreRelease(outlineCore);
    return [outlinePath autorelease];
}

- (NIBBBezierPath *)outlineBezierPathAtDistance:(CGFloat)distance projectionNormal:(NIBBVector)projectionNormal spacing:(CGFloat)spacing
{
    NIBBBezierPath *outlinePath;
    NIBBBezierCoreRef outlineCore;
    
	if (NIBBBezierCoreSubpathCount(_bezierCore) != 1) {
		return nil;
	}
	
    outlineCore = NIBBBezierCoreCreateOutlineWithNormal(_bezierCore, distance, spacing, projectionNormal);
    outlinePath = [[NIBBBezierPath alloc] initWithNIBBBezierCore:outlineCore];
    NIBBBezierCoreRelease(outlineCore);
    return [outlinePath autorelease];
}


- (NSInteger)elementCount
{
    return NIBBBezierCoreSegmentCount(_bezierCore);
}

- (CGFloat)length
{
	@synchronized (self) {
		if (_length	== 0.0) {
			_length = NIBBBezierCoreLength(_bezierCore);
		}
	}
	return _length;
}

- (CGFloat)lengthThroughElementAtIndex:(NSInteger)element
{
    return NIBBBezierCoreLengthToSegmentAtIndex(_bezierCore, element, NIBBBezierDefaultFlatness);
}

- (NIBBBezierCoreRef)NIBBBezierCore
{
	_NIBBBezierCoreSteward *bezierCoreSteward;
	NIBBBezierCoreRef copy;
	copy = NIBBBezierCoreCreateCopy(_bezierCore);
	bezierCoreSteward = [[_NIBBBezierCoreSteward alloc] initWithNIBBBezierCore:copy];
	NIBBBezierCoreRelease(copy);
	[bezierCoreSteward autorelease];
    return [bezierCoreSteward NIBBBezierCore];
}

- (NSBezierPath *)NSBezierPath
{
    NSBezierPath *newBezierPath = [NSBezierPath bezierPath];
    NSUInteger elementCount = [self elementCount];
    NSUInteger i;
    NIBBBezierPathElement pathElement;
    NIBBVector control1;
    NIBBVector control2;
    NIBBVector endPoint;

    for (i = 0; i < elementCount; i++) {
        pathElement = [self elementAtIndex:i control1:&control1 control2:&control2 endpoint:&endPoint];

        switch (pathElement) {
            case NIBBMoveToBezierPathElement:
                [newBezierPath moveToPoint:NSPointFromNIBBVector(endPoint)];
                break;
            case NIBBLineToBezierPathElement:
                [newBezierPath lineToPoint:NSPointFromNIBBVector(endPoint)];
                break;
            case NIBBCurveToBezierPathElement:
                [newBezierPath curveToPoint:NSPointFromNIBBVector(endPoint) controlPoint1:NSPointFromNIBBVector(control1) controlPoint2:NSPointFromNIBBVector(control2)];
                break;
            case NIBBCloseBezierPathElement:
                [newBezierPath closePath];
                break;
        }
    }

    return newBezierPath;
}

- (NSDictionary *)dictionaryRepresentation
{
	return [(NSDictionary *)NIBBBezierCoreCreateDictionaryRepresentation(_bezierCore) autorelease];
}

- (NIBBVector)vectorAtStart
{
    return NIBBBezierCoreVectorAtStart(_bezierCore);
}

- (NIBBVector)vectorAtEnd
{
    return NIBBBezierCoreVectorAtEnd(_bezierCore);
}

- (NIBBVector)tangentAtStart
{
    return NIBBBezierCoreTangentAtStart(_bezierCore);
}

- (NIBBVector)tangentAtEnd
{
    return NIBBBezierCoreTangentAtEnd(_bezierCore);
}

- (NIBBVector)normalAtEndWithInitialNormal:(NIBBVector)initialNormal
{
	if (NIBBBezierCoreSubpathCount(_bezierCore) != 1) {
		return NIBBVectorZero;
	}
	
    return NIBBBezierCoreNormalAtEndWithInitialNormal(_bezierCore, initialNormal);
}

- (BOOL)isPlanar
{
    return NIBBBezierCoreIsPlanar(_bezierCore, NULL);
}

- (NIBBPlane)leastSquaresPlane
{
	return NIBBBezierCoreLeastSquaresPlane(_bezierCore);
}

- (NIBBPlane)topBoundingPlaneForNormal:(NIBBVector)normal
{
    NIBBPlane plane;
    
    NIBBBezierCoreGetBoundingPlanesForNormal(_bezierCore, normal, &plane, NULL);
    return plane;
}

- (NIBBPlane)bottomBoundingPlaneForNormal:(NIBBVector)normal
{
    NIBBPlane plane;
    
    NIBBBezierCoreGetBoundingPlanesForNormal(_bezierCore, normal, NULL, &plane);
    return plane;
}

- (NIBBBezierPathElement)elementAtIndex:(NSInteger)index
{
    return [self elementAtIndex:index control1:NULL control2:NULL endpoint:NULL];
}

- (NIBBBezierPathElement)elementAtIndex:(NSInteger)index control1:(NIBBVectorPointer)control1 control2:(NIBBVectorPointer)control2 endpoint:(NIBBVectorPointer)endpoint; // Warning: differs from NSBezierPath in that controlVector2 is always the end
{
    NIBBBezierCoreSegmentType segmentType;
    NIBBVector control1Vector;
    NIBBVector control2Vector;
    NIBBVector endpointVector;
    
    @synchronized (self) {
        if (_bezierCoreRandomAccessor == NULL) {
            _bezierCoreRandomAccessor = NIBBBezierCoreRandomAccessorCreateWithMutableBezierCore(_bezierCore);
        }
    }
    
    segmentType = NIBBBezierCoreRandomAccessorGetSegmentAtIndex(_bezierCoreRandomAccessor, index, &control1Vector,  &control2Vector, &endpointVector);
    
    switch (segmentType) {
        case NIBBMoveToBezierCoreSegmentType:
            if (endpoint) {
                *endpoint = endpointVector;
            }            
            return NIBBMoveToBezierPathElement;
        case NIBBLineToBezierCoreSegmentType:
            if (endpoint) {
                *endpoint = endpointVector;
            }            
            return NIBBLineToBezierPathElement;
        case NIBBCurveToBezierCoreSegmentType:
            if (control1) {
                *control1 = control1Vector;
            }
            if (control2) {
                *control2 = control2Vector;
            }
            if (endpoint) {
                *endpoint = endpointVector;
            }
            return NIBBCurveToBezierPathElement;
		case NIBBCloseBezierCoreSegmentType:
            if (endpoint) {
                *endpoint = endpointVector;
            }            
            return NIBBCloseBezierPathElement;
        default:
            assert(0);
            return 0;
    }
}

- (NIBBVector)vectorAtRelativePosition:(CGFloat)relativePosition // RelativePosition is in [0, 1]
{
    NIBBVector vector;
    
    if (NIBBBezierCoreGetVectorInfo(_bezierCore, 0, relativePosition * [self length], NIBBVectorZero, &vector, NULL, NULL, 1)) {
        return vector;
    } else {
        return [self vectorAtEnd];
    }
}

- (NIBBVector)tangentAtRelativePosition:(CGFloat)relativePosition
{
    NIBBVector tangent;
    
    if (NIBBBezierCoreGetVectorInfo(_bezierCore, 0, relativePosition * [self length], NIBBVectorZero, NULL, &tangent, NULL, 1)) {
        return tangent;
    } else {
        return [self tangentAtEnd];
    }    
}

- (NIBBVector)normalAtRelativePosition:(CGFloat)relativePosition initialNormal:(NIBBVector)initialNormal
{
    NIBBVector normal;
    
	if (NIBBBezierCoreSubpathCount(_bezierCore) != 1) {
		return NIBBVectorZero;
	}
	
    if (NIBBBezierCoreGetVectorInfo(_bezierCore, 0, relativePosition * [self length], initialNormal, NULL, NULL, &normal, 1)) {
        return normal;
    } else {
        return [self normalAtEndWithInitialNormal:initialNormal];
    }    
}

- (CGFloat)relativePositionClosestToVector:(NIBBVector)vector
{
    return NIBBBezierCoreRelativePositionClosestToVector(_bezierCore, vector, NULL, NULL);
}

- (CGFloat)relativePositionClosestToLine:(NIBBLine)line;
{
    return NIBBBezierCoreRelativePositionClosestToLine(_bezierCore, line, NULL, NULL);
}

- (CGFloat)relativePositionClosestToLine:(NIBBLine)line closestVector:(NIBBVectorPointer)vectorPointer;
{
    return NIBBBezierCoreRelativePositionClosestToLine(_bezierCore, line, vectorPointer, NULL);
}

- (NIBBBezierPath *)bezierPathByCollapsingZ
{
    NIBBMutableBezierPath *collapsedBezierPath;
    NIBBAffineTransform collapseTransform;
    
    collapsedBezierPath = [self mutableCopy];
    
    collapseTransform = NIBBAffineTransformIdentity;
    collapseTransform.m33 = 0.0;
    
    [collapsedBezierPath applyAffineTransform:collapseTransform];
    
    return [collapsedBezierPath autorelease];
}

- (NIBBBezierPath *)bezierPathByReversing
{
    NIBBBezierCoreRef reversedBezierCore;
    NIBBMutableBezierPath *reversedBezierPath;
    
    reversedBezierCore = NIBBBezierCoreCreateCopyByReversing(_bezierCore);
    reversedBezierPath = [NIBBMutableBezierPath bezierPathNIBBBezierCore:reversedBezierCore];
    NIBBBezierCoreRelease(reversedBezierCore);
    return reversedBezierPath;
}

- (NSArray*)intersectionsWithPlane:(NIBBPlane)plane; // returns NSValues containing NIBBVectors of the intersections.
{
    return [self intersectionsWithPlane:plane relativePositions:NULL];
}

- (NSArray*)intersectionsWithPlane:(NIBBPlane)plane relativePositions:(NSArray **)returnedRelativePositions;
{
	NIBBMutableBezierPath *flattenedPath;
	NIBBBezierCoreRef bezierCore;
	NSInteger intersectionCount;
	NSInteger i;
	NSMutableArray *intersectionArray;
	NSMutableArray *relativePositionArray;
	CGFloat *relativePositions;
	NIBBVector *intersections;
	
    if (NIBBBezierCoreHasCurve(_bezierCore)) {
        flattenedPath = [self mutableCopy];
        [flattenedPath subdivide:NIBBBezierDefaultSubdivideSegmentLength];
        [flattenedPath flatten:NIBBBezierDefaultFlatness];
        
        bezierCore = NIBBBezierCoreRetain([flattenedPath NIBBBezierCore]);
        [flattenedPath release];
    } else {
        bezierCore = NIBBBezierCoreRetain(_bezierCore);
    }

	intersectionCount = NIBBBezierCoreCountIntersectionsWithPlane(bezierCore, plane);
	intersections = malloc(intersectionCount * sizeof(NIBBVector));
	relativePositions = malloc(intersectionCount * sizeof(CGFloat));
	
	intersectionCount = NIBBBezierCoreIntersectionsWithPlane(bezierCore, plane, intersections, relativePositions, intersectionCount);
	
	intersectionArray = [NSMutableArray arrayWithCapacity:intersectionCount];
	relativePositionArray = [NSMutableArray arrayWithCapacity:intersectionCount];
	for (i = 0; i < intersectionCount; i++) {
		[intersectionArray addObject:[NSValue valueWithNIBBVector:intersections[i]]];
		[relativePositionArray addObject:[NSNumber numberWithDouble:relativePositions[i]]];
	}
	
	free(relativePositions);
	free(intersections);
    NIBBBezierCoreRelease(bezierCore);
    
    if (returnedRelativePositions) {
        *returnedRelativePositions = relativePositionArray;
    }
	return intersectionArray;
}

- (NSArray *)subPaths
{
    NSMutableArray *subPaths = [NSMutableArray array];
    CFArrayRef cfSubPaths = NIBBBezierCoreCopySubpaths(_bezierCore);
    NSUInteger i;
    
    for (i = 0; i < CFArrayGetCount(cfSubPaths); i++) {
        [subPaths addObject:[NIBBBezierPath bezierPathNIBBBezierCore:CFArrayGetValueAtIndex(cfSubPaths, i)]];
    }
    
    CFRelease(cfSubPaths);
    return subPaths;
}

- (NIBBBezierPath *)bezierPathByClippingFromRelativePosition:(CGFloat)startRelativePosition toRelativePosition:(CGFloat)endRelativePosition
{
    NIBBBezierCoreRef clippedBezierCore;
    NIBBMutableBezierPath *clippedBezierPath;
    
    clippedBezierCore = NIBBBezierCoreCreateCopyByClipping(_bezierCore, startRelativePosition, endRelativePosition);
    clippedBezierPath = [NIBBMutableBezierPath bezierPathNIBBBezierCore:clippedBezierCore];
    NIBBBezierCoreRelease(clippedBezierCore);
    return clippedBezierPath;
}

- (CGFloat)signedAreaUsingNormal:(NIBBVector)normal
{
    return NIBBBezierCoreSignedAreaUsingNormal(_bezierCore, normal);
}


@end

@interface NIBBMutableBezierPath ()

- (void)_clearRandomAccessor;

@end


@implementation NIBBMutableBezierPath

- (void)moveToVector:(NIBBVector)vector
{
    [self _clearRandomAccessor];
    NIBBBezierCoreAddSegment(_bezierCore, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, vector);
}

- (void)lineToVector:(NIBBVector)vector
{
    [self _clearRandomAccessor];
    NIBBBezierCoreAddSegment(_bezierCore, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, vector);
}

- (void)curveToVector:(NIBBVector)vector controlVector1:(NIBBVector)controlVector1 controlVector2:(NIBBVector)controlVector2
{
    [self _clearRandomAccessor];
    NIBBBezierCoreAddSegment(_bezierCore, NIBBCurveToBezierCoreSegmentType, controlVector1, controlVector2, vector);
}

- (void)close
{
	[self _clearRandomAccessor];
    NIBBBezierCoreAddSegment(_bezierCore, NIBBCloseBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, NIBBVectorZero);
}

- (void)flatten:(CGFloat)flatness
{
    [self _clearRandomAccessor];
    NIBBBezierCoreFlatten(_bezierCore, flatness);
}

- (void)subdivide:(CGFloat)maxSegmentLength;
{
    [self _clearRandomAccessor];
    NIBBBezierCoreSubdivide(_bezierCore, maxSegmentLength);
}

- (void)applyAffineTransform:(NIBBAffineTransform)transform
{
    [self _clearRandomAccessor];
    NIBBBezierCoreApplyTransform(_bezierCore, transform);
}

- (void)projectToPlane:(NIBBPlane)plane
{
    NIBBMutableBezierCoreRef newBezierCore;
    
    [self _clearRandomAccessor];
    newBezierCore = NIBBBezierCoreCreateMutableCopyProjectedToPlane(_bezierCore, plane);
    NIBBBezierCoreRelease(_bezierCore);
    _bezierCore = newBezierCore;
}

- (void)appendBezierPath:(NIBBBezierPath *)bezierPath connectPaths:(BOOL)connectPaths
{
    [self _clearRandomAccessor];
    NIBBBezierCoreAppendBezierCore(_bezierCore, [bezierPath NIBBBezierCore], connectPaths);
}

- (void)addEndpointsAtIntersectionsWithPlane:(NIBBPlane)plane // will  flatten the path if it is not already flattened
{
    NIBBMutableBezierCoreRef newBezierCore;
    
    [self _clearRandomAccessor];
    newBezierCore = NIBBBezierCoreCreateMutableCopyWithEndpointsAtPlaneIntersections(_bezierCore, plane);
    NIBBBezierCoreRelease(_bezierCore);
    _bezierCore = newBezierCore;
}

- (void)_clearRandomAccessor
{
    NIBBBezierCoreRandomAccessorRelease(_bezierCoreRandomAccessor);
    _bezierCoreRandomAccessor = NULL;
	_length = 0.0;
}

- (void)setVectorsForElementAtIndex:(NSInteger)index control1:(NIBBVector)control1 control2:(NIBBVector)control2 endpoint:(NIBBVector)endpoint
{
	[self elementAtIndex:index]; // just to make sure that the _bezierCoreRandomAccessor has been initialized
	NIBBBezierCoreRandomAccessorSetVectorsForSegementAtIndex(_bezierCoreRandomAccessor, index, control1, control2, endpoint);
}

@end

















