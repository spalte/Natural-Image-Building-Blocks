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

#import "NIStorage.h"
#import "NIStorageCoordinator.h"
#import "NIStorageEntities.h"
#import "NIStorageBox.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIStorage ()

@end

@implementation NIStorage

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
    return NO;
}

- (nullable instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
{
    if ( (self = [super init]) ) {
        _managedObjectContext = [moc retain];
    }
    return self;
}

+ (nullable instancetype)storageForBundle:(NSBundle *)bundle
{
    return [[NIStorageCoordinator sharedStorageCoordinator] storageForBundle:bundle];
}

+ (nullable instancetype)storageForURL:(NSURL *)url
{
    return [[NIStorageCoordinator sharedStorageCoordinator] storageForURL:url];
}

- (BOOL)containsValueForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block BOOL containsValue = NO;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        containsValue = [results count] > 0;
    }];

    return containsValue;
}

- (void)removeValueForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    [self willChangeValueForKey:key];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        for (NIStorageEntity *prevEntity in results) {
            [_managedObjectContext deleteObject:prevEntity];
        }
    }];

    [self didChangeValueForKey:key];
}

- (NSArray<NSString *> *)allKeys
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setResultType:NSDictionaryResultType];
    [fetchRequest setPropertiesToFetch:@[@"key"]];

    NSMutableArray<NSString *>* allKeys = [NSMutableArray array];
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NSDictionary *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        [allKeys addObjectsFromArray:[results valueForKey:@"key"]];
    }];

    return allKeys;
}

- (NSArray<NSString *> *)keysWithPrefix:(NSString *)prefix
{
    if (prefix == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: prefix is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key BEGINSWITH %@", prefix]];

    [fetchRequest setResultType:NSDictionaryResultType];
    [fetchRequest setPropertiesToFetch:@[@"key"]];

    NSMutableArray<NSString *>* prefixKeys = [NSMutableArray array];
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NSDictionary *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        [prefixKeys addObjectsFromArray:[results valueForKey:@"key"]];
    }];

    return prefixKeys;
}

- (nullable id)valueForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block id value = nil;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        for (NIStorageEntity *prevEntity in results) {
            id object = [prevEntity objectValueOfClasses:[NSSet setWithObjects:[NSValue class], [NSNull class], [NSString class], [NSDate class], [NSData class], [NIStorageBox class], nil]];

            if ([object isKindOfClass:[NSValue class]] ||
                [object isKindOfClass:[NSNull class]] ||
                [object isKindOfClass:[NSString class]] ||
                [object isKindOfClass:[NSDate class]] ||
                [object isKindOfClass:[NSData class]]) {

                value = object;
                break;
            } else if ([object isKindOfClass:[NIStorageBox class]]) {
                value = [[(NIStorageBox *)object value] retain];
                break;
            }
        }
    }];

    return [value autorelease];
}

- (void)setValue:(nullable id)value forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    if (value == nil) {
        [self removeValueForKey:key];
    } else if ([value isKindOfClass:[NSString class]]) {
        [self setString:value forKey:key];
    } else if ([value isKindOfClass:[NSNumber class]]) { // should check different types, but this is good enough for all integers of reasonable size
        [self setDouble:[value doubleValue] forKey:key];
    } else if ([value isKindOfClass:[NSDate class]] ||
               [value isKindOfClass:[NSNull class]]) {
        [self setObject:value forKey:key];
    } else if ([value isKindOfClass:[NSData class]]) {
        [self setData:value forKey:key];
    } else if ([value isKindOfClass:[NSValue class]]) {
        if (strcmp([value objCType], @encode(NIVector)) == 0) {
            [self setNIVector:[(NSValue *)value NIVectorValue] forKey:key];
        } else if (strcmp([value objCType], @encode(NIAffineTransform)) == 0) {
            [self setNIAffineTransform:[(NSValue *)value NIAffineTransformValue] forKey:key];
        } else if (strcmp([value objCType], @encode(NIPlane)) == 0) {
            [self setNIPlane:[(NSValue *)value NIPlaneValue] forKey:key];
        } else if (strcmp([value objCType], @encode(NILine)) == 0) {
            [self setNILine:[(NSValue *)value NILineValue] forKey:key];
        } else if (strcmp([value objCType], @encode(NSPoint)) == 0) {
            [self setPoint:[(NSValue *)value pointValue] forKey:key];
        } else if (strcmp([value objCType], @encode(NSSize)) == 0) {
            [self setSize:[(NSValue *)value sizeValue] forKey:key];
        } else if (strcmp([value objCType], @encode(NSRect)) == 0) {
            [self setRect:[(NSValue *)value rectValue] forKey:key];
        }
    }
}


- (void)setData:(NSData *)data forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    if (data == nil) {
        [self removeValueForKey:key];
        return;
    }

    if ([data isKindOfClass:[NSData class]] == NO) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: attempting to set data that is not a kind of NSData class for key: %@", __PRETTY_FUNCTION__, key] userInfo:nil];
    }

    [self willChangeValueForKey:key];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
            err = nil;
        }

        for (NIStorageEntity *prevEntity in results) {
            [_managedObjectContext deleteObject:prevEntity];
        }

        NIStorageEntity *newEntity = [[[NIStorageEntity alloc] initWithData:data insertIntoManagedObjectContext:_managedObjectContext] autorelease];
        newEntity.key = key;
        [_managedObjectContext save:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }
    }];

    [self didChangeValueForKey:key];
}

- (void)setString:(NSString *)string forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    if (string == nil) {
        [self removeValueForKey:key];
        return;
    }

    if ([string isKindOfClass:[NSString class]] == NO) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: attempting to set a string that is not a kind of NSString class for key: %@", __PRETTY_FUNCTION__, key] userInfo:nil];
    }

    [self willChangeValueForKey:key];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
            err = nil;
        }

        for (NIStorageEntity *prevEntity in results) {
            [_managedObjectContext deleteObject:prevEntity];
        }

        NIStorageEntity *newEntity = [[[NIStorageEntity alloc] initWithString:string insertIntoManagedObjectContext:_managedObjectContext] autorelease];
        newEntity.key = key;
        [_managedObjectContext save:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }
    }];

    [self didChangeValueForKey:key];
}

- (void)setDate:(NSDate *)date forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    if (date == nil) {
        [self removeValueForKey:key];
        return;
    }

    if ([date isKindOfClass:[NSDate class]] == NO) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: attempting to set a date that is not a kind of NSDate class for key: %@", __PRETTY_FUNCTION__, key] userInfo:nil];
    }

    [self setObject:date forKey:key];
}

- (void)setObject:(id<NSSecureCoding>)object forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    if (object == nil) {
        [self removeValueForKey:key];
        return;
    }

    [self willChangeValueForKey:key];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
            err = nil;
        }

        for (NIStorageEntity *prevEntity in results) {
            [_managedObjectContext deleteObject:prevEntity];
        }

        NIStorageEntity *newEntity = [[[NIStorageEntity alloc] initWithObject:object insertIntoManagedObjectContext:_managedObjectContext] autorelease];
        newEntity.key = key;
        [_managedObjectContext save:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }
    }];

    [self didChangeValueForKey:key];
}

- (void)setLongLong:(long long)number forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    [self willChangeValueForKey:key];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
            err = nil;
        }

        for (NIStorageEntity *prevEntity in results) {
            [_managedObjectContext deleteObject:prevEntity];
        }

        NIStorageEntity *newEntity = [[[NIStorageEntity alloc] initWithLongLong:number insertIntoManagedObjectContext:_managedObjectContext] autorelease];
        newEntity.key = key;
        [_managedObjectContext save:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }
    }];

    [self didChangeValueForKey:key];
}

- (void)setBool:(BOOL)boolVal forKey:(NSString *)key;
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    [self setLongLong:(long long)boolVal forKey:key];
}

- (void)setInteger:(NSInteger)integer forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    [self setLongLong:(long long)integer forKey:key];
}

- (void)setDouble:(double)realv forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    [self willChangeValueForKey:key];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
            err = nil;
        }

        for (NIStorageEntity *prevEntity in results) {
            [_managedObjectContext deleteObject:prevEntity];
        }

        NIStorageEntity *newEntity = [[[NIStorageEntity alloc] initWithDouble:realv insertIntoManagedObjectContext:_managedObjectContext] autorelease];
        newEntity.key = key;
        [_managedObjectContext save:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }
    }];

    [self didChangeValueForKey:key];
}

- (void)setNIVector:(NIVector)vector forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    [self setObject:[NIStorageBox storageBoxWithVector:vector] forKey:key];
}

- (void)setNIAffineTransform:(NIAffineTransform)transform forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    [self setObject:[NIStorageBox storageBoxWithAffineTransform:transform] forKey:key];
}

- (void)setNIPlane:(NIPlane)plane forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    [self setObject:[NIStorageBox storageBoxWithPlane:plane] forKey:key];
}

- (void)setNILine:(NILine)line forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    [self setObject:[NIStorageBox storageBoxWithLine:line] forKey:key];
}

- (void)setPoint:(NSPoint)point forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    [self setObject:[NIStorageBox storageBoxWithPoint:point] forKey:key];
}

- (void)setSize:(NSSize)size forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    [self setObject:[NIStorageBox storageBoxWithSize:size] forKey:key];
}

- (void)setRect:(NSRect)rect forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    [self setObject:[NIStorageBox storageBoxWithRect:rect] forKey:key];
}

- (nullable NSData *)dataForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block NSData *data = nil;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        if ([results count]) {
            data = [[results[0] dataValue] retain];
        }
    }];

    return [data autorelease];
}

- (nullable NSString *)stringForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block NSString *string = nil;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        if ([results count]) {
            string = [[results[0] stringValue] retain];
        }
    }];

    return [string autorelease];
}

- (nullable NSDate *)dateForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    return [self objectOfClass:[NSDate class] forKey:key];
}

- (nullable id)objectOfClass:(Class)aClass forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block id object = nil;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        if ([results count]) {
            object = [[results[0] objectValueOfClass:aClass] retain];
        }
    }];

    return [object autorelease];
}

- (nullable id)objectOfClasses:(NSSet<Class> *)classes forKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block id object = nil;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        if ([results count]) {
            object = [[results[0] objectValueOfClasses:classes] retain];
        }
    }];

    return [object autorelease];
}

- (long long)longLongForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block long long value = 0;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        if ([results count]) {
            value = [results[0] longLongValue];
        }
    }];

    return value;
}

- (BOOL)boolForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    return (BOOL)[self longLongForKey:key];
}

- (NSInteger)integerForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    return (NSInteger)[self longLongForKey:key];
}

- (double)doubleForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block double value = 0;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        if ([results count]) {
            value = [results[0] doubleValue];
        }
    }];

    return value;
}

- (NIVector)NIVectorForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block NIVector vector = NIVectorZero;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        if ([results count]) {
            NIStorageBox *object = [results[0] objectValueOfClass:[NIStorageBox class]];
            if (object) {
                vector = [object vector];
            }
        }
    }];

    return vector;
}

- (NIAffineTransform)NIAffineTransformForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block NIAffineTransform transform = NIAffineTransformIdentity;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        if ([results count]) {
            NIStorageBox *object = [results[0] objectValueOfClass:[NIStorageBox class]];
            if (object) {
                transform = [object transform];
            }
        }
    }];

    return transform;
}

- (NIPlane)NIPlaneForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block NIPlane plane = NIPlaneInvalid;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        if ([results count]) {
            NIStorageBox *object = [results[0] objectValueOfClass:[NIStorageBox class]];
            if (object) {
                plane = [object plane];
            }
        }
    }];

    return plane;
}

- (NILine)NILineForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block NILine line = NILineInvalid;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        if ([results count]) {
            NIStorageBox *object = [results[0] objectValueOfClass:[NIStorageBox class]];
            if (object) {
                line = [object line];
            }
        }
    }];

    return line;
}

- (NSPoint)pointForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block NSPoint point = NSZeroPoint;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        if ([results count]) {
            NIStorageBox *object = [results[0] objectValueOfClass:[NIStorageBox class]];
            if (object) {
                point = [object point];
            }
        }
    }];

    return point;
}

- (NSSize)sizeForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block NSSize size = NSZeroSize;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        if ([results count]) {
            NIStorageBox *object = [results[0] objectValueOfClass:[NIStorageBox class]];
            if (object) {
                size = [object size];
            }
        }
    }];

    return size;
}

- (NSRect)rectForKey:(NSString *)key
{
    if (key == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: key is nil object", __PRETTY_FUNCTION__] userInfo:nil];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    __block NSRect rect = NSZeroRect;
    [_managedObjectContext performBlockAndWait:^{
        NSError *err = nil;
        NSArray<NIStorageEntity *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];
        if (err) {
            NSLog(@"*** %s: %@", __PRETTY_FUNCTION__, err);
        }

        if ([results count]) {
            NIStorageBox *object = [results[0] objectValueOfClass:[NIStorageBox class]];
            if (object) {
                rect = [object rect];
            }
        }
    }];

    return rect;
}


@end

NS_ASSUME_NONNULL_END
