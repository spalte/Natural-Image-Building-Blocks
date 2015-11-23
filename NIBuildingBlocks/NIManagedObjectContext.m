
//
//  NIManagedObjectContext.m
//  Stag
//
//  Created by Alessandro Volz on 3/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIManagedObjectContext.h"
#import "NIDatabase.h"

@interface NIManagedObjectContext ()

@property (assign, readwrite) NIDatabase* database;

@end

@implementation NIManagedObjectContext

@synthesize database = _database;

- (id)initWithConcurrencyType:(NSManagedObjectContextConcurrencyType)type database:(NIDatabase*)database {
    if ((self = [super initWithConcurrencyType:type])) {
        self.database = database;
//        DebugLog(@"allocating context %lx for %lx", (unsigned long)self, (unsigned long)self.thread);
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    DebugLog(@"deallocating context 0x%lx for 0x%lx", (unsigned long)self, (unsigned long)self.thread);
    [super dealloc];
}

- (BOOL)save:(NSError**)error {
//    DebugLog(@"saving context %lx for %lx", (unsigned long)self, (unsigned long)self.thread);
    __autoreleasing NSError* lerror = nil;
    if (!error) error = &lerror;
    *error = nil;
    
    BOOL r =  [super save:error];
    if (*error)
        switch ([*error code]) {
            case 133020: {
                NSLog(@"Warning: save error, merge conflicts - %@", [*error userInfo][@"conflictList"]);
            } break;
            default: {
                NSLog(@"Warning: save error - %@", [*error localizedDescription]);
            } break;
        }
    
    return r;
}

- (void)mergeChangesFromContextDidSaveNotification:(NSNotification*)n {
    [self performBlockAndWait:^{
        @try {
//            DebugLog(@"%lx merging changes %lx %@", (unsigned long)self, (unsigned long)n, n.userInfo);
            [super mergeChangesFromContextDidSaveNotification:n];
        } @catch (NSException* e) {
           // if (!([e.name isEqualToString:NSInternalInconsistencyException] && [e.reason isEqualToString:@"Can't perform collection evaluate with non-collection object."])) // it's bad practice, but...
                NSLog(@"Warning: database merge exception - %@", e);
        }
    }];
}

@end
