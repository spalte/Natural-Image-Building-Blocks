//
//  NIRecursiveLock.m
//  NIBuildingBlocks
//
//  Created by Alessandro Volz on 11/10/15.
//  Copyright © 2015 Spaltenstein Natural Image. All rights reserved.
//  Copyright © 2015 volz io. All rights reserved.
//

#import "NIRecursiveLock.h"

@interface NIRecursiveLock ()

@property NSMutableArray* lockers;

@end

@implementation NIRecursiveLock

@synthesize lockers = _lockers;

- (id)init {
    if (!(self = [super init]))
        return nil;
    
    self.lockers = [NSMutableArray array];
    
    return self;
}

- (void)dealloc {
    self.lockers = nil;
    [super dealloc];
}

- (void)lock {
    [super lock];
    
    @synchronized (self.lockers) {
        [self.lockers addObject:[NSThread currentThread]];
    }
}

- (void)unlock {
    @synchronized (self.lockers) {
        if (self.lockers.lastObject != [NSThread currentThread])
            [NSException raise:NSGenericException format:@"Unlock must come from same thread as corresponding lock"];
        [self.lockers removeLastObject];
    }
    
    [super unlock];
}

@end
