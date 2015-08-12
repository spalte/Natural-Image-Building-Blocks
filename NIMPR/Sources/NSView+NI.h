//
//  NIBackgroundView.h
//  NIMPR
//
//  Created by Alessandro Volz on 8/3/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NIViewController;

@interface NIView : NSView {
    NIViewController* _controller;
}

@property(assign) NIViewController* controller;

+ (id)labelWithControlSize:(NSControlSize)controlSize;
+ (id)fieldWithControlSize:(NSControlSize)controlSize;
+ (id)buttonWithControlSize:(NSControlSize)controlSize bezelStyle:(NSBezelStyle)bezelStyle title:(NSString*)title block:(void (^)())actionBlock;

@end

@interface NIViewController : NSViewController {
    void (^_updateConstraintsBlock)();
}

@property(copy) void (^updateConstraintsBlock)();

@property(retain) NIView* view;

- (id)initWithView:(NIView*)view;
- (id)initWithView:(NIView*)view updateConstraints:(void (^)())updateConstraintsBlock;
- (id)initWithView:(NIView*)view updateConstraints:(void (^)())updateConstraintsBlock and:(void (^)(NIRetainer* r))block;
- (id)initWithTitle:(NSString*)title view:(NIView*)view updateConstraints:(void (^)())updateConstraintsBlock and:(void (^)(NIRetainer* r))block;

@end

@interface NSView (NI)

- (void)removeAllSubviews;
- (void)removeAllConstraints;

@end

@interface NIButton : NSButton {
    void (^_actionBlock)();
}

@property(copy) void (^actionBlock)();

- (id)initWithBlock:(void (^)())actionBlock;

@end

@interface NIBackgroundView : NIView {
    NSColor* _backgroundColor;
}

@property(retain) NSColor* backgroundColor;

- (id)initWithFrame:(NSRect)frameRect color:(NSColor*)backgroundColor;

@end
