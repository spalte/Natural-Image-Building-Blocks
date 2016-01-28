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

#import "NIStorageCoordinator.h"
#import "NIStorage.h"
#import "NIStorage+Private.h"

@interface NIStorageCoordinator ()
@end

@implementation NIStorageCoordinator

+ (instancetype)sharedStorageCoordinator
{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[super alloc] init];
    });
    return shared;
}

+ (NSManagedObjectModel *)managedObjectModel
{
    return [[NIStorageCoordinator sharedStorageCoordinator] managedObjectModel];
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel == nil) {
        NSURL *modelURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"NIStorageModel" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        NSAssert(_managedObjectModel != nil, @"Error initializing Managed Object Model");
    }

    return _managedObjectModel;
}

- (nullable NIStorage*)storageForBundle:(NSBundle *)bundle
{
    return [self storageForURL:[self storageURLForBundle:bundle]];
}

- (nullable NIStorage *)storageForURL:(NSURL *)storageURL
{
    return [self storageForStorageURL:storageURL];
}

- (NIStorage *)storageForStorageURL:(NSURL *)url
{
    if (_storages == nil) {
        _storages = [[NSMutableDictionary alloc] init];
    }

    NIStorage *storage = [_storages objectForKey:url];

    if (storage) {
        return storage;
    }

    // create the URL
    NSError *err;

    if ([NSFileManager.defaultManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&err] == NO) {
        NSAssert(0, @"couldn't create persistentStore directory");
    }

    NSURL *storeURL = [url URLByAppendingPathComponent:@"storage.sqlite"];

    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [moc setPersistentStoreCoordinator:psc];

    NSPersistentStore *store = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:0 error:&err];
    NSAssert2(store != nil, @"Error initializing PSC: %@\n%@", [err localizedDescription], [err userInfo]);

    storage = [[NIStorage alloc] initWithManagedObjectContext:moc];
    [_storages setObject:storage forKey:url];
    return storage;
}


- (NSURL *)storageURLForBundle:(NSBundle *)bundle
{
    NSURL *applicationStorageURL = nil;

    if ([[[NSBundle mainBundle] bundleIdentifier] hasPrefix:@"com.rossetantoine.osirix"]) {
        NSString *appSupport = @"Library/Application Support/OsiriX/";
        applicationStorageURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:appSupport]];
    } else if ([[[NSBundle mainBundle] bundleIdentifier] hasPrefix:@"com.horosproject.horos"]) {
        NSString *appSupport = @"Library/Application Support/Horos/";
        applicationStorageURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:appSupport]];
    } else {
        NSError *err;
        NSURL *applicationSupportURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&err];
        applicationStorageURL = [applicationSupportURL URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier] isDirectory:YES];
    }

    NSString *bundleIdentifier = [bundle bundleIdentifier];
    NSURL *bundleStorageURL = [applicationStorageURL URLByAppendingPathComponent:bundleIdentifier isDirectory:YES];

    return bundleStorageURL;
}

@end
