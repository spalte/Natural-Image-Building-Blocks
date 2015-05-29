//
//  CPRMPRAdditions.h
//  CPRMPR
//
//  Created by Alessandro Volz on 5/27/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (CPRMPRAdditions)

- (id)if:(Class)c;
- (id)performSelector:(SEL)sel withObjects:(id)obj1 :(id)obj2;
- (id)performSelector:(SEL)sel withObjects:(id)obj1 :(id)obj2 :(id)obj3;

@end

//@interface NSDictionary (CPRMPRAdditions)
//
//@end
//
//@interface NSMutableDictionary (CPRMPRAdditions)
//
//@end
