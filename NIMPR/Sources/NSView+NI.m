//
//  NIBackgroundView.m
//  NIMPR
//
//  Created by Alessandro Volz on 8/3/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NSView+NI.h"

//NSString* const NIViewDidMoveToSuperviewNotification = @"NIViewDidMoveToSuperviewNotification";

@implementation NIView

@synthesize controller = _controller;

- (id)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return self;
}

- (void)updateConstraints {
    [super updateConstraints];
    [self.controller updateViewConstraints];
}

+ (id)labelWithControlSize:(NSControlSize)controlSize {
    NSTextField* r = [self.class fieldWithControlSize:controlSize];
    r.selectable = r.bordered = r.drawsBackground = NO;
    return r;
}

+ (id)fieldWithControlSize:(NSControlSize)controlSize {
    NSTextField* r = [[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    r.translatesAutoresizingMaskIntoConstraints = NO;
    r.controlSize = controlSize;
    r.font = [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:controlSize]];
    return r;
}

+ (id)buttonWithControlSize:(NSControlSize)controlSize bezelStyle:(NSBezelStyle)bezelStyle title:(NSString*)title block:(void (^)())actionBlock {
    NSButton* r = [[[NIButton alloc] initWithBlock:actionBlock] autorelease];
    r.translatesAutoresizingMaskIntoConstraints = NO;
    r.controlSize = NSSmallControlSize;
    r.title = title;
    if ((r.bezelStyle = bezelStyle) == NSRecessedBezelStyle)
        r.attributedTitle = [[[NSAttributedString alloc] initWithString:title attributes:@{ NSForegroundColorAttributeName: NSColor.whiteColor, NSFontAttributeName: [NSFont controlContentFontOfSize:[NSFont systemFontSizeForControlSize:controlSize]] }] autorelease];
    return r;
}

@end

@implementation NIViewController

@synthesize updateConstraintsBlock = _updateConstraintsBlock;

@dynamic view;

- (id)initWithView:(NIView*)view {
    return [self initWithView:view updateConstraints:nil];
}

- (id)initWithView:(NIView*)view updateConstraints:(void (^)())updateConstraintsBlock {
    return [self initWithView:view updateConstraints:updateConstraintsBlock and:nil];
}

- (id)initWithView:(NIView*)view updateConstraints:(void (^)())updateConstraintsBlock and:(void (^)(NIRetainer* r))block {
    return [self initWithTitle:nil view:view updateConstraints:updateConstraintsBlock and:block];
}

- (id)initWithTitle:(NSString*)title view:(NIView*)view updateConstraints:(void (^)())updateConstraintsBlock and:(void (^)(NIRetainer* r))block {
    if ((self = [super init])) {
        self.title = title;
        self.view = view;
        self.updateConstraintsBlock = updateConstraintsBlock;
        
        [self addObserver:self forKeyPath:@"updateConstraintsBlock" options:NSKeyValueObservingOptionInitial context:NIViewController.class];
        
        if (block)
            block(self.retainer);
    }
    
    return self;
}

- (void)dealloc {
    self.view.controller = nil;
    [self removeObserver:self forKeyPath:@"updateConstraintsBlock" context:NIViewController.class];
    self.updateConstraintsBlock = nil;
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != NIViewController.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"updateConstraintsBlock"]) {
        self.view.needsUpdateConstraints = YES;
    }
}

- (void)setView:(NIView*)view {
    view.controller = self;
    [super setView:view];
}

- (void)updateViewConstraints {
    if (self.updateConstraintsBlock) {
        self.updateConstraintsBlock();
        self.view.needsUpdateConstraints = NO;
    } else [self.view updateConstraints];
}

@end

@implementation NSView (NI)

- (void)removeAllSubviews {
    for (NSView* view in self.subviews)
        [view removeFromSuperview];
}

- (void)removeAllConstraints {
    [self removeConstraints:self.constraints];
}

@end

@implementation NIButton

@synthesize actionBlock = _actionBlock;

- (id)initWithBlock:(void (^)())actionBlock {
    if ((self = [super initWithFrame:NSZeroRect])) {
        self.actionBlock = actionBlock;
        self.target = self;
        self.action = @selector(_action:);
    }
    
    return self;
}

- (void)dealloc {
    self.actionBlock = nil;
    [super dealloc];
}

- (void)_action:(id)sender {
    if (self.actionBlock)
        self.actionBlock();
}

@end

@implementation NIBackgroundView

@synthesize backgroundColor = _backgroundColor;

- (id)initWithFrame:(NSRect)frameRect {
    return [self initWithFrame:frameRect color:nil];
}

- (id)initWithFrame:(NSRect)frameRect color:(NSColor*)backgroundColor {
    if ((self = [super initWithFrame:frameRect])) {
//        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = backgroundColor;
        [self addObserver:self forKeyPath:@"backgroundColor" options:0 context:NIBackgroundView.class];
    }
    
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"backgroundColor" context:NIBackgroundView.class];
    self.backgroundColor = nil;
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != NIBackgroundView.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"backgroundColor"]) {
        self.needsDisplay = YES;
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    if (self.backgroundColor) {
        [NSGraphicsContext saveGraphicsState];
//        [[NSAffineTransform transform] set];
//        [[NSBezierPath bezierPathWithRect:[self.window.contentView frame]] setClip];
        
        [self.backgroundColor set];
//        if (self != self.window.contentView)
            NSRectFill(self.bounds);
//        else NSRectFill(NSMakeRect(0, 0, self.window.frame.size.width, self.window.frame.size.height+20));
    
        [NSGraphicsContext restoreGraphicsState];
    }
    
    [super drawRect:dirtyRect];
}

- (void)viewWillDraw {
    if (self.needsUpdateConstraints)
        [self updateConstraints];
    [super viewWillDraw];
}

@end



