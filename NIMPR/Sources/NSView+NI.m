//
//  NIBackgroundView.m
//  NIMPR
//
//  Created by Alessandro Volz on 8/3/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NSView+NI.h"

//NSString* const NIViewDidMoveToSuperviewNotification = @"NIViewDidMoveToSuperviewNotification";

@interface NIViewController ()

@property(retain) NSMutableDictionary* retains;

@end

@implementation NIViewController

@synthesize updateConstraintsBlock = _updateConstraintsBlock;
@synthesize retains = _retains;

- (id)initWithView:(NSView*)view {
    if ((self = [super init])) {
        self.view = view;
        [self addObserver:self forKeyPath:@"updateConstraintsBlock" options:0 context:NIViewController.class];
    }
    
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"updateConstraintsBlock" context:NIViewController.class];
    self.retains = nil;
    self.updateConstraintsBlock = nil;
    [super dealloc];
}

- (void)retain:(id)obj {
    [self retain:obj forKey:[NSValue valueWithPointer:obj]];
}

- (void)retain:(id)obj forKey:(id)key {
    if (!self.retains)
        self.retains = [NSMutableDictionary dictionary];
    if (obj)
        self.retains[key] = obj;
    else [self.retains removeObjectForKey:key];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != NIViewController.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"updateConstraintsBlock"]) {
        self.view.needsUpdateConstraints = YES;
    }
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    if (self.updateConstraintsBlock)
        self.updateConstraintsBlock();
}

@end

@implementation NSView (NI)

- (void)removeAllConstraints {
    [self removeConstraints:self.constraints];
}

@end

@implementation NIBackgroundView

@synthesize backgroundColor = _backgroundColor;

- (id)initWithFrame:(NSRect)frameRect {
    return [self initWithFrame:frameRect color:nil];
}

- (id)initWithFrame:(NSRect)frameRect color:(NSColor*)backgroundColor {
    if ((self = [super initWithFrame:frameRect])) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
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
        [self.backgroundColor set];
        NSRectFill(self.bounds);
    }
    
    [super drawRect:dirtyRect];
}

- (void)viewWillDraw {
    if (self.needsUpdateConstraints)
        [self updateConstraints];
    [super viewWillDraw];
}

@end

@implementation NSTextField (NI)

+ (instancetype)labelWithControlSize:(NSControlSize)controlSize {
    NSTextField* r = [self.class fieldWithControlSize:controlSize];
    r.selectable = r.bordered = r.drawsBackground = NO;
    return r;
}

+ (instancetype)fieldWithControlSize:(NSControlSize)controlSize {
    NSTextField* r = [[[self.class alloc] initWithFrame:NSZeroRect] autorelease];
    r.controlSize = controlSize;
    r.font = [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:controlSize]];
    r.translatesAutoresizingMaskIntoConstraints = NO;
    return r;
}

@end
