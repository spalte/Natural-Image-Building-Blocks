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
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface NIStorageEntity : NSManagedObject

- (__kindof NIStorageEntity *)initWithString:(NSString *)string insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context;
- (__kindof NIStorageEntity *)initWithData:(NSData *)data insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context;
- (__kindof NIStorageEntity *)initWithObject:(id<NSSecureCoding>)object insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context;
- (__kindof NIStorageEntity *)initWithDouble:(double)doubleValue insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context;
- (__kindof NIStorageEntity *)initWithLongLong:(long long)longLongValue insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context;


@property (nonnull, nonatomic, retain) NSString *key;



@property (nullable, readonly, retain) NSString* stringValue;
@property (nullable, readonly, retain) NSData* dataValue;

- (id)objectValueOfClass:(Class)objectClass;
- (id)objectValueOfClasses:(NSSet<Class> *)classes;

@property (readonly, assign) double doubleValue;
@property (readonly, assign) long long longLongValue;

@end


NS_ASSUME_NONNULL_END