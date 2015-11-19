//
//  NIDatabase.m
//  Stag
//
//  Created by Alessandro Volz on 3/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIDatabase.h"
#import "NIManagedObjectContext.h"
#import <objc/runtime.h>
#if TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#elif TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@interface NIDatabase ()

@property (readwrite, strong, nonatomic) NSManagedObjectContext* managedObjectContext;

@property (retain) __kindof NIDatabase* parent;
@property (retain) __kindof NIDatabaseFamilyData* familyData;

@end

@interface NIDatabaseFamilyData ()

@property (retain) NSURL *URL, *momURL;
@property BOOL momSaved;

@end

@implementation NIDatabase

@synthesize managedObjectContext = _managedObjectContext;
@synthesize parent = _parent, familyData = _familyData;

+ (Class)NIDatabaseFamilyDataClass {
    return NIDatabaseFamilyData.class;
}

+ (NSURL*)model {
    return nil;
}

- (void)performBlock:(void (^)())block {
    [self.managedObjectContext performBlock:block];
}

- (void)performBlockAndWait:(void (^)())block {
    [self.managedObjectContext performBlockAndWait:block];
}

- (id)initWithURL:(NSURL*)url {
    return [self initWithURL:url model:nil];
}

- (id)initWithURL:(NSURL*)url model:(NSURL*)murl {
    if ((self = [super init])) {
        self.familyData = [[[NIDatabaseFamilyData alloc] init] autorelease];
        
        if (!murl)
            for (Class class = self.class; class; class = class.superclass)
                if (class_getClassMethod(class, @selector(model)))
                    if ((murl = [class model]))
                        break;
        
        NSNumber* isDir;
        if ([murl getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:NULL]) {
            if (isDir.boolValue) {
                NSDictionary* versionInfo = [NSDictionary dictionaryWithContentsOfURL:[murl URLByAppendingPathComponent:@"VersionInfo.plist"]];
                NSString* currentVersionName = versionInfo[@"NSManagedObjectModel_CurrentVersionName"];
                if (!currentVersionName.length)
                    currentVersionName = [murl.lastPathComponent stringByDeletingPathExtension];
                murl = [murl URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.mom", currentVersionName]];
            }
        }
       
        self.familyData.URL = url;
        self.familyData.momURL = murl;
        
        NSURL* containingDirURL = [url URLByDeletingLastPathComponent];
        if (![containingDirURL checkPromisedItemIsReachableAndReturnError:NULL])
            [[NSFileManager defaultManager] createDirectoryAtURL:containingDirURL withIntermediateDirectories:YES attributes:nil error:NULL];
        
        self.managedObjectContext = [[NIManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType database:self];
        self.managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        
        [self performBlockAndWait:^{
            NSError* error = nil;

            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeManagedObjectContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:self.managedObjectContext];
            
            self.managedObjectContext.undoManager = nil;
            NSManagedObjectModel* mom = [[[NSManagedObjectModel alloc] initWithContentsOfURL:murl] autorelease];
            self.managedObjectContext.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
            
            NSURL* urlm = [url URLByAppendingPathExtension:@"mom"]; // mom used when last saving persistent storage
            
            if (![self.managedObjectContext.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:@{ NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES } error:&error]) {
                if (![[NSData dataWithContentsOfURL:urlm] isEqualToData:[NSData dataWithContentsOfURL:murl]]) // exists, != murl
                    [self.class migrate:url from:urlm into:self.managedObjectContext];
            }
        }];
    }
    
    return self;
}

- (id)initWithConcurrencyType:(NSManagedObjectContextConcurrencyType)type parent:(__kindof NIDatabase*)parent {
    if ((self = [super init])) {
        self.parent = parent;
        self.familyData = parent.familyData;

        self.managedObjectContext = [[NIManagedObjectContext alloc] initWithConcurrencyType:type database:self];
        self.managedObjectContext.parentContext = parent.managedObjectContext;
        self.managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        self.managedObjectContext.undoManager = nil;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeManagedObjectContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:self.managedObjectContext];

//        [self.managedObjectContext setPersistentStoreCoordinator:parent.managedObjectContext.persistentStoreCoordinator];
        
        [[NSNotificationCenter defaultCenter] addObserver:self.managedObjectContext selector:@selector(mergeChangesFromContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:parent.managedObjectContext];
    }
    
    return self;
}

- (__kindof NIDatabase*)ancestor {
    __kindof NIDatabase* db = self;

    while (db.parent)
        db = db.parent;
    
    return db;
}

- (void)dealloc {
    [self saveIfChanged];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:self.managedObjectContext];
    self.managedObjectContext = nil;
    
    if (self.parent) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:self.parent.managedObjectContext];
        self.parent = nil;
    }
    
    self.familyData = nil;
    
    [super dealloc];
}

- (BOOL)hasChanges {
    __block BOOL r = NO;
    [self performBlockAndWait:^{
        r = [self.managedObjectContext hasChanges];
    }];
    return r;
}

- (void)saveIfChanged {
    if (self.hasChanges)
        [self save];
}

- (void)save {
    [self performBlockAndWait:^{
        @try {
            NSError* error = nil;
            if (![self.managedObjectContext save:&error])
                NSLog(@"Error: save error - %@", error.localizedDescription);
        } @catch(NSException* e) {
            NSLog(@"%@", e);
        }
    }];
}

- (NSPersistentStoreCoordinator*)persistentStoreCoordinator {
    __block NSPersistentStoreCoordinator* r = nil;
    [self performBlockAndWait:^{
        r = self.managedObjectContext.persistentStoreCoordinator;
    }];
    return r;
}

- (NSManagedObjectModel*)managedObjectModel {
    return self.persistentStoreCoordinator.managedObjectModel;
}

- (NIDatabase*)childDatabase {
    return [self childDatabaseWithConcurrencyType:NSPrivateQueueConcurrencyType];
}

- (NIDatabase*)childDatabaseForMainThread {
    return [self childDatabaseWithConcurrencyType:NSMainQueueConcurrencyType];
}

- (NIDatabase*)childDatabaseWithConcurrencyType:(NSManagedObjectContextConcurrencyType)type {
    return [[[self.class alloc] initWithConcurrencyType:type parent:self] autorelease];
}

- (NSEntityDescription*)entityForName:(NSString*)name {
    __block NSEntityDescription* r = nil;
    [self performBlockAndWait:^{
        r = [NSEntityDescription entityForName:name inManagedObjectContext:self.managedObjectContext];
    }];
    return r;
}

- (id)insertNewObjectForEntity:(NSEntityDescription*)entity {
    __block id r = nil;
    [self performBlockAndWait:^{
        r = [NSEntityDescription insertNewObjectForEntityForName:entity.name inManagedObjectContext:self.managedObjectContext];
    }];
    return r;
}

#if TARGET_OS_IPHONE
- (NSFetchedResultsController*)resultsControllerWithFetchRequest:(NSFetchRequest*)fetchRequest sectionNameKeyPath:(NSString*)sectionNameKeyPath cacheName:(NSString*)name {
    __block NSFetchedResultsController* r = nil;
    [self performBlockAndWait:^{
        r = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:sectionNameKeyPath cacheName:name];
    }];
    return r;
}
#endif

- (NSUInteger)countObjectsForEntity:(NSEntityDescription*)entity predicate:(NSPredicate*)predicate {
    return [self countObjectsForEntity:entity predicate:predicate error:NULL];
}

- (NSUInteger)countObjectsForEntity:(NSEntityDescription*)entity predicateFormat:(NSString*)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    @try {
        return [self countObjectsForEntity:entity predicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args] error:NULL];
    } @catch(...) {
        @throw;
    } @finally {
        va_end(args);
    }
}

- (NSUInteger)countObjectsForEntity:(NSEntityDescription*)entity predicate:(NSPredicate*)predicate error:(NSError**)error {
    NSFetchRequest* fr = [[NSFetchRequest alloc] init];
    fr.entity = entity;
    fr.predicate = predicate;
    
    __block NSUInteger r = 0;
    [self performBlockAndWait:^{
        r = [self.managedObjectContext countForFetchRequest:fr error:error];
    }];
    return r;
}

- (NSArray*)objectsForEntity:(NSEntityDescription*)entity predicate:(NSPredicate*)predicate {
    return [self objectsForEntity:entity predicate:predicate error:NULL];
}

- (NSArray*)objectsForEntity:(NSEntityDescription*)entity predicateFormat:(NSString*)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    @try {
        return [self objectsForEntity:entity predicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args] error:NULL];
    } @catch(...) {
        @throw;
    } @finally {
        va_end(args);
    }
}

- (NSArray*)objectsForEntity:(NSEntityDescription*)entity predicate:(NSPredicate*)predicate error:(NSError**)error {
    NSFetchRequest* fr = [[NSFetchRequest alloc] init];
    fr.entity = entity;
    fr.predicate = predicate;

    __block NSArray* r = nil;
    [self performBlockAndWait:^{
        r = [self.managedObjectContext executeFetchRequest:fr error:error];
    }];
    return r;
}

- (id)objectWithID:(NSManagedObjectID*)objectID {
    __block id r = nil;
    if (objectID)
        [self performBlockAndWait:^{
            r = [self.managedObjectContext objectWithID:objectID];
        }];
    return r;
}

- (void)deleteObject:(NSManagedObject*)obj {
    [self performBlockAndWait:^{
        [self.managedObjectContext deleteObject:obj];
    }];
}

- (void)refreshObjects:(id)collection mergeChanges:(BOOL)flag {
    for (id obj in collection)
        [self refreshObject:obj mergeChanges:flag];
}

- (void)refreshObject:(NSManagedObject*)object mergeChanges:(BOOL)flag {
    [self performBlockAndWait:^{
        [self.managedObjectContext refreshObject:object mergeChanges:flag];
    }];
}

- (void)observeManagedObjectContextDidSaveNotification:(NSNotification*)n {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @synchronized(self.familyData) {
            if (!self.familyData.momSaved) {
                [[NSFileManager defaultManager] copyItemAtURL:self.familyData.momURL toURL:[self.familyData.URL URLByAppendingPathExtension:@"mom"] error:NULL];
                self.familyData.momSaved = YES;
            }
        }
    });
}

+ (void)migrate:(NSURL*)url from:(NSURL*)murl into:(NSManagedObjectContext*)nmoc {
    @autoreleasepool {
        NSError* error;
        
        NSManagedObjectModel* omom = [[NSManagedObjectModel alloc] initWithContentsOfURL:murl];
        
        NSURL* ourl = [url URLByAppendingPathExtension:@"old"];
        NSURL* omurl = [murl URLByAppendingPathExtension:@"old"];
        NSURL* nurl = [url URLByAppendingPathExtension:@"new"];
        
        [self.class _removeItemsForURL:ourl];
        [self.class _removeItemsForURL:omurl];
        [self.class _removeItemsForURL:nurl];
        
        NSException* omome = nil;
        if (omom) {
            NSLog(@"Info: migrating persistent store...");
            
            @try {
                @autoreleasepool {
                    NSMappingModel* mm = [NSMappingModel inferredMappingModelForSourceModel:omom destinationModel:nmoc.persistentStoreCoordinator.managedObjectModel error:&error];
                    if (!mm)
                        [NSException raise:NSGenericException format:@"%@", error.localizedDescription];

                    NSMigrationManager* manager = [[NSMigrationManager alloc] initWithSourceModel:omom destinationModel:nmoc.persistentStoreCoordinator.managedObjectModel];
                    if (![manager migrateStoreFromURL:url type:NSSQLiteStoreType options:nil withMappingModel:mm toDestinationURL:nurl destinationType:NSSQLiteStoreType destinationOptions:nil error:&error])
                        [NSException raise:NSGenericException format:@"%@", error.localizedDescription];
                }
            } @catch (NSException* e) {
                omome = e;
            }
            
            [self.class _moveItemsForURL:url toURL:ourl];
            [self.class _moveItemsForURL:murl toURL:omurl];
            
            [self.class _moveItemsForURL:nurl toURL:url];
        }
        
        if (!omom || omome) {
            NSLog(@"Error: can't read persistent store, %@!\n\n!!! DELETING DATA !!!\n\n", omome? omome.reason : @"model is unavailable");
            [self.class _removeItemsForURL:url];
        }
        
        if (![nmoc.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error])
            [NSException raise:NSGenericException format:@"%@", error.localizedDescription];
        
        [nmoc save:NULL];
        
        [self.class _removeItemsForURL:ourl];
        [self.class _removeItemsForURL:omurl];
    }
}

+ (void)_removeItemsForURL:(NSURL*)url {
    [[NSFileManager defaultManager] removeItemAtURL:url error:NULL];
    NSString* uname = url.lastPathComponent;
    for (NSURL* surl in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:url.URLByDeletingLastPathComponent includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants+NSDirectoryEnumerationSkipsPackageDescendants error:NULL]) {
        NSString* sname = surl.lastPathComponent;
        if ([sname hasPrefix:uname] && [sname characterAtIndex:uname.length] == '-')
            [[NSFileManager defaultManager] removeItemAtURL:surl error:NULL];
    }
}

+ (void)_moveItemsForURL:(NSURL*)url toURL:(NSURL*)nurl {
    [[NSFileManager defaultManager] moveItemAtURL:url toURL:nurl error:NULL];
    NSString* uname = url.lastPathComponent;
    NSString* nname = nurl.lastPathComponent;
    for (NSURL* surl in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:url.URLByDeletingLastPathComponent includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants+NSDirectoryEnumerationSkipsPackageDescendants error:NULL]) {
        NSString* sname = surl.lastPathComponent;
        if ([sname hasPrefix:uname] && [sname characterAtIndex:uname.length] == '-')
            [[NSFileManager defaultManager] moveItemAtURL:surl toURL:[nurl.URLByDeletingLastPathComponent URLByAppendingPathComponent:[nname stringByAppendingString:[sname substringFromIndex:uname.length]]] error:NULL];
    }
}

@end

@implementation NIDatabaseFamilyData

@synthesize URL = _URL, momURL = _momURL;
@synthesize momSaved = _momSaved;

- (void)dealloc {
    self.URL = self.momURL = nil;
    [super dealloc];
}

@end


