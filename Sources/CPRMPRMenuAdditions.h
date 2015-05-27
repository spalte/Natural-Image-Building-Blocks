//
//  CPRMPRBlockMenuItem.h
//  CPRMPR
//
//  Created by Alessandro Volz on 5/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CPRMPRBlockMenuItem : NSMenuItem <NSCoding> {
    void(^_block)();
}

//+ (instancetype)itemWithTitle:(NSString*)title block:(void(^)())block;

@end

@interface CPRMPRSubmenuMenuItem : NSMenuItem <NSMenuDelegate, NSCoding> {
    void(^_block)(NSMenu*);
}

//+ (instancetype)itemWithTitle:(NSString*)title block:(void(^)(NSMenu* menu))block;

@end

@interface NSMenu (CPRMPR)

- (NSMenuItem*)addItemWithTitle:(NSString*)title block:(void(^)())block;
- (NSMenuItem*)addItemWithTitle:(NSString*)title keyEquivalent:(NSString*)keyEquivalent block:(void(^)())block;
- (NSMenuItem*)addItemWithTitle:(NSString*)title submenu:(NSMenu*)submenu;

@end