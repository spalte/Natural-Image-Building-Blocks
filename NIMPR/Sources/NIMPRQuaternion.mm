//
//  NIMPRQuaternion.m
//  NIMPR
//
//  Created by Alessandro Volz on 5/20/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#define NIMPRQuaternion_Private

#import "NIMPRQuaternion.h"

namespace NIMPR {
    class quaternion {
        CGFloat _w, _x, _y, _z;
        
        CGFloat length() const { return sqrtf( powf(_w, 2) + powf(_x, 2) + powf(_y, 2) + powf(_z, 2) ); }
        void normalize() { CGFloat l = length(); if (l) { _w /= l; _x /= l; _y /= l; _z /= l; } }
        quaternion conjugate() const { return quaternion(_w, -_x, -_y, -_z); }
        
    public:
        quaternion(CGFloat w, CGFloat x, CGFloat y, CGFloat z) : _w(w), _x(x), _y(y), _z(z) { normalize(); }
        quaternion() : quaternion(1, 0, 0, 0) {}
        quaternion(const quaternion& q) : quaternion(q.w(), q.x(), q.y(), q.z()) {}
        quaternion(const NIVector& v) : quaternion(0, v.x, v.y, v.z) {}
        quaternion(CGFloat x, CGFloat y, CGFloat z) : quaternion(0, x, y, z) {}
        
        inline CGFloat w() const { return _w; }
        inline CGFloat x() const { return _x; }
        inline CGFloat y() const { return _y; }
        inline CGFloat z() const { return _z; }
        
        quaternion operator*(const quaternion& q) const { // cross product
            CGFloat qw = q.w(), qx = q.x(), qy = q.y(), qz = q.z();
            return quaternion( _w*qw - _x*qx - _y*qy - _z*qz,
                              _w*qx + _x*qw + _y*qz - _z*qy,
                              _w*qy - _x*qz + _y*qw + _z*qx,
                              _w*qz + _x*qy - _y*qx + _z*qw );
        }
        
        quaternion& operator=(const quaternion& q) {
            _w = q.w(); _x = q.x(); _y = q.y(); _z = q.z();
            return *this;
        }
        
        quaternion rotate(const quaternion& axis, CGFloat rads) const {
            CGFloat rads_div2 = rads/2, rads_div2_sin = sin(rads_div2);
            quaternion q(cos(rads_div2), axis.x()*rads_div2_sin, axis.y()*rads_div2_sin, axis.z()*rads_div2_sin);
            return (q * *this) * q.conjugate();
        }
        
        NIVector vector() const {
            return NIVectorMake(_x, _y, _z);
        }
    };
};

@interface NIMPRQuaternionImpl : NIMPRQuaternion {
    NIMPR::quaternion _quaternion;
}

@end

@implementation NIMPRQuaternionImpl

- (instancetype)initWithQuaternion:(const NIMPR::quaternion&)quaternion {
    if ((self = [super init])) {
        _quaternion = quaternion;
    }
    
    return self;
}

- (instancetype)initWithValues:(CGFloat)x :(CGFloat)y :(CGFloat)z {
    return [self initWithQuaternion:NIMPR::quaternion(x, y, z)];
}

- (instancetype)initWithValues:(CGFloat)w :(CGFloat)x :(CGFloat)y :(CGFloat)z {
    return [self initWithQuaternion:NIMPR::quaternion(w, x, y, z)];
}

- (instancetype)copyWithZone:(NSZone*)zone {
    return [[self.class alloc] initWithQuaternion:_quaternion];
}

- (NIVector)vector {
    return _quaternion.vector();
}

- (void)rotate:(CGFloat)rads axis:(NIVector)axis {
    _quaternion = _quaternion.rotate(axis, rads);
}

- (NSString*)description {
    return [NSString stringWithFormat:@"(%f,%f,%f,%f)", _quaternion.x(), _quaternion.y(), _quaternion.z(), _quaternion.w()];
}

@end

@implementation NIMPRQuaternion

+ (instancetype)quaternion {
    return [[[NIMPRQuaternionImpl alloc] init] autorelease];
}

+ (instancetype)quaternion:(NIVector)vector {
    return [[[NIMPRQuaternionImpl alloc] initWithQuaternion:vector] autorelease];
}

+ (instancetype)quaternion:(CGFloat)x :(CGFloat)y :(CGFloat)z {
    return [[[NIMPRQuaternionImpl alloc] initWithValues:x:y:z] autorelease];
}

- (NIVector)vector {
    [NSException raise:NSGenericException format:@"NIMPRQuaternion is abstract, subclasses must implement -vector"];
    return NIVectorZero;
}

- (void)rotate:(CGFloat)rads axis:(NIVector)axis {
    [NSException raise:NSGenericException format:@"NIMPRQuaternion is abstract, subclasses must implement -rotate:axis:"];
}

@end

