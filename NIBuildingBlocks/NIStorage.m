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

@interface NIStorage ()

@end

@implementation NIStorage


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
{
    if ( (self = [super init]) ) {
        _managedObjectContext = [moc retain];
    }
    return self;
}

+ (instancetype)storageForBundle:(NSBundle *)bundle
{
    return [[NIStorageCoordinator sharedStorageCoordinator] storageForBundle:bundle];
}

+ (instancetype)storageForURL:(NSURL *)url
{
    return [[NIStorageCoordinator sharedStorageCoordinator] storageForURL:url];
}

- (BOOL)containsValueForKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    return [results count];
}

- (void)removeValueForKey:(nonnull NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        [_managedObjectContext deleteObject:prevEntity];
    }
}

- (nullable id)valueForKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        id object = [prevEntity objectValueOfClasses:[NSSet setWithObjects:[NSValue class], [NSString class], [NIStorageBox class], nil]];

        if ([object isKindOfClass:[NSValue class]] ||
            [object isKindOfClass:[NSString class]]) {

            return object;
        } else if ([object isKindOfClass:[NIStorageBox class]]) {
            return [(NIStorageBox *)object value];
        }
    }

    return nil;;
}

- (void)setValue:(nullable id)value forKey:(NSString *)key
{
    if (value == nil) {
        [self removeValueForKey:key];
    } else if ([value isKindOfClass:[NSString class]]) {
        [self setString:value forKey:key];
    } else if ([value isKindOfClass:[NSNumber class]]) { // should check different types, but this is good enough for all integers of reasonable size
        [self setDouble:[value doubleValue] forKey:key];
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
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        [_managedObjectContext deleteObject:prevEntity];
    }

    NIStorageEntity *newEntity = [[[NIStorageEntity alloc] initWithData:data insertIntoManagedObjectContext:_managedObjectContext] autorelease];
    newEntity.key = key;
    [_managedObjectContext save:&err];
}

- (void)setString:(NSString *)string forKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        [_managedObjectContext deleteObject:prevEntity];
    }

    NIStorageEntity *newEntity = [[[NIStorageEntity alloc] initWithString:string insertIntoManagedObjectContext:_managedObjectContext] autorelease];
    newEntity.key = key;
    [_managedObjectContext save:&err];
}

- (void)setObject:(id<NSSecureCoding>)object forKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        [_managedObjectContext deleteObject:prevEntity];
    }

    NIStorageEntity *newEntity = [[[NIStorageEntity alloc] initWithObject:object insertIntoManagedObjectContext:_managedObjectContext] autorelease];
    newEntity.key = key;
    [_managedObjectContext save:&err];
}

- (void)setLongLong:(long long)number forKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        [_managedObjectContext deleteObject:prevEntity];
    }

    NIStorageEntity *newEntity = [[[NIStorageEntity alloc] initWithLongLong:number insertIntoManagedObjectContext:_managedObjectContext] autorelease];
    newEntity.key = key;
    [_managedObjectContext save:&err];
}

- (void)setInteger:(NSInteger)integer forKey:(NSString *)key
{
    [self setLongLong:(long long)integer forKey:key];
}

- (void)setDouble:(double)realv forKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        [_managedObjectContext deleteObject:prevEntity];
    }

    NIStorageEntity *newEntity = [[[NIStorageEntity alloc] initWithDouble:realv insertIntoManagedObjectContext:_managedObjectContext] autorelease];
    newEntity.key = key;
    [_managedObjectContext save:&err];
}

- (void)setNIVector:(NIVector)vector forKey:(NSString *)key
{
    [self setObject:[NIStorageBox storageBoxWithVector:vector] forKey:key];
}

- (void)setNIAffineTransform:(NIAffineTransform)transform forKey:(NSString *)key
{
    [self setObject:[NIStorageBox storageBoxWithAffineTransform:transform] forKey:key];
}

- (void)setNIPlane:(NIPlane)plane forKey:(NSString *)key
{
    [self setObject:[NIStorageBox storageBoxWithPlane:plane] forKey:key];
}

- (void)setNILine:(NILine)line forKey:(NSString *)key
{
    [self setObject:[NIStorageBox storageBoxWithLine:line] forKey:key];
}

- (void)setPoint:(NSPoint)point forKey:(NSString *)key
{
    [self setObject:[NIStorageBox storageBoxWithPoint:point] forKey:key];
}

- (void)setSize:(NSSize)size forKey:(NSString *)key
{
    [self setObject:[NIStorageBox storageBoxWithSize:size] forKey:key];
}

- (void)setRect:(NSRect)rect forKey:(NSString *)key
{
    [self setObject:[NIStorageBox storageBoxWithRect:rect] forKey:key];
}

- (NSData *)dataForKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        return [prevEntity dataValue];
    }
    return nil;
}

- (NSString *)stringForKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        return [prevEntity stringValue];
    }

    return nil;
}

- (id)objectOfClass:(Class)aClass forKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        id object = [prevEntity objectValueOfClass:aClass];
        if (object) {
            return object;
        }
    }

    return nil;
}

- (long long)longLongForKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        return [prevEntity longLongValue];
    }

    return 0;
}

- (NSInteger)integerForKey:(NSString *)key
{
    return (NSInteger)[self longLongForKey:key];
}

- (double)doubleForKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        return [prevEntity doubleValue];
    }

    return 0;
}

- (NIVector)NIVectorForKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        NIStorageBox *object = [prevEntity objectValueOfClass:[NIStorageBox class]];
        if (object) {
            return [object vector];
        }
    }

    return NIVectorZero;
}

- (NIAffineTransform)NIAffineTransformForKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        NIStorageBox *object = [prevEntity objectValueOfClass:[NIStorageBox class]];
        if (object) {
            return [object transform];
        }
    }

    return NIAffineTransformIdentity;
}

- (NIPlane)NIPlaneForKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        NIStorageBox *object = [prevEntity objectValueOfClass:[NIStorageBox class]];
        if (object) {
            return [object plane];
        }
    }

    return NIPlaneInvalid;
}

- (NILine)NILineForKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        NIStorageBox *object = [prevEntity objectValueOfClass:[NIStorageBox class]];
        if (object) {
            return [object line];
        }
    }

    return NILineInvalid;
}

- (NSPoint)pointForKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        NIStorageBox *object = [prevEntity objectValueOfClass:[NIStorageBox class]];
        if (object) {
            return [object point];
        }
    }

    return NSZeroPoint;
}

- (NSSize)sizeForKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        NIStorageBox *object = [prevEntity objectValueOfClass:[NIStorageBox class]];
        if (object) {
            return [object size];
        }
    }

    return NSZeroSize;
}

- (NSRect)rectForKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        NIStorageBox *object = [prevEntity objectValueOfClass:[NIStorageBox class]];
        if (object) {
            return [object rect];
        }
    }

    return NSZeroRect;
}


@end
