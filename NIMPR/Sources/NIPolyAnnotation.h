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
}

@property(readonly) NSArray* vectors;
- (NSMutableArray*)mutableVectors;

@end
