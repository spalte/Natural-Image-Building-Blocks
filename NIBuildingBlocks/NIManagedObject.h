//
//  StagManagedObject.h
//  Stag
//
//  Created by Alessandro Volz on 3/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <CoreData/CoreData.h>

@class NIDatabase, NIRecursiveLock, NIManagedObjectContext;

@interface NIManagedObject : NSManagedObject {
    NIDatabase* _database;
}

@property (retain, readonly) NIDatabase* database;
@property (readonly) NSString* objectId;

- (NIManagedObject*)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NIManagedObjectContext *)context NS_DESIGNATED_INITIALIZER;

- (BOOL)hasValueForRelationshipNamed:(NSString*)key;

@end
