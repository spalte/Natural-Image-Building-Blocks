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

NS_ASSUME_NONNULL_BEGIN

@interface NIStorage : NSObject
{
    NSManagedObjectContext* _managedObjectContext;
}

+ (nullable instancetype)storageForBundle:(NSBundle *)bundle;
+ (nullable instancetype)storageForURL:(NSURL *)url;

- (BOOL)containsValueForKey:(NSString *)key;
- (void)removeValueForKey:(NSString *)key;

- (NSArray<NSString *> *)allKeys;
- (NSArray<NSString *> *)keysWithPrefix:(NSString *)prefix;

- (nullable id)valueForKey:(NSString *)key;
- (void)setValue:(nullable id)value forKey:(NSString *)key;

- (void)setData:(NSData *)data forKey:(NSString *)key;
- (void)setString:(NSString *)string forKey:(NSString *)key;
- (void)setDate:(NSDate *)date forKey:(NSString *)key;
- (void)setObject:(id<NSSecureCoding>)object forKey:(NSString *)aKey;
- (void)setInteger:(NSInteger)integer forKey:(NSString *)key;
- (void)setLongLong:(long long)number forKey:(NSString *)key;
- (void)setDouble:(double)realv forKey:(NSString *)key;

- (void)setNIVector:(NIVector)vector forKey:(NSString *)key;
- (void)setNIAffineTransform:(NIAffineTransform)transform forKey:(NSString *)key;
- (void)setNIPlane:(NIPlane)plane forKey:(NSString *)key;
- (void)setNILine:(NILine)line forKey:(NSString *)key;

- (void)setPoint:(NSPoint)point forKey:(NSString *)key;
- (void)setSize:(NSSize)size forKey:(NSString *)key;
- (void)setRect:(NSRect)rect forKey:(NSString *)key;

- (nullable NSData *)dataForKey:(NSString *)key;
- (nullable NSString *)stringForKey:(NSString *)key;
- (nullable NSDate *)dateForKey:(NSString *)key;
- (nullable id)objectOfClass:(Class)aClass forKey:(NSString *)key;
- (nullable id)objectOfClasses:(NSSet<Class> *)classes forKey:(NSString *)key;
- (long long)longLongForKey:(NSString *)key;
- (NSInteger)integerForKey:(NSString *)key;
- (double)doubleForKey:(NSString *)key;

- (NIVector)NIVectorForKey:(NSString *)key;
- (NIAffineTransform)NIAffineTransformForKey:(NSString *)key;
- (NIPlane)NIPlaneForKey:(NSString *)key;
- (NILine)NILineForKey:(NSString *)key;

- (NSPoint)pointForKey:(NSString *)key;
- (NSSize)sizeForKey:(NSString *)key;
- (NSRect)rectForKey:(NSString *)key;


// working with subdirectories
//- (NIStorage *)storageForKeyPath:(NSString *)keyPath;
//- (BOOL)containsValueForKeyPath:(NSString *)keyPath;
//
//- (void)setData:(NSData *)data forKeyPath:(NSString *)keyPath;
//- (void)setString:(NSString *)string forKeyPath:(NSString *)keyPath;
//- (void)setObject:(id<NSSecureCoding>)object forKeyPath:(NSString *)keyPath;
//- (void)setInt64:(int64_t)integer forKeyPath:(NSString *)keyPath;
//- (void)setDouble:(double)realv forKeyPath:(NSString *)keyPath;
//
//- (NSData *)dataForKeyPath:(NSString *)keyPath;
//- (NSString *)stringForKeyPath:(NSString *)keyPath;
//- (id)objectOfClass:(Class)aClass forKeyPath:(NSString *)keyPath;
//- (int64_t)int64ForKeyPath:(NSString *)keyPath;
//- (double)doubleForKeyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END

