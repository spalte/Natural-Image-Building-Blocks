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
@synthesize smoothen = _smoothen;

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
    return [NSSet setWithObjects: @"vectors", @"smoothen", nil];
}

- (NIBezierPath*)NIBezierPath {
    NIMutableBezierPath* path = [NIMutableBezierPath bezierPath];
    
    NSArray *cp1s = nil, *cp2s = nil;
    if (self.smoothen) {
        [self.class spline:self.vectors :&cp1s :&cp2s];
    }
    
    [self.vectors enumerateObjectsUsingBlock:^(NSValue* vv, NSUInteger i, BOOL *stop) {
        if (!i)
            [path moveToVector:vv.NIVectorValue];
        else {
            if (!self.smoothen || !cp1s || !cp2s)
                [path lineToVector:vv.NIVectorValue];
            else [path curveToVector:vv.NIVectorValue controlVector1:[cp1s[i-1] NIVectorValue] controlVector2:[cp2s[i-1] NIVectorValue]];
        }
    }];
    
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

+ (void)spline:(NSArray*)ksa :(NSArray**)rcp1s :(NSArray**)rcp2s {
    if (ksa.count <= 2) {
        *rcp1s = *rcp2s = nil;
        return;
    }
    
    NSUInteger n = ksa.count;
    
    NIVector ks[n];
    for (NSUInteger i = 0; i < n; ++i)
        ks[i] = [ksa[i] NIVectorValue];
    
    --n;
    NIVector t[n];
    
    t[0] = NIVectorAdd(ks[0], NIVectorScalarMultiply(ks[1], 2));
    for (NSUInteger i = 1; i < n-1; ++i)
        t[i] = NIVectorAdd(NIVectorScalarMultiply(ks[i], 4), NIVectorScalarMultiply(ks[i+1], 2));
    t[n-1] = NIVectorScalarMultiply(NIVectorAdd(NIVectorScalarMultiply(ks[n-1], 8), ks[n]), .5);
    
    NIVector r[n], tmp[n], b = NIVectorMake(2, 2, 2);
    
    r[0] = NIVectorMake(t[0].x/b.x, t[0].y/b.y, t[0].z/b.z);
    for (NSUInteger i = 1; i < n; ++i) { // decomposition and forward substitution
        tmp[i] = NIVectorMake(1./b.x, 1./b.y, 1./b.z);
        CGFloat bb = (i < n-1 ? 4.0 : 3.5);
        b = NIVectorMake(bb-tmp[i].x, bb-tmp[i].y, bb-tmp[i].z);
        r[i] = NIVectorMake((t[i].x-r[i-1].x)/b.x, (t[i].y-r[i-1].y)/b.y, (t[i].z-r[i-1].z)/b.z);
    }
    
    for (NSUInteger i = 1; i < n; ++i) // backsubstitution
        r[n-i-1] = NIVectorSubtract(r[n-i-1], NIVectorMake(tmp[n-i].x*r[n-i].x, tmp[n-i].y*r[n-i].y, tmp[n-i].z*r[n-i].z));
    
    NSMutableArray* cp1s = [NSMutableArray array];
    NSMutableArray* cp2s = [NSMutableArray array];
    *rcp1s = cp1s; *rcp2s = cp2s;
    
    for (NSUInteger i = 0; i < n; ++i) {
        [cp1s addObject:[NSValue valueWithNIVector:r[i]]];
        if (i < n-1)
            [cp2s addObject:[NSValue valueWithNIVector:NIVectorSubtract(NIVectorScalarMultiply(ks[i+1], 2), r[i+1])]];
        else [cp2s addObject:[NSValue valueWithNIVector:NIVectorScalarMultiply(NIVectorAdd(ks[n], r[n-1]), .5)]];
    }
}

@end
