//
//  CPRMPRQuaternion.h
//  CPRMPR
//
//  Created by Alessandro Volz on 5/20/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <OsiriXAPI/N3Geometry.h>

namespace cprmpr {
    class quaternion {
        CGFloat _w, _x, _y, _z;
        
        CGFloat length() const { return sqrtf( powf(_w, 2) + powf(_x, 2) + powf(_y, 2) + powf(_z, 2) ); }
        void normalize() { CGFloat l = length(); if (l) { _w /= l; _x /= l; _y /= l; _z /= l; } }
        quaternion conjugate() const { return quaternion(_w, -_x, -_y, -_z); }
        
    public:
        quaternion(CGFloat w, CGFloat x, CGFloat y, CGFloat z) : _w(w), _x(x), _y(y), _z(z) { normalize(); }
        quaternion() : quaternion(1, 0, 0, 0) {}
        quaternion(const quaternion& q) : quaternion(q.w(), q.x(), q.y(), q.z()) {}
        quaternion(const N3Vector& v) : quaternion(0, v.x, v.y, v.z) {}
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
        
        N3Vector vector() const {
            return N3VectorMake(_x, _y, _z);
        }
    };
};

@interface CPRMPRQuaternion : NSObject {
    cprmpr::quaternion _quaternion;
}

+ (instancetype)quaternion;
+ (instancetype)quaternion:(const cprmpr::quaternion&)quaternion;
+ (instancetype)quaternion:(CGFloat)x :(CGFloat)y :(CGFloat)z;

- (instancetype)initWithQuaternion:(const cprmpr::quaternion&)quaternion;
- (instancetype)initWithValues:(CGFloat)x :(CGFloat)y :(CGFloat)z;
- (instancetype)initWithValues:(CGFloat)w :(CGFloat)x :(CGFloat)y :(CGFloat)z;

- (const cprmpr::quaternion&)quaternion;
- (N3Vector)vector;

- (void)rotate:(CGFloat)rads axis:(N3Vector)axis;
- (N3Vector)rotated:(CGFloat)rads axis:(N3Vector)axis;

@end