//
//  StagManagedObject.h
//  Stag
//
//  Created by Alessandro Volz on 3/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <CoreData/CoreData.h>

@class NIDatabase, NIRecursiveLock, NIManagedObjectContext;

@interface NIManagedObject : NSManagedObject

- (__kindof NIDatabase*)database;

- (NSString*)objectId;

- (BOOL)hasValueForRelationshipNamed:(NSString*)key;

@end
