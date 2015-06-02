//
//  NIMPRQuaternion.h
//  NIMPR
//
//  Created by Alessandro Volz on 5/20/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <NIBuildingBlocks/NIGeometry.h>

@interface NIMPRQuaternion : NSObject

+ (instancetype)quaternion;
+ (instancetype)quaternion:(NIVector)vector;
+ (instancetype)quaternion:(CGFloat)x :(CGFloat)y :(CGFloat)z;

#ifndef NIMPRQuaternion_Private
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
#endif

- (NIVector)vector;
- (void)rotate:(CGFloat)rads axis:(NIVector)axis;

@end