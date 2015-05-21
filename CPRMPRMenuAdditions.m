//
//  CPRMPRBlockMenuItem.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRMenuAdditions.h"

@interface CPRMPRBlockMenuItem ()

@property(copy) void (^block)();

@end

@implementation CPRMPRBlockMenuItem

@synthesize block = _block;

+ (instancetype)itemWithTitle:(NSString *)title block:(void (^)())block {
    return [[[self.class alloc] initWithTitle:title block:block] autorelease];
}

- (instancetype)initWithTitle:(NSString *)title block:(void (^)())block {
    if ((self = [super initWithTitle:title action:@selector(action:) keyEquivalent:@""])) {
        self.target = self;
        self.block = block;
    }
    
    return self;
}

- (void)dealloc {
    self.block = nil;
    [super dealloc];
}

- (void)action:(id)sender {
    self.block();
}

@end

@implementation NSMenu (CPRMPR)

- (CPRMPRBlockMenuItem*)addItemWithTitle:(NSString*)title block:(void(^)())block {
    CPRMPRBlockMenuItem* item = [CPRMPRBlockMenuItem itemWithTitle:title block:block];
    [self addItem:item];
    return item;
}

@end