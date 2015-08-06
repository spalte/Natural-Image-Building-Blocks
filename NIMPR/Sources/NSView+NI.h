//
//  NIBackgroundView.h
//  NIMPR
//
//  Created by Alessandro Volz on 8/3/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NIViewController;

@interface NIRetainer : NSObject {
    NSMutableDictionary* _retains;
}

- (void)retain:(id)obj;
- (void)retain:(id)obj forKey:(id)key;

@end

@interface NIView : NSView {
    NIViewController* _controller;
}

@property(assign) NIViewController* controller;

@end

@interface NIViewController : NSViewController {
    void (^_updateConstraintsBlock)();
    NIRetainer* _retainer;
}

@property(copy) void (^updateConstraintsBlock)();
@property(readonly, retain, nonatomic) NIRetainer* retainer;

@property(retain) NIView* view;

- (id)initWithView:(NIView*)view;
- (id)initWithView:(NIView*)view updateConstraints:(void (^)())updateConstraintsBlock;
- (id)initWithView:(NIView*)view updateConstraints:(void (^)())updateConstraintsBlock and:(void (^)(NIRetainer* r))block;

@end

@interface NSView (NI)

- (void)removeAllConstraints;

@end

@interface NIBackgroundView : NIView {
    NSColor* _backgroundColor;
}

@property(retain) NSColor* backgroundColor;

- (id)initWithFrame:(NSRect)frameRect color:(NSColor*)backgroundColor;

@end

@interface NSTextField (NI)

+ (instancetype)labelWithControlSize:(NSControlSize)controlSize;
+ (instancetype)fieldWithControlSize:(NSControlSize)controlSize;

@end
