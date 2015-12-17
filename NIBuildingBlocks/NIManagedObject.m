//
//  StagManagedObject.m
//  Stag
//
//  Created by Alessandro Volz on 3/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIManagedObject.h"
#import "NIManagedObjectContext.h"
#import "NIDatabase.h"
#import "NIRecursiveLock.h"

@interface NIManagedObject ()

@property (retain) NIDatabase* database;

@end

@implementation NIManagedObject

@synthesize database = _database;

- (NIManagedObject*)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(nullable NIManagedObjectContext *)context {
    if (!(self = [super initWithEntity:entity insertIntoManagedObjectContext:context]))
        return nil;
    
    self.database = context.database;
    
    return self;
}

- (void)dealloc {
    self.database = nil;
    [super dealloc];
}

- (NSString*)objectId {
    return self.objectID.URIRepresentation.absoluteString;
}

- (BOOL)hasValueForRelationshipNamed:(NSString*)key {
    return [self.database countObjectsForEntity:self.entity predicateFormat:@"SELF = %@ AND %@ != NIL", self, [NSExpression expressionForKeyPath:key]] != 0;
}

@end
