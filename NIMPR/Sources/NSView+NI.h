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

- (instancetype)initWithView:(NIView*)view;
- (instancetype)initWithView:(NIView*)view updateConstraints:(void (^)())updateConstraintsBlock;
- (instancetype)initWithView:(NIView*)view updateConstraints:(void (^)())updateConstraintsBlock and:(void (^)(NIRetainer* r))block;
- (instancetype)initWithTitle:(NSString*)title view:(NIView*)view updateConstraints:(void (^)())updateConstraintsBlock and:(void (^)(NIRetainer* r))block;

@end

@interface NSView (NI)

- (void)removeAllSubviews;
- (void)removeAllConstraints;

@end

@interface NIButton : NSButton {
    void (^_actionBlock)();
}

@property(copy) void (^actionBlock)();

- (instancetype)initWithBlock:(void (^)())actionBlock;

@end

@interface NIBackgroundView : NIView {
    NSColor* _backgroundColor;
}

@property(retain) NSColor* backgroundColor;

- (instancetype)initWithFrame:(NSRect)frameRect color:(NSColor*)backgroundColor;

@end

@interface NISavePanel : NSSavePanel {
    NSDictionary* _allowedFileTypesDictionary;
}

@property(retain, nonatomic) NSDictionary* allowedFileTypesDictionary;

@end