//
//  CPRMPRWindow.h
//  CPRMPR
//
//  Created by Alessandro Volz on 5/29/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CPRMPRWindow : NSWindow

@end

@interface NSView (CPRMPRWindow)

- (BOOL)interceptsToolbarRightMouseDownEvents;

@end