//  Copyright (c) 2016 Spaltenstein Natural Image
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>

#import "NIGeometry.h"

typedef NS_ENUM(NSUInteger, NIStorageBoxType) {
    NIStorageBoxVector = 0,
    NIStorageBoxAffineTransform,
    NIStorageBoxPlane,
    NIStorageBoxLine
};


@interface NIStorageBox : NSObject <NSSecureCoding>
{
    NIStorageBoxType _type;
    NIVector _vector;
    NIAffineTransform _transform;
    NIPlane _plane;
    NILine _line;
}

+ (instancetype)storageBoxWithVector:(NIVector)vector;
+ (instancetype)storageBoxWithAffineTransform:(NIAffineTransform)transform;
+ (instancetype)storageBoxWithPlane:(NIPlane)plane;
+ (instancetype)storageBoxWithLine:(NILine)line;

@property (nonatomic, readonly, assign) NIStorageBoxType type;
@property (nonatomic, readonly, assign) NIVector vector;
@property (nonatomic, readonly, assign) NIAffineTransform transform;
@property (nonatomic, readonly, assign) NIPlane plane;
@property (nonatomic, readonly, assign) NILine line;

- (id)value;

@end
