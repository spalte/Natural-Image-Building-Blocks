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

+ (NSSet*)keyPathsForValuesAffectingNIBezierPath {
    return [NSSet setWithObjects: @"vectors", nil];
}

- (NIBezierPath*)NIBezierPath {
    NIMutableBezierPath* path = [NIMutableBezierPath bezierPath];
    
    BOOL first = YES;
    for (NSValue* vv in self.vectors) {
        if (first) {
            first = NO;
            [path moveToVector:vv.NIVectorValue];
        } else [path lineToVector:vv.NIVectorValue];
    }
    
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

@end
