//
//  CPRMPRBlockMenuItem.h
//  CPRMPR
//
//  Created by Alessandro Volz on 5/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CPRMPRBlockMenuItem : NSMenuItem {
    void (^_block)();
}

+ (instancetype)itemWithTitle:(NSString*)title block:(void(^)())block;
- (instancetype)initWithTitle:(NSString*)title block:(void(^)())block;

@end

@interface NSMenu (CPRMPR)

- (CPRMPRBlockMenuItem*)addItemWithTitle:(NSString*)title block:(void(^)())block;

@end