//
//  CPRMPRBlockMenuItem.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRMenuAdditions.h"

@interface CPRMPRBlockMenuItem ()

@property(copy) void(^block)();

@end

@implementation CPRMPRBlockMenuItem

@synthesize block = _block;

+ (instancetype)itemWithTitle:(NSString *)title block:(void(^)())block {
    CPRMPRBlockMenuItem* item = [[[self.class alloc] initWithTitle:title action:@selector(action:) keyEquivalent:@""] autorelease];
    item.block = block;
    return item;
}

- (void)dealloc {
    self.block = nil;
    [super dealloc];
}

NSString* const CPRMPRBlockMenuItemBlockKey = @"CPRMPRBlockMenuItemBlock";

- (id)initWithCoder:(NSCoder*)coder {
    if ((self = [super initWithCoder:coder])) {
        self.block = [coder decodeObjectForKey:CPRMPRBlockMenuItemBlockKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.block forKey:CPRMPRBlockMenuItemBlockKey];
}

- (void)action:(id)sender {
    self.block();
}

@end

@interface CPRMPRSubmenuMenuItem ()

@property(copy) void(^block)(NSMenu*);

@end

@implementation CPRMPRSubmenuMenuItem

@synthesize block = _block;

+ (instancetype)itemWithTitle:(NSString *)title block:(void(^)(NSMenu*))block {
    CPRMPRSubmenuMenuItem* item = [[[self.class alloc] initWithTitle:title action:nil keyEquivalent:@""] autorelease];
    item.submenu = [[[NSMenu alloc] init] autorelease];
    item.submenu.delegate = item;
    item.block = block;
    return item;
}

- (void)dealloc {
    self.block = nil;
    [super dealloc];
}

NSString* const CPRMPRSubmenuMenuItemBlockKey = @"CPRMPRSubmenuMenuItemBlock";

- (id)initWithCoder:(NSCoder*)coder {
    if ((self = [super initWithCoder:coder])) {
        self.block = [coder decodeObjectForKey:CPRMPRSubmenuMenuItemBlockKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.block forKey:CPRMPRSubmenuMenuItemBlockKey];
}

- (void)menuWillOpen:(NSMenu*)menu {
    self.block(menu);
}

@end

@implementation NSMenu (CPRMPR)

- (NSMenuItem*)addItemWithTitle:(NSString*)title block:(void(^)())block {
    CPRMPRBlockMenuItem* item = [CPRMPRBlockMenuItem itemWithTitle:title block:block];
    [self addItem:item];
    return item;
}

- (NSMenuItem*)addItemWithTitle:(NSString*)title submenu:(NSMenu*)submenu {
    NSMenuItem* item = [self addItemWithTitle:title action:nil keyEquivalent:@""];
    item.submenu = submenu;
    return item;
}

@end