//
//  NIDatabase.h
//  Stag
//
//  Created by Alessandro Volz on 3/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIManagedObjectContext.h"

@class NIDatabaseFamilyData;

@interface NIDatabase : NSObject {
    NIManagedObjectContext* _managedObjectContext;
    __kindof NIDatabase* _parent;
    __kindof NIDatabaseFamilyData* _familyData;
}

@property (readonly, strong, nonatomic) NIManagedObjectContext* managedObjectContext; // access to the context is discouraged
@property (readonly, retain) NIDatabase* parent;
@property (readonly, retain) NIDatabaseFamilyData* familyData;

+ (Class)NIDatabaseFamilyDataClass;

- (instancetype)initWithURL:(NSURL*)url model:(NSURL*)murl error:(NSError**)error;
- (instancetype)initWithConcurrencyType:(NSManagedObjectContextConcurrencyType)type parent:(__kindof NIDatabase*)parent; // this initializer is declared strictly for subclassing!! you shouldn't call this directly
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

- (__kindof NSManagedObject*)insertNewObjectForEntity:(NSEntityDescription*)entity;

- (NSUInteger)countObjectsForEntity:(NSEntityDescription*)entity predicate:(NSPredicate*)predicate;
- (NSUInteger)countObjectsForEntity:(NSEntityDescription*)entity predicateFormat:(NSString*)predicateFormat, ...;
- (NSUInteger)countObjectsForEntity:(NSEntityDescription*)entity predicate:(NSPredicate*)predicate error:(NSError**)error;

- (NSArray<__kindof NSManagedObject*>*)objectsForEntity:(NSEntityDescription*)entity predicate:(NSPredicate*)predicate;
- (NSArray<__kindof NSManagedObject*>*)objectsForEntity:(NSEntityDescription*)entity predicateFormat:(NSString*)predicateFormat, ...;
- (NSArray<__kindof NSManagedObject*>*)objectsForEntity:(NSEntityDescription*)entity predicate:(NSPredicate*)predicate error:(NSError**)error;

- (__kindof NSManagedObject*)objectWithID:(NSManagedObjectID*)objectID;

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
