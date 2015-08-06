//
//  NIBackgroundView.m
//  NIMPR
//
//  Created by Alessandro Volz on 8/3/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NSView+NI.h"

//NSString* const NIViewDidMoveToSuperviewNotification = @"NIViewDidMoveToSuperviewNotification";

@interface NIBackgroundView ()

@property(retain) NSMutableArray* retains;

@end

@implementation NIBackgroundView

@synthesize backgroundColor = _backgroundColor;
@synthesize updateConstraintsBlock = _updateConstraintsBlock;
//@synthesize willMoveToSuperviewBlock = _willMoveToSuperviewBlock;
@synthesize retains = _retains;

- (id)initWithFrame:(NSRect)frameRect {
    return [self initWithFrame:frameRect color:nil];
}

- (id)initWithFrame:(NSRect)frameRect color:(NSColor*)backgroundColor {
    if ((self = [super initWithFrame:frameRect])) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = backgroundColor;
        [self addObserver:self forKeyPath:@"backgroundColor" options:0 context:NIBackgroundView.class];
        [self addObserver:self forKeyPath:@"updateConstraintsBlock" options:0 context:NIBackgroundView.class];
    }
    
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"updateConstraintsBlock" context:NIBackgroundView.class];
    [self removeObserver:self forKeyPath:@"backgroundColor" context:NIBackgroundView.class];
    self.retains = nil;
    self.backgroundColor = nil;
    self.updateConstraintsBlock = nil;
//    self.willMoveToSuperviewBlock = nil;
    [super dealloc];
}

- (id)retain:(id)obj {
    if (!self.retains)
        self.retains = [NSMutableArray array];
    [self.retains addObject:obj];
    return obj;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != NIBackgroundView.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"backgroundColor"]) {
        self.needsDisplay = YES;
    }
    
    if ([keyPath isEqualToString:@"updateConstraintsBlock"]) {
        self.needsUpdateConstraints = YES;
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    if (self.backgroundColor) {
        [self.backgroundColor set];
        NSRectFill(self.bounds);
    }
    
    [super drawRect:dirtyRect];
}

- (void)updateConstraints {
    [super updateConstraints];
    if (self.updateConstraintsBlock)
        self.updateConstraintsBlock();
}

//- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
//    if (self.willMoveToSuperviewBlock)
//        self.willMoveToSuperviewBlock(newSuperview);
//    [super viewWillMoveToSuperview:newSuperview];
//}

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
