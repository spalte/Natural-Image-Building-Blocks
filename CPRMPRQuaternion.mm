//
//  CPRMPRQuaternion.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/20/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRQuaternion.hpp"

@implementation CPRMPRQuaternion

+ (instancetype)quaternion {
    return [[[self.class alloc] init] autorelease];
}

+ (instancetype)quaternion:(const cprmpr::quaternion&)quaternion {
    return [[[self.class alloc] initWithQuaternion:quaternion] autorelease];
}

+ (instancetype)quaternion:(CGFloat)x :(CGFloat)y :(CGFloat)z {
    return [[[self.class alloc] initWithValues:x:y:z] autorelease];
}

- (instancetype)initWithQuaternion:(const cprmpr::quaternion&)quaternion {
    if ((self = [super init])) {
        _quaternion = quaternion;
    }
    
    return self;
}

- (instancetype)initWithValues:(CGFloat)x :(CGFloat)y :(CGFloat)z {
    return [self initWithQuaternion:cprmpr::quaternion(x, y, z)];
}

- (instancetype)initWithValues:(CGFloat)w :(CGFloat)x :(CGFloat)y :(CGFloat)z {
    return [self initWithQuaternion:cprmpr::quaternion(w, x, y, z)];
}

- (instancetype)copyWithZone:(NSZone*)zone {
    return [[self.class alloc] initWithQuaternion:_quaternion];
}

- (void)rotate:(CGFloat)rads axis:(N3Vector)axis {
    _quaternion = _quaternion.rotate(axis, rads);
}

- (N3Vector)rotated:(CGFloat)rads axis:(N3Vector)axis {
    return _quaternion.rotate(axis, rads).vector();
}

- (N3Vector)vector {
    return _quaternion.vector();
}

- (NSString*)description {
    return [NSString stringWithFormat:@"(%f,%f,%f,%f)", _quaternion.x(), _quaternion.y(), _quaternion.z(), _quaternion.w()];
}

@end

