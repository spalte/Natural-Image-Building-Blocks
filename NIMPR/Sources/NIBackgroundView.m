//
//  NIBackgroundView.m
//  NIMPR
//
//  Created by Alessandro Volz on 8/3/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIBackgroundView.h"

@implementation NIBackgroundView

@synthesize backgroundColor = _backgroundColor;

- (id)initWithFrame:(NSRect)frameRect color:(NSColor*)backgroundColor {
    if ((self = [super initWithFrame:frameRect])) {
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
        [self setNeedsDisplay:YES];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [self.backgroundColor set];
    [[NSBezierPath bezierPathWithRect:self.bounds] fill];
    [super drawRect:dirtyRect];
}

@end
