//
//  NIMPRBlockMenuItem.m
//  NIMPR
//
//  Created by Alessandro Volz on 5/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NSMenu+NIMPR.h"

@interface NIMPRBlockMenuItem ()

@property(copy) void(^block)();

@end

@implementation NIMPRBlockMenuItem

static NSString* const NIMPRBlockMenuItemBlockKey = @"NIMPRBlockMenuItemBlock";

@synthesize block = _block;

+ (instancetype)itemWithTitle:(NSString *)title keyEquivalent:(NSString*)keyEquivalent block:(void(^)())block {
    NIMPRBlockMenuItem* item = [[[self.class alloc] initWithTitle:title action:@selector(action:) keyEquivalent:keyEquivalent] autorelease];
    item.target = item;
    item.block = block;
    return item;
}

- (id)initWithCoder:(NSCoder*)coder {
    if ((self = [super initWithCoder:coder])) {
        self.block = [coder decodeObjectForKey:NIMPRBlockMenuItemBlockKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.block forKey:NIMPRBlockMenuItemBlockKey];
}

- (void)dealloc {
    self.block = nil;
    [super dealloc];
}

- (void)action:(id)sender {
    self.block();
}

@end

@interface NIMPRSubmenuMenuItem ()

@property(copy) void(^block)(NSMenu*);

@end

@implementation NIMPRSubmenuMenuItem

@synthesize block = _block;

+ (instancetype)itemWithTitle:(NSString *)title block:(void(^)(NSMenu*))block {
    NIMPRSubmenuMenuItem* item = [[[self.class alloc] initWithTitle:title action:nil keyEquivalent:@""] autorelease];
    item.submenu = [[[NSMenu alloc] init] autorelease];
    item.submenu.delegate = item;
    item.block = block;
    return item;
}

- (void)dealloc {
    self.block = nil;
    [super dealloc];
}

NSString* const NIMPRSubmenuMenuItemBlockKey = @"NIMPRSubmenuMenuItemBlock";

- (id)initWithCoder:(NSCoder*)coder {
    if ((self = [super initWithCoder:coder])) {
        self.block = [coder decodeObjectForKey:NIMPRSubmenuMenuItemBlockKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.block forKey:NIMPRSubmenuMenuItemBlockKey];
}

- (void)menuWillOpen:(NSMenu*)menu {
    self.block(menu);
}

@end

@implementation NSMenu (NIMPR)

- (NSMenuItem*)addItemWithTitle:(NSString*)title block:(void(^)())block {
    return [self addItemWithTitle:title keyEquivalent:@"" block:block];
}

- (NSMenuItem*)addItemWithTitle:(NSString*)title keyEquivalent:(NSString*)keyEquivalent block:(void(^)())block {
    NIMPRBlockMenuItem* item = [NIMPRBlockMenuItem itemWithTitle:title keyEquivalent:keyEquivalent block:block];
    [self addItem:item];
    return item;
}

- (NSMenuItem*)addItemWithTitle:(NSString*)title submenu:(NSMenu*)submenu {
    NSMenuItem* item = [self addItemWithTitle:title action:nil keyEquivalent:@""];
    item.submenu = submenu;
    return item;
}

@end