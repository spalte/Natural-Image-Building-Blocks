//
//  NIMPR.m
//  NIMPR
//
//  Created by Alessandro Volz on 6/2/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPR+Private.h"

static NIMPR* instance = nil;

@implementation NIMPR

@synthesize bundle = _bundle;

- (instancetype)init {
    if ((self = [super init])) {
        self.bundle = [NSBundle bundleForClass:NIMPR.class];
    }
    
    return self;
}

- (void)dealloc {
    self.bundle = nil;
    if (instance == self)
        instance = nil;
    [super dealloc];
}

+ (NIMPR*)instance {
    if (!instance)
        instance = [[self.class alloc] init];
    return instance;
}

+ (NSBundle*)bundle {
    return self.instance.bundle;
}

+ (NSImage*)image:(NSString*)name {
    NSImage* image = [self.bundle imageForResource:name];
    
    if (image)
        return image;
    
    NSURL* url = [self.bundle URLForImageResource:name];
    if (url)
        return [[[NSImage alloc] initWithContentsOfURL:url] autorelease];
    
    return nil;
}

@end
