//
//  CPRMPRWindow.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/29/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRWindow.h"
#import "CPRMPRController+Private.h"

@implementation CPRMPRWindow

- (void)sendEvent:(NSEvent*)event {
    if (event.type == NSKeyDown || event.type == NSKeyUp)
        if ([event.characters characterAtIndex:0] == ' ') {
            BOOL flag = (event.type == NSKeyDown);
            if ([self.windowController spacebarIsDown] != flag)
                [self.windowController setSpacebarDown:flag];
        }
    [super sendEvent:event];
}

@end
