//
//  NIMPRBlockMenuItem.m
//  NIMPR
//
//  Created by Alessandro Volz on 5/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NSMenu+NIMPR.h"

@interface NIBlockMenuItem ()

@property(copy) void(^block)(id sender);

@end

@implementation NIBlockMenuItem

static NSString* const NIBlockMenuItemBlockKey = @"NIBlockMenuItemBlock";

@synthesize block = _block;

+ (instancetype)itemWithTitle:(NSString *)title block:(void(^)())block {
    return [self.class itemWithTitle:title keyEquivalent:@"" block:block];
}

+ (instancetype)itemWithTitle:(NSString *)title keyEquivalent:(NSString*)keyEquivalent block:(void(^)())block {
    NIBlockMenuItem* item = [[[self.class alloc] initWithTitle:title action:@selector(action:) keyEquivalent:keyEquivalent] autorelease];
    item.target = item;
    item.block = block;
    return item;
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    if ((self = [super initWithCoder:coder])) {
        self.block = [coder decodeObjectForKey:NIBlockMenuItemBlockKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.block forKey:NIBlockMenuItemBlockKey];
}

- (void)dealloc {
    self.block = nil;
    [super dealloc];
}

- (void)action:(id)sender {
    self.block(sender);
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

- (instancetype)initWithCoder:(NSCoder*)coder {
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

@implementation NIMenuItem

@synthesize altTitle = _altTitle;

- (void)dealloc {
    self.altTitle = nil;
    [super dealloc];
}

@end

@implementation NSMenu (NIMPR)

- (NSMenuItem*)addItemWithTitle:(NSString *)title tag:(NSInteger)tag {
    NSMenuItem* r = [self addItemWithTitle:title action:nil keyEquivalent:@""];
    r.tag = tag;
    return r;
}

- (NSMenuItem*)addItemWithTitle:(NSString *)title alt:(NSString *)alt tag:(NSInteger)tag {
    NIMenuItem* item = [[[NIMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""] autorelease];
    item.altTitle = alt;
    item.tag = tag;
    [self addItem:item];
    return item;
}


- (NSMenuItem*)addItemWithTitle:(NSString*)title block:(void(^)())block {
    return [self addItemWithTitle:title alt:nil keyEquivalent:@"" block:block];
}

- (NSMenuItem*)addItemWithTitle:(NSString*)title keyEquivalent:(NSString*)ke block:(void(^)())block {
    return [self addItemWithTitle:title alt:nil keyEquivalent:ke block:block];
}

- (NSMenuItem*)addItemWithTitle:(NSString*)title alt:(NSString*)alt block:(void(^)())block {
    return [self addItemWithTitle:title alt:alt keyEquivalent:@"" block:block];
}

- (NSMenuItem*)addItemWithTitle:(NSString*)title alt:(NSString*)alt keyEquivalent:(NSString*)keyEquivalent block:(void(^)())block {
    return [self insertItemWithTitle:title alt:alt keyEquivalent:keyEquivalent block:block atIndex:self.numberOfItems];
}

- (NSMenuItem*)insertItemWithTitle:(NSString*)title block:(void(^)())block atIndex:(NSUInteger)idx {
    return [self insertItemWithTitle:title alt:nil keyEquivalent:@"" block:block atIndex:idx];
}

- (NSMenuItem*)insertItemWithTitle:(NSString*)title alt:(NSString*)alt keyEquivalent:(NSString*)keyEquivalent block:(void(^)())block atIndex:(NSUInteger)idx {
    NIBlockMenuItem* item = [NIBlockMenuItem itemWithTitle:title keyEquivalent:keyEquivalent block:block];
    item.altTitle = alt;
    [self insertItem:item atIndex:idx];
    return item;
}

- (NSMenuItem*)addItemWithTitle:(NSString*)title submenu:(NSMenu*)submenu {
    NSMenuItem* item = [self addItemWithTitle:title action:nil keyEquivalent:@""];
    item.submenu = submenu;
    return item;
}

@end
