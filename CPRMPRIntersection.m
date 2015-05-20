//
//  CPRMPRIntersection.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRIntersection.h"

@interface CPRMPRIntersection ()

@property(readwrite, assign) CPRMPRView* mprView;

@end

@implementation CPRMPRIntersection

@synthesize mprView = _mprView;

- (instancetype)initWithMPRView:(CPRMPRView*)mprView {
    if ((self = [super init])) {
        self.mprView = mprView;
    }
    
    return self;
}

- (void)dealloc {
    self.mprView = nil;
    [super dealloc];
}

@end
