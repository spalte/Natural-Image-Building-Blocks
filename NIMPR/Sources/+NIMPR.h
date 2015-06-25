//
//  NIMPRAdditions.h
//  NIMPR
//
//  Created by Alessandro Volz on 5/27/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (NIMPR)

- (id)if:(Class)c;
- (id)performSelector:(SEL)sel withObjects:(id)obj1 :(id)obj2;
- (id)performSelector:(SEL)sel withObjects:(id)obj1 :(id)obj2 :(id)obj3;

@end

//@interface NSDictionary (NIMPRAdditions)
//
//@end
//
//@interface NSMutableDictionary (NIMPRAdditions)
//
//@end

@interface NSWindow (NIMPR)

- (NSPoint)convertPointToScreen:(NSPoint)point;
- (NSPoint)convertPointFromScreen:(NSPoint)point;

@end