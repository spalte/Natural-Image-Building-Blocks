//
//  NIPolyAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIPolyAnnotation.h"

@implementation NIPolyAnnotation

@synthesize vectors = _vectors;
@synthesize smooth = _smooth, closed = _closed;

- (id)init {
    if ((self = [super init])) {
        _vectors = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    [_vectors release];
    [super dealloc];
}

- (void)translate:(NIVector)translation {
    [self.vectors enumerateObjectsUsingBlock:^(NSValue* vv, NSUInteger idx, BOOL* stop) {
        [self.mutableVectors replaceObjectAtIndex:idx withObject:[NSValue valueWithNIVector:NIVectorAdd(vv.NIVectorValue, translation)]];
    }];
}

+ (NSSet*)keyPathsForValuesAffectingNIBezierPath {
    return [NSSet setWithObjects: @"vectors", @"smooth", @"closed", nil];
}

- (NIBezierPath*)NIBezierPath {
    if (self.smooth) {
        if (!self.closed)
            return [[[NIBezierPath alloc] initWithNodeArray:self.vectors style:NIBezierNodeOpenEndsStyle] autorelease];
        else {
            NSMutableArray* vectors = [[self.vectors mutableCopy] autorelease];
            [vectors addObject:vectors[0]];
            return [[[NIBezierPath alloc] initWithNodeArray:vectors style:NIBezierNodeEndsMeetStyle] autorelease];
        }
    }
    
    NIMutableBezierPath* path = [NIMutableBezierPath bezierPath];

    for (NSValue* vv in self.vectors)
        if (!path.elementCount)
            [path moveToVector:vv.NIVectorValue];
        else [path lineToVector:vv.NIVectorValue];
    
    if (self.closed)
        [path close];
    
    return path;
}

- (NSMutableArray*)mutableVectors {
    return [self mutableArrayValueForKey:@"vectors"];
}

- (NSUInteger)countOfVectors {
    return _vectors.count;
}

- (id)objectInVectorsAtIndex:(NSUInteger)index {
    return _vectors[index];
}

- (void)insertObject:(NSValue*)object inVectorsAtIndex:(NSUInteger)index {
    [_vectors insertObject:object atIndex:index];
}

- (void)removeObjectFromVectorsAtIndex:(NSUInteger)index {
    [_vectors removeObjectAtIndex:index];
}

- (NSSet*)handlesInView:(NIAnnotatedGeneratorRequestView*)view {
    NIAffineTransform dicomToSliceTransform = NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform);
    
    NSMutableSet* handles = [NSMutableSet set];
    
    [self.vectors enumerateObjectsUsingBlock:^(NSValue* vv, NSUInteger idx, BOOL* stop) {
        [handles addObject:[NIHandlerAnnotationHandle handleAtSliceVector:NIVectorApplyTransform(vv.NIVectorValue, dicomToSliceTransform)
                                                                  handler:^(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector d) {
                                                                      [self.mutableVectors replaceObjectAtIndex:idx withObject:[NSValue valueWithNIVector:NIVectorAdd([self.vectors[idx] NIVectorValue], d)]];
                                                                  }]];
    }];
    
    return handles;
}

//+ (void)spline:(NSArray*)ksa :(NSArray**)rcp1s :(NSArray**)rcp2s { // this produces an open bezier spline, based on http://www.codeproject.com/Articles/31859/Draw-a-Smooth-Curve-through-a-Set-of-D-Points-wit - check http://www.codeproject.com/Articles/33776/Draw-Closed-Smooth-Curve-with-Bezier-Spline for closed version..
//    assert(rcp1s != NULL && rcp2s != NULL);
//    
//    if (ksa.count <= 2) {
//        *rcp1s = *rcp2s = nil;
//        return;
//    }
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

//- (NSString*)description {
//    NSMutableString* s = [NSMutableString stringWithFormat:@"NIPolyAnnotation<%x>: {\n", (NSUInteger)self];
//    
//    for (NSValue* vv in self.vectors)
//        [s appendFormat:@"\t%@\n", NSStringFromNIVector(vv.NIVectorValue)];
//    
//    [s appendString:@"}\n"];
//    
//    return s;
//}

@end
