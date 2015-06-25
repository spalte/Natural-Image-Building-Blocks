//
//  NIMPRWindow.h
//  NIMPR
//
//  Created by Alessandro Volz on 5/29/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NIMPRWindow : NSWindow

@end

@interface NSView (NIMPRWindow)

- (BOOL)interceptsToolbarRightMouseEvents;

@end