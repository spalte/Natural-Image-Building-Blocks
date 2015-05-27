//
//  CPRMPRQuaternion.h
//  CPRMPR
//
//  Created by Alessandro Volz on 5/20/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <OsiriXAPI/N3Geometry.h>

@interface CPRMPRQuaternion : NSObject

+ (instancetype)quaternion;
+ (instancetype)quaternion:(N3Vector)vector;
+ (instancetype)quaternion:(CGFloat)x :(CGFloat)y :(CGFloat)z;

- (N3Vector)vector;
- (void)rotate:(CGFloat)rads axis:(N3Vector)axis;

@end