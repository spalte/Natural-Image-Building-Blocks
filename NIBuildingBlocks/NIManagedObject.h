//
//  StagManagedObject.h
//  Stag
//
//  Created by Alessandro Volz on 3/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <CoreData/CoreData.h>

@class NIDatabase, NIRecursiveLock, NIManagedObjectContext;
// @class NIManagedObjectControllerFactory;

//extern NSString* const NIManagedObjectIsBeingDeletedNotification;

@interface NIManagedObject : NSManagedObject

//+ (Class)controllerClass;

- (__kindof NIDatabase*)database;

- (NSString*)objectId;

//- (id)controller;

- (BOOL)hasValueForRelationshipNamed:(NSString*)key;

@end

//@interface NIManagedObjectController : NSObject {
//    NIDatabase* _database;
//    NSManagedObjectID* _objectID;
//    NSMutableDictionary* _instances;
//    id _key;
//    NIManagedObjectControllerFactory* _factory;
//    NIRecursiveLock* _lock;
//}
//
//- (id)object;
//
//- (id)database;
//
//- (id)initWithObject:(NIManagedObject*)object NS_REQUIRES_SUPER;
//
//- (id)refreshObject;
//- (id)refreshObject:(BOOL)merge;
//
//
//@end
