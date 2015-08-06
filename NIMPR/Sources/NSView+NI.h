//
//  NIBackgroundView.h
//  NIMPR
//
//  Created by Alessandro Volz on 8/3/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NIViewController : NSViewController {
    void (^_updateConstraintsBlock)();
    NSMutableDictionary* _retains;
}

@property(copy) void (^updateConstraintsBlock)();

- (id)initWithView:(NSView*)view;

- (void)retain:(id)obj;
- (void)retain:(id)obj forKey:(id)key;

@end

@interface NSView (NI)

- (void)removeAllConstraints;

@end

@interface NIBackgroundView : NSView {
    NSColor* _backgroundColor;
}

@property(retain) NSColor* backgroundColor;

- (id)initWithFrame:(NSRect)frameRect color:(NSColor*)backgroundColor;

@end

@interface NSTextField (NI)

+ (instancetype)labelWithControlSize:(NSControlSize)controlSize;
+ (instancetype)fieldWithControlSize:(NSControlSize)controlSize;

@end
