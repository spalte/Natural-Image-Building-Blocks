//
//  NIMPRRegionGrowTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRRegionGrowingTool.h"
#import "NIMaskAnnotation.h"
#import "NIBackgroundView.h"
#import "NIMPRController+Toolbar.h"
#import "NIThresholdSegmentation.h"
#import "NSMenu+NIMPR.h"

@interface NIMPRRegionGrowingTool ()

@property(readwrite, retain, nonatomic) NSPopover* popover;
@property(readwrite) BOOL popoverDetached;
@property(readwrite, retain) id <NISegmentationAlgorithm> segmentationAlgorithm;

@end

@implementation NIMPRRegionGrowingTool

@dynamic annotation;
@synthesize popover = _popover;
@synthesize popoverDetached = _popoverDetached;
@synthesize segmentationAlgorithm = _segmentationAlgorithm;

- (id)init {
    if ((self = [super init])) {
        self.segmentationAlgorithm = self.segmentationAlgorithms[0];
    }
    
    return self;
}

- (void)dealloc {
    [_popover performClose:nil];
    [_popover release];
    self.segmentationAlgorithm = nil;
//    [_superviewObserver release];
//    [_observers release];
    [super dealloc];
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    if (context != NIMPRRegionGrowingTool.class)
//        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//    
//    if ([keyPath isEqualToString:@"segmentationAlgorithm"]) {
//        self.popover.contentViewController.view.needsUpdateConstraints = YES;
//    }
//}

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^{
        NIVector miv = NIVectorApplyTransform(self.mouseDownLocationVector, view.data.volumeTransform);
        NIMaskIndex mi = {miv.x, miv.y, miv.z};
        
        NIMask* mask = [[[NIMask alloc] initWithIndexes:@[[NSValue valueWithNIMaskIndex:mi]]] autorelease];
        
        NIMaskAnnotation* ma = [[NIMaskAnnotation alloc] initWithMask:mask transform:NIAffineTransformInvert(view.data.volumeTransform)];
        ma.locked = YES;
        [view.mutableAnnotations addObject:ma];
        
        [self.class seed:mi volume:view.data annotation:ma];
    }];
}

- (void)toolbarItemAction:(id)sender {
    if (!self.popover.isShown) {
        NSEvent* event = [NSApp currentEvent];
        NSRect r = [sender bounds];
        if ([sender isKindOfClass:NIMPRSegmentedControl.class])
            for (NSInteger i = 0; i < [sender segmentCount]; ++i) {
                NSRect ir = [sender boundsForSegment:i];
                if (NSPointInRect([event locationInView:sender], [sender boundsForSegment:i])) {
                    r = NSInsetRect(ir, 0, 2);
                    break;
                }
            }
        [self.popover showRelativeToRect:r ofView:sender preferredEdge:NSMaxYEdge];
    } else [self.popover performClose:sender];
}

- (NSPopover*)popover {
    if (_popover)
        return _popover;
    
    NSPopover* po = _popover = [[NSPopover alloc] init];
    po.delegate = self;
    po.contentViewController = [[[NSViewController alloc] init] autorelease];
    po.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    po.contentViewController.view = [self popoverView];
    
    return po;
}

- (void)popoverWillShow:(NSNotification*)notification {
    self.popoverDetached = NO;
    [self.popover.contentViewController.view setNeedsUpdateConstraints:YES];
}

- (BOOL)popoverShouldDetach:(NSPopover*)popover {
    self.popoverDetached = YES;
    [self.popover.contentViewController.view setNeedsUpdateConstraints:YES];
    return YES;
}

- (NSOperation*)seed:(NIMaskIndex)seed volume:(NIVolumeData*)data annotation:(NIMaskAnnotation*)ma {
    NSBlockOperation* op = [NSBlockOperation blockOperationWithBlock:^{
        [self.segmentationAlgorithm processWithSeeds:@[[NSValue valueWithNIMaskIndex:seed]] volume:data annotation:ma operation:op];
    }];
    
    NSOperationQueue* queue = [[[NSOperationQueue alloc] init] autorelease];
    [queue addOperation:op];

    return op;
}

- (NSArray*)segmentationAlgorithms {
    static NSArray* sas = nil;
    if (!sas)
        sas = [@[ [[[NIThresholdIntervalSegmentation alloc] init] autorelease],
                  [[[NIThresholdSegmentation alloc] init] autorelease] ] retain];
    return sas;
}

- (NSView*)popoverView {
    NIBackgroundView* view = [[[NIBackgroundView alloc] initWithFrame:NSZeroRect color:[NSColor.blackColor colorWithAlphaComponent:.8]] autorelease];
    
    NSTextField* label = [[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    label.translatesAutoresizingMaskIntoConstraints = label.selectable = label.bordered = label.drawsBackground = NO;
    label.controlSize = NSSmallControlSize;
    label.font = [NSFont menuFontOfSize:[NSFont systemFontSizeForControlSize:label.controlSize]];
    label.stringValue = NSLocalizedString(@"Region Growing", nil);
    [view addSubview:label];
    
    NSPopUpButton* algorithms = [[[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO] autorelease];
    algorithms.translatesAutoresizingMaskIntoConstraints = NO;
    algorithms.focusRingType = NSFocusRingTypeNone;
    algorithms.controlSize = NSSmallControlSize;
    algorithms.font = [NSFont menuFontOfSize:[NSFont systemFontSizeForControlSize:algorithms.controlSize]];
    for (id <NISegmentationAlgorithm> sac in self.segmentationAlgorithms)
        [algorithms.menu addItemWithTitle:sac.name block:^{
            self.segmentationAlgorithm = sac;
//            algorithms.title = sac.shortName;
        }];
    [view addSubview:algorithms];
    
    NSView* algorithm = [[[NSView alloc] initWithFrame:NSZeroRect] autorelease];
    algorithm.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:algorithm];
    
    [view retain:[self observeKeyPath:@"segmentationAlgorithm" options:NSKeyValueObservingOptionInitial block:^(NSDictionary *change) {
        for (NSView* view in algorithm.subviews)
             [view removeFromSuperview];
        NSView* view = [self.segmentationAlgorithm view];
        [algorithm addSubview:view];
        [algorithm addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[view]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)]];
        [algorithm addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)]];
    }]];
    
    [label addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:label.fittingSize.width]];

    view.updateConstraintsBlock = ^{
        [view removeConstraints:view.constraints];
        NSDictionary* m = @{ @"h": @8, @"v": @8, @"lmargin": (_popoverDetached? @24 : @7) };
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-lmargin-[label]-h-|" options:0 metrics:m views:NSDictionaryOfVariableBindings(label)]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-h-[algorithms]-h-|" options:0 metrics:m views:NSDictionaryOfVariableBindings(algorithms)]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-h-[algorithm]-h-|" options:0 metrics:m views:NSDictionaryOfVariableBindings(algorithm)]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-v-[label]-v-[algorithms]-v-[algorithm]-v-|" options:0 metrics:m views:NSDictionaryOfVariableBindings(label, algorithms, algorithm)]];
    };
    
    return view;
}

@end
