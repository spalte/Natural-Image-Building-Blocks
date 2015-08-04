//
//  NIBackgroundView.h
//  NIMPR
//
//  Created by Alessandro Volz on 8/3/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//@interface NIObserver : NSObject {
//    
//}

@interface NIBackgroundView : NSView {
    NSColor* _backgroundColor;
//    NSArray* _observers;
}

@property(retain) NSColor* backgroundColor;

- (id)initWithFrame:(NSRect)frameRect color:(NSColor*)backgroundColor;

@end
