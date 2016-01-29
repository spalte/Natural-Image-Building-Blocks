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

#import "NIStorageEntities.h"
#import "NIStorageCoordinator.h"

@interface NIStorageInt64Entity : NIStorageEntity
@property (nonatomic, assign) int64_t int64;
@end

@interface NIStorageDoubleEntity : NIStorageEntity
@property (nonatomic, assign) double realv;
@end

@interface NIStorageStringEntity : NIStorageEntity
@property (nonnull, nonatomic, retain) NSString *string;
@end

@interface NIStorageSmallDataEntity : NIStorageEntity
@property (nonnull, nonatomic, retain) NSData *data;
@end

@interface NIStorageLargeDataEntity : NIStorageEntity
@property (nonnull, nonatomic, retain) NSString *relativeURL;
@end

@interface NIStorageObjectEntity : NIStorageEntity
@property (nonnull, nonatomic, retain) NSData *encodedObject;
@end


@implementation NIStorageEntity
@dynamic key;

@dynamic stringValue;
@dynamic dataValue;
@dynamic doubleValue;
@dynamic longLongValue;



- (__kindof NIStorageEntity *)initWithString:(nonnull NSString *)string insertIntoManagedObjectContext:(NSManagedObjectContext *)context
{
    NSManagedObjectModel *mom = [NIStorageCoordinator managedObjectModel];

    NIStorageStringEntity *entity = [[NIStorageStringEntity alloc] initWithEntity:[[mom entitiesByName] objectForKey:@"NIStorageStringEntity"] insertIntoManagedObjectContext:context];
    entity.string = string;

    [self autorelease];
    return entity;
}

- (__kindof NIStorageEntity *)initWithData:(nonnull NSData *)data insertIntoManagedObjectContext:(NSManagedObjectContext *)context;
{
    NSManagedObjectModel *mom = [NIStorageCoordinator managedObjectModel];

    NIStorageSmallDataEntity *entity = [[NIStorageSmallDataEntity alloc] initWithEntity:[[mom entitiesByName] objectForKey:@"NIStorageSmallDataEntity"] insertIntoManagedObjectContext:context];
    entity.data = data;

    [self autorelease];
    return entity;
}

- (__kindof NIStorageEntity *)initWithObject:(nonnull id<NSSecureCoding>)object insertIntoManagedObjectContext:(NSManagedObjectContext *)context
{
    NSManagedObjectModel *mom = [NIStorageCoordinator managedObjectModel];

    NIStorageObjectEntity *entity = [[NIStorageObjectEntity alloc] initWithEntity:[[mom entitiesByName] objectForKey:@"NIStorageObjectEntity"] insertIntoManagedObjectContext:context];

    NSMutableData *encodedObject = [NSMutableData data];

    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:encodedObject];
    [archiver setRequiresSecureCoding:YES];
    [archiver encodeObject:object forKey:@"rootObject"];
    [archiver finishEncoding];

    entity.encodedObject = encodedObject;

    [archiver release];

    [self autorelease];
    return entity;
}

- (__kindof NIStorageEntity *)initWithDouble:(double)doubleValue insertIntoManagedObjectContext:(NSManagedObjectContext *)context
{
    NSManagedObjectModel *mom = [NIStorageCoordinator managedObjectModel];

    NIStorageDoubleEntity *entity = [[NIStorageDoubleEntity alloc] initWithEntity:[[mom entitiesByName] objectForKey:@"NIStorageDoubleEntity"] insertIntoManagedObjectContext:context];
    entity.realv = doubleValue;

    [self autorelease];
    return entity;
}

- (__kindof NIStorageEntity *)initWithLongLong:(long long)longLongValue insertIntoManagedObjectContext:(NSManagedObjectContext *)context
{
    NSManagedObjectModel *mom = [NIStorageCoordinator managedObjectModel];

    NIStorageInt64Entity *entity = [[NIStorageInt64Entity alloc] initWithEntity:[[mom entitiesByName] objectForKey:@"NIStorageInt64Entity"] insertIntoManagedObjectContext:context];
    entity.int64 = longLongValue;

    [self autorelease];
    return entity;
}

- (NSString *)stringValue
{
    NSAssert(NO, @"NIStorageEntity is an abstract class");
    return nil;
}

- (NSData *)dataValue
{
    NSAssert(NO, @"NIStorageEntity is an abstract class");
    return nil;
}

- (double)doubleValue
{
    NSAssert(NO, @"NIStorageEntity is an abstract class");
    return 0;
}

- (long long)longLongValue
{
    NSAssert(NO, @"NIStorageEntity is an abstract class");
    return 0;
}

- (id)objectValueOfClass:(Class)objectClass
{
    return [self objectValueOfClasses:[NSSet setWithObject:objectClass]];
}

- (id)objectValueOfClasses:(NSSet<Class> *)classes
{
    return nil;
}

@end



@implementation NIStorageInt64Entity
@dynamic int64;

- (NSString *)stringValue
{
    return [@(self.int64) stringValue];
}

- (NSData *)dataValue
{
    return nil;
}

- (double)doubleValue
{
    return (double)self.int64;
}

- (long long)longLongValue
{
    return (long long)self.int64;
}

- (id)objectValueOfClasses:(NSSet<Class> *)classes
{
    if ([classes containsObject:[NSNumber class]]) {
        return @(self.int64);
    } else if ([classes containsObject:[NSString class]]) {
        return [@(self.int64) stringValue];
    }

    return nil;
}

@end

@implementation NIStorageDoubleEntity
@dynamic realv;

- (NSString *)stringValue
{
    return [@(self.realv) stringValue];
}

- (NSData *)dataValue
{
    return nil;
}

- (double)doubleValue
{
    return self.realv;
}

- (long long)longLongValue
{
    return (long long)self.realv;
}

- (id)objectValueOfClasses:(NSSet<Class> *)classes
{
    if ([classes containsObject:[NSNumber class]]) {
        return @(self.realv);
    } else if ([classes containsObject:[NSString class]]) {
        return [@(self.realv) stringValue];
    }

    return nil;
}

@end

@implementation NIStorageStringEntity
@dynamic string;

- (NSString *)stringValue
{
    return self.string;
}

- (NSData *)dataValue
{
    return nil;
}

- (double)doubleValue
{
    return [self.string doubleValue];
}

- (long long)longLongValue
{
    return [self.string longLongValue];
}

- (id)objectValueOfClasses:(NSSet<Class> *)classes
{
    if ([classes containsObject:[NSString class]]) {
        return self.string;
    } else if ([classes containsObject:[NSNumber class]]) {
        NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        return [formatter numberFromString:self.string];
    }

    return nil;
}

@end

@implementation NIStorageSmallDataEntity
@dynamic data;

- (NSString *)stringValue
{
    return nil;
}

- (NSData *)dataValue
{
    return self.data;
}

- (double)doubleValue
{
    return 0;
}

- (long long)longLongValue
{
    return 0;
}

- (id)objectValueOfClasses:(NSSet<Class> *)classes
{
    if ([classes containsObject:[NSData class]]) {
        return self.data;
    }

    return nil;
}


@end

@implementation NIStorageLargeDataEntity
@dynamic relativeURL;

- (NSString *)stringValue
{
    return nil;
}

- (NSData *)dataValue
{
    return nil;
}

- (double)doubleValue
{
    return 0;
}

- (long long)longLongValue
{
    return 0;
}

@end

@implementation NIStorageObjectEntity
@dynamic encodedObject;

- (NSString *)stringValue
{
    id objectValue = [self objectValueOfClasses:[NSSet setWithObjects:[NSString class], [NSValue class], nil]];

    if ([objectValue isKindOfClass:[NSString class]]) {
        return (NSString *)objectValue;
    } else if ([objectValue respondsToSelector:@selector(stringValue)]) {
        return [objectValue performSelector:@selector(stringValue)];
    }

    return nil;
}

- (NSData *)dataValue
{
    NSData* objectValue = [self objectValueOfClass:[NSData class]];

    if ([objectValue isKindOfClass:[NSData class]]) {
        return (NSData *)objectValue;
    }

    return nil;
}

- (id)objectValueOfClass:(Class)objectClass
{
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:self.encodedObject];
    [unarchiver setRequiresSecureCoding:YES];

    id<NSSecureCoding>objectValue = nil;
    @try {
        objectValue = [unarchiver decodeObjectOfClass:objectClass forKey:@"rootObject"];
    }
    @catch (NSException *exception) {
    }

    [unarchiver release];
    return objectValue;
}

- (id)objectValueOfClasses:(NSSet<Class> *)classes;
{
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:self.encodedObject];
    [unarchiver setRequiresSecureCoding:YES];

    id<NSSecureCoding>objectValue = nil;
    @try {
        objectValue = [unarchiver decodeObjectOfClasses:classes forKey:@"rootObject"];
    }
    @catch (NSException *exception) {
    }

    [unarchiver release];
    return objectValue;
}

- (double)doubleValue
{
    id objectValue = [self objectValueOfClasses:[NSSet setWithObjects:[NSString class], [NSValue class], nil]];

    if ([objectValue respondsToSelector:@selector(doubleValue)]) {
        NSInvocation *doubleValueInvocation = [NSInvocation invocationWithMethodSignature:[NSNumber methodSignatureForSelector:@selector(doubleValue)]];
        [doubleValueInvocation invokeWithTarget:objectValue];
        double doubleValue = 0;
        NSAssert([[doubleValueInvocation methodSignature] methodReturnLength] == sizeof(double), @"doubleValue has invalid return length");
        [doubleValueInvocation getReturnValue:&doubleValue];
        return doubleValue;
    }

    return 0;
}

- (long long)longLongValue
{
    id objectValue = [self objectValueOfClasses:[NSSet setWithObjects:[NSString class], [NSValue class], nil]];

    if ([objectValue respondsToSelector:@selector(longLongValue)]) {
        NSInvocation *longLongValueInvocation = [NSInvocation invocationWithMethodSignature:[NSNumber methodSignatureForSelector:@selector(longLongValue)]];
        [longLongValueInvocation invokeWithTarget:objectValue];
        long long longLongValue = 0;
        NSAssert([[longLongValueInvocation methodSignature] methodReturnLength] == sizeof(long long), @"longLongValue has invalid return length");
        [longLongValueInvocation getReturnValue:&longLongValue];
        return longLongValue;
    }

    return 0;
}


@end









