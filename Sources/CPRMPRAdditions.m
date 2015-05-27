//
//  CPRMPRAdditions.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/27/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRAdditions.h"

@implementation NSObject (CPRMPRAdditions)

- (id)if:(Class)class {
    if (![self isKindOfClass:class])
        return nil;
    return self;
}

@end

@implementation NSDictionary (CPRMPRAdditions)

- (id)valueForKeyPath:(NSString*)keyPath {
    NSRange r = [keyPath rangeOfString:@"."];
    if (r.location != NSNotFound)
        return [[self valueForKey:[keyPath substringToIndex:r.location]] valueForKeyPath:[keyPath substringFromIndex:r.location+r.length]];
    else return [self valueForKey:keyPath];
}

@end

@implementation NSMutableDictionary (CPRMPRAdditions)

- (void)setValue:(id)value forKeyPath:(NSString*)keyPath {
    NSRange r = [keyPath rangeOfString:@"."];
    if (r.location != NSNotFound)
        [[self valueForKey:[keyPath substringToIndex:r.location]] setValue:value forKeyPath:[keyPath substringFromIndex:r.location+r.length]];
    else [self setValue:value forKey:keyPath];
}

@end