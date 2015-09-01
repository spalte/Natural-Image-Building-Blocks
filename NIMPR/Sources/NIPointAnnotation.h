//
//  NIPointAnnotation.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/8/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotation.h"
#import <NIBuildingBlocks/NIGeometry.h>

@interface NIPointAnnotation : NIAnnotation {
    NIVector _vector;
}

@property NIVector vector;

+ (instancetype)pointWithVector:(NIVector)vector;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder*)coder NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithVector:(NIVector)vector;

@end
