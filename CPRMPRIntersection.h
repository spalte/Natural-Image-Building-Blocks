//
//  CPRMPRIntersection.h
//  CPRMPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRIntersection.h"

@class CPRMPRView;

@interface CPRMPRIntersection : CPRIntersection {
    CPRMPRView* _mprView;
}

@property(readonly, assign) CPRMPRView* mprView;

- (instancetype)initWithMPRView:(CPRMPRView*)mprView;

@end
