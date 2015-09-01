//
//  NIPolyAnnotation.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIBezierPathAnnotation.h"

@interface NIPolyAnnotation : NIBezierPathAnnotation {
    NSMutableArray* _vectors;
    BOOL _smooth, _closed;
}

@property(readonly) NSArray* vectors;
- (NSMutableArray*)mutableVectors;

@property BOOL smooth, closed;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder*)coder NS_DESIGNATED_INITIALIZER;

@end
