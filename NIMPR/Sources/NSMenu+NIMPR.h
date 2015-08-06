//
//  NIMPRBlockMenuItem.h
//  NIMPR
//
//  Created by Alessandro Volz on 5/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NIMenuItem : NSMenuItem {
    NSString* _altTitle;
}

@property(retain) NSString* altTitle;

@end

@interface NIBlockMenuItem : NIMenuItem <NSCoding> {
    void(^_block)();
}

+ (instancetype)itemWithTitle:(NSString *)title block:(void(^)())block;
+ (instancetype)itemWithTitle:(NSString *)title keyEquivalent:(NSString*)keyEquivalent block:(void(^)())block;

@end

@interface NIMPRSubmenuMenuItem : NSMenuItem <NSMenuDelegate, NSCoding> {
    void(^_block)(NSMenu*);
}

//+ (instancetype)itemWithTitle:(NSString*)title block:(void(^)(NSMenu* menu))block;

@end

@interface NSMenu (NIMPR)

- (NSMenuItem*)addItemWithTitle:(NSString *)title tag:(NSInteger)tag;
- (NSMenuItem*)addItemWithTitle:(NSString *)aString alt:(NSString*)alt tag:(NSInteger)tag;

- (NSMenuItem*)addItemWithTitle:(NSString*)title block:(void(^)())block;
- (NSMenuItem*)addItemWithTitle:(NSString*)title keyEquivalent:(NSString*)ke block:(void(^)())block;
- (NSMenuItem*)addItemWithTitle:(NSString*)title alt:(NSString*)alt block:(void(^)())block;
- (NSMenuItem*)addItemWithTitle:(NSString*)title alt:(NSString*)alt keyEquivalent:(NSString*)keyEquivalent block:(void(^)())block;
- (NSMenuItem*)insertItemWithTitle:(NSString*)title block:(void(^)())block atIndex:(NSUInteger)idx;
- (NSMenuItem*)insertItemWithTitle:(NSString*)title alt:(NSString*)alt  keyEquivalent:(NSString*)keyEquivalent block:(void(^)())block atIndex:(NSUInteger)idx;

- (NSMenuItem*)addItemWithTitle:(NSString*)title submenu:(NSMenu*)submenu;

@end