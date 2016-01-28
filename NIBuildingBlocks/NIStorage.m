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

- (void)setData:(NSData *)data forKey:(NSString *)key
{
    NSError *err;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NIStorageEntity"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];

    NSArray *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&err];

    for (NIStorageEntity *prevEntity in results) {
        [_managedObjectContext deleteObject:prevEntity];
    }

    NIStorageEntity *newEntity = [[NIStorageEntity alloc] initWithData:data insertIntoManagedObjectContext:_managedObjectContext];
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

    NIStorageEntity *newEntity = [[NIStorageEntity alloc] initWithString:string insertIntoManagedObjectContext:_managedObjectContext];
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

    NIStorageEntity *newEntity = [[NIStorageEntity alloc] initWithObject:object insertIntoManagedObjectContext:_managedObjectContext];
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

    NIStorageEntity *newEntity = [[NIStorageEntity alloc] initWithLongLong:number insertIntoManagedObjectContext:_managedObjectContext];
    newEntity.key = key;
    [_managedObjectContext save:&err];
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

    NIStorageEntity *newEntity = [[NIStorageEntity alloc] initWithDouble:realv insertIntoManagedObjectContext:_managedObjectContext];
    newEntity.key = key;
    [_managedObjectContext save:&err];
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
        id object = [prevEntity objectValue];
        if ([object isKindOfClass:aClass]) {
            return [prevEntity objectValue];
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



//
//@synthesize location = _location;
//
//- (instancetype)initWithBundle:(NSBundle*)bundle {
//    return [self initWithLocation:[self.class defaultLocationForBundle:bundle]];
//}
//
//- (instancetype)initWithLocation:(NSURL*)location {
//    if (!(self = [super init]))
//        return nil;
//    
//    self.location = location;
//    
//    return self;
//}
//
//- (void)dealloc {
//    self.location = nil;
//    [super dealloc];
//}
//
//- (NSURL*)directoryForKey:(NSString*)keyPath {
//    return [self directoryForKey:keyPath create:YES];
//}
//
//- (NSURL*)directoryForKey:(NSString*)keyPath create:(BOOL)create {
//    if (!keyPath)
//        return nil;
//    
//    NSMutableArray* keyComponents = [NSMutableArray array];
//    size_t ib = 0;
//    for (size_t i = 1; i < keyPath.length; ++i)
//        if ([keyPath characterAtIndex:i] == '.' && [keyPath characterAtIndex:i-1] != '\\') {
//            [keyComponents addObject:[keyPath substringWithRange:NSMakeRange(ib, i-ib)]];
//            ib = i+1;
//        }
//    if (ib != keyPath.length)
//        [keyComponents addObject:[keyPath substringWithRange:NSMakeRange(ib, keyPath.length-ib)]];
//    
//    NSURL* url = self.location;
//    for (NSString* keyComponent in keyComponents)
//        url = [url URLByAppendingPathComponent:[keyComponent stringByReplacingOccurrencesOfString:@"\\." withString:@"."] isDirectory:YES];
//    
//    if (create)
//        [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:NULL];
//    
//    return url;
//}
//
//+ (NSURL*)defaultLocationForBundle:(NSBundle*)bundle {
//    // find the NIStorageLocators
//    Protocol* storageLocatorProtocol = NSProtocolFromString(@"NIStorageLocator"); // TODO: Is there a better way to obtain this Protocol*?
//    int count = objc_getClassList(NULL, 0);
//    Class c[count]; objc_getClassList(c, count);
//    __GENERIC(NSMutableArray, Class)* NIStorageLocators = [NSMutableArray array];
//    for (int i = 0; i < count; ++i) {
//        if (class_conformsToProtocol(c[i], storageLocatorProtocol))
//            [NIStorageLocators addObject:c[i]];
//    }
//    
//    [NIStorageLocators sortUsingComparator:^NSComparisonResult(Class c1, Class c2) { // prioritize classes inside the bundle argument
//        NSBundle *b1 = [NSBundle bundleForClass:c1], *b2 = [NSBundle bundleForClass:c2];
//        if (b1 == b2) return NSOrderedSame;
//        if (b1 == bundle) return NSOrderedAscending;
//        if (b2 == bundle) return NSOrderedDescending;
//        return NSOrderedSame;
//    }];
//    
//    __GENERIC(NSMutableArray, NSBundle*)* bundles = [NSMutableArray arrayWithObject:NSBundle.mainBundle];
//    if (bundle && ![bundles containsObject:bundle])
//        [bundles addObject:bundle];
//    
//    static NSString* const CFBundleName = @"CFBundleName";
//    NSError* err = nil;
//    
//    NSURL* dir = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&err];
//    if (err)
//        @throw [NSException exceptionWithName:NSGenericException reason:@"Couldn't determine Application Support directory location" userInfo:@{ NSUnderlyingErrorKey: err }];
//    
//    for (NSBundle* bundle in bundles) {
//        NSURL* bundleDir = nil;
//        
//        // locators method
//        
//        for (Class c in NIStorageLocators)
//            @try {
//                NSURL* ldir = [c NIStorageDefaultLocationForBundle:bundle];
//                if (ldir) {
//                    bundleDir = ldir;
//                    break;
//                }
//            } @catch (...) {
//                // do nothing
//            }
//        
//        // default method
//        
//        if (!bundleDir) {
//            __GENERIC(NSMutableArray, NSString*)* sdirs = [NSMutableArray array]; // regarding Library/Application Support, Apple switched their recommendation to BundleIdentifier instead of the application name a while ago. According to them all new apps should use the bundle identifier.
//            [sdirs addObject:bundle.bundleIdentifier];
//            NSString* bundleName = bundle.infoDictionary[CFBundleName];
//            if (bundleName.length)
//                [sdirs addObject:bundleName];
//            else [sdirs addObject:[[bundle.bundleURL lastPathComponent] stringByDeletingPathExtension]];
//
//            for (NSString* sdir in sdirs) {
//                NSURL* sdirDir = [dir URLByAppendingPathComponent:sdir isDirectory:YES];
//                if ([sdirDir checkPromisedItemIsReachableAndReturnError:NULL]) {
//                    bundleDir = sdirDir;
//                    break;
//                }
//            }
//            
//            if (!bundleDir) {
//                [NSFileManager.defaultManager createDirectoryAtURL:(bundleDir = [dir URLByAppendingPathComponent:sdirs[0] isDirectory:YES]) withIntermediateDirectories:YES attributes:nil error:&err];
//                if (err)
//                    @throw [NSException exceptionWithName:NSGenericException reason:@"Couldn't create Application Support directory" userInfo:@{ NSUnderlyingErrorKey: err }];
//            }
//        }
//
//        dir = bundleDir;
//    }
//    
//    return dir;
//}

@end
