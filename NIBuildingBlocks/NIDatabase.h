//
//  NIDatabase.h
//  Stag
//
//  Created by Alessandro Volz on 3/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIManagedObjectContext.h"
#import "Macros.h"

@class NIDatabaseFamilyData;

@interface NIDatabase : NSObject {
    NIManagedObjectContext* _managedObjectContext;
    NIDatabase* _parent;
    NIDatabaseFamilyData* _familyData; // was used for saving the model when intercepting a save; now the model is saved on init, but I'm leaving this here just in case it becomes useful again...
}

@property (readonly, strong, nonatomic) NIManagedObjectContext* managedObjectContext; // access to the context is discouraged
@property (readonly, retain) NIDatabase* parent;
@property (readonly, retain) NIDatabaseFamilyData* familyData;

+ (Class)NIDatabaseFamilyDataClass;

- (instancetype)initWithURL:(NSURL*)url model:(NSURL*)murl error:(NSError**)error;
- (instancetype)initWithConcurrencyType:(NSManagedObjectContextConcurrencyType)type parent:(NIDatabase*)parent; // this initializer is declared strictly for subclassing!! you shouldn't call this directly
- (instancetype)ancestor;

- (instancetype)childDatabase;
- (instancetype)mainChildDatabase; // only for the main thread!

+ (NSURL*)model; // your subclass can implement a +model method in order to provide a model without passing it to the -initWithUrl:model: method
- (id)initWithURL:(NSURL*)url error:(NSError**)error;

- (BOOL)hasChanges;
- (BOOL)saveIfChanged;
- (BOOL)save;

- (void)performBlock:(void (^)())block;
- (void)performBlockAndWait:(void (^)())block;

- (NSEntityDescription*)entityForName:(NSString*)name;

- (id)insertNewObjectForEntity:(NSEntityDescription*)entity;
- (BOOL)obtainPermanentIDsForObjects:(NSArray<NSManagedObject *> *)objects error:(NSError**)error;

- (NSUInteger)countObjectsForEntity:(NSEntityDescription*)entity predicate:(NSPredicate*)predicate;
- (NSUInteger)countObjectsForEntity:(NSEntityDescription*)entity predicateFormat:(NSString*)predicateFormat, ...;
- (NSUInteger)countObjectsForEntity:(NSEntityDescription*)entity predicate:(NSPredicate*)predicate error:(NSError**)error;

- (__GENERIC(NSArray, __KINDOF(NSManagedObject) *)*)objectsForEntity:(NSEntityDescription*)entity predicate:(NSPredicate*)predicate;
- (__GENERIC(NSArray, __KINDOF(NSManagedObject) *)*)objectsForEntity:(NSEntityDescription*)entity predicateFormat:(NSString*)predicateFormat, ...;
- (__GENERIC(NSArray, __KINDOF(NSManagedObject) *)*)objectsForEntity:(NSEntityDescription*)entity predicate:(NSPredicate*)predicate error:(NSError**)error;

- (id)objectWithID:(NSManagedObjectID*)objectID;

- (void)deleteObject:(NSManagedObject*)obj;

- (void)refreshObjects:(id)collection mergeChanges:(BOOL)flag;
- (void)refreshObject:(NSManagedObject*)object mergeChanges:(BOOL)flag;

#if TARGET_OS_IPHONE
- (NSFetchedResultsController*)resultsControllerWithFetchRequest:(NSFetchRequest*)fetchRequest sectionNameKeyPath:(NSString*)sectionNameKeyPath cacheName:(NSString*)name;
#endif

@end


@interface NIDatabaseFamilyData : NSObject {
    NSURL *_URL, *_momURL;
    BOOL _momSaved;
}

@property (readonly, retain) NSURL *URL, *momURL;
@property (readonly) BOOL momSaved;

@end
