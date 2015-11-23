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

@implementation NIManagedObject

- (__kindof NIDatabase*)database {
    id context = [self managedObjectContext];
    if ([context isKindOfClass:NIManagedObjectContext.class])
        return [(NIManagedObjectContext*)context database];
    return nil;
}

- (NSString*)objectId {
    return self.objectID.URIRepresentation.absoluteString;
}

- (BOOL)hasValueForRelationshipNamed:(NSString*)key {
    return [self.database countObjectsForEntity:self.entity predicateFormat:@"SELF = %@ AND %@ != NIL", self, [NSExpression expressionForKeyPath:key]] != 0;
}

@end
