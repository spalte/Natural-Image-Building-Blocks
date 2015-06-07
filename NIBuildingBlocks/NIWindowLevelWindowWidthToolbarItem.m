//  Created by Joël Spaltenstein on 6/4/15.
//  Copyright (c) 2015 Spaltenstein Natural Image
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <QuartzCore/QuartzCore.h>

#import "NIWindowLevelWindowWidthToolbarItem.h"
#import "NIGeneratorRequestView.h"
#import "NIVolumeDataProperties.h"
#import "NIWindowingView.h"

@interface NIWindowLevelWindowWidthToolbarItemBackgroundView : NSView

@end

@implementation NIWindowLevelWindowWidthToolbarItemBackgroundView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);
}

@end

@implementation NIWindowLevelWindowWidthToolbarItem

@synthesize popover = _popover;
@synthesize windowingView = _windowingView;
@synthesize generatorRequestViews = _generatorRequestViews;
@synthesize volumeDataIndex = _volumeDataIndex;

- (instancetype)copyWithZone:(NSZone *)zone
{
    NIWindowLevelWindowWidthToolbarItem *copy = [super copyWithZone:zone];

    return copy;
}

- (void)dealloc
{
    _popover.contentViewController.view = nil;
    [_popover release];
    _popover = nil;

    if (_observingView) {
        [_windowingView removeObserver:self forKeyPath:@"windowLevel"];
        [_windowingView removeObserver:self forKeyPath:@"windowWidth"];
    }
    [_windowingView release];
    _windowingView = nil;

    [_volumeDataProperties release];
    _volumeDataProperties = nil;

    [_generatorRequestViews release];
    _generatorRequestViews = nil;

    [(NSButton *)self.view setTarget:nil];

    [super dealloc];
}

- (IBAction)_WLWWButtonPressed:(id)sender
{
    [self.popover showRelativeToRect:[self.view bounds] ofView:self.view preferredEdge:NSMaxXEdge];

    NSLog(@"pressed the button");
}

- (instancetype)initWithItemIdentifier:(NSString *)itemIdentifier
{
    if ( (self = [super initWithItemIdentifier:itemIdentifier])) {

        NSNib *nib = [[[NSNib alloc] initWithNibNamed:@"NIWindowLevelWindowWidthToolbarItem" bundle:[NSBundle bundleForClass:[NIWindowLevelWindowWidthToolbarItem class]]] autorelease];
        [nib instantiateWithOwner:self topLevelObjects:NULL];

        self.label = @"WL / WW";
        self.paletteLabel = @"Window Level / Window Width";
        self.toolTip = @"WL / WW";

        NSButton *WLWWButton = [[[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 38, 28)] autorelease];
        [WLWWButton setButtonType:NSMomentaryPushInButton];
        WLWWButton.bezelStyle = NSTexturedRoundedBezelStyle;
        WLWWButton.image = [[NSBundle bundleForClass:[NIWindowLevelWindowWidthToolbarItem class]] imageForResource:@"ContrastTemplate"];

        WLWWButton.target = self;
        WLWWButton.action = @selector(_WLWWButtonPressed:);
        self.view = WLWWButton;
        self.minSize = WLWWButton.frame.size;
        self.maxSize = WLWWButton.frame.size;
    }

    return self;
}

- (void)setGeneratorRequestViews:(NSArray *)generatorRequestViews
{
    if ([_generatorRequestViews isEqual:generatorRequestViews] == NO) {
        [_volumeDataProperties release];
        _volumeDataProperties = nil;

        for (NIGeneratorRequestView *oldView in _generatorRequestViews) {
            [oldView removeObserver:self forKeyPath:@"volumeDataProperties"];
        }
        [_generatorRequestViews release];
        _generatorRequestViews = nil;

        NSMutableArray *newRequestViews = [NSMutableArray array];
        NSMutableArray *newProperties = [NSMutableArray array];

        if (_observingView) {
            [_windowingView removeObserver:self forKeyPath:@"windowLevel"];
            [_windowingView removeObserver:self forKeyPath:@"windowWidth"];
        }

        for (NIGeneratorRequestView *view in generatorRequestViews) {
            [newRequestViews addObject:view];
            [view addObserver:self forKeyPath:@"volumeDataProperties" options:NSKeyValueObservingOptionNew context:NULL];
            if (view.volumeDataCount > _volumeDataIndex) {
                NIVolumeDataProperties *properties = [view volumeDataPropertiesAtIndex:_volumeDataIndex];
                [newProperties addObject:properties];

                _windowingView.windowLevel = properties.windowLevel;
                _windowingView.windowWidth = properties.windowWidth;
            }
        }

        [_windowingView addObserver:self forKeyPath:@"windowLevel" options:NSKeyValueObservingOptionNew context:NULL];
        [_windowingView addObserver:self forKeyPath:@"windowWidth" options:NSKeyValueObservingOptionNew context:NULL];
        _observingView = YES;

        _generatorRequestViews = [newRequestViews retain];
        _volumeDataProperties = [newProperties retain];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"windowLevel"] || [keyPath isEqualToString:@"windowWidth"]) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        for (NIVolumeDataProperties *properties in _volumeDataProperties) {
            [properties setValue:[object valueForKey:keyPath] forKey:keyPath];
        }
        [CATransaction commit];
    } else if ([keyPath isEqualToString:@"volumeDataProperties"]) {
        [_volumeDataProperties release];
        _volumeDataProperties = nil;

        NSMutableArray *newProperties = [NSMutableArray array];
        for (NIGeneratorRequestView *view in _generatorRequestViews) {
            if (view.volumeDataCount > _volumeDataIndex) {
                NIVolumeDataProperties *properties = [view volumeDataPropertiesAtIndex:_volumeDataIndex];
                [newProperties addObject:properties];

                _windowingView.windowLevel = properties.windowLevel;
                _windowingView.windowWidth = properties.windowWidth;
            }
        }
        _volumeDataProperties = [newProperties retain];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (BOOL)popoverShouldDetach:(NSPopover *)popover
{
    return YES;
}

@end
