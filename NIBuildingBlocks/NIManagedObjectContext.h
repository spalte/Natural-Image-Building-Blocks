//
//  NIManagedObjectContext.h
//  Stag
//
//  Created by Alessandro Volz on 3/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <CoreData/CoreData.h>

@class NIDatabase;

@interface NIManagedObjectContext : NSManagedObjectContext {
    NIDatabase* _database;
}

@property (assign, readonly) NIDatabase* database;

- (id)initWithConcurrencyType:(NSManagedObjectContextConcurrencyType)type database:(NIDatabase*)database;

@end
