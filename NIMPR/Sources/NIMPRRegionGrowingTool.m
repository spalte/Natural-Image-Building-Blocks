//
//  NIMPRRegionGrowTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRRegionGrowingTool.h"
#import "NIMaskAnnotation.h"
#import "NSView+NI.h"
#import "NIMPRWindowController+Toolbar.h"
#import "NIThresholdSegmentation.h"
#import "NSMenu+NIMPR.h"

@interface NIMPRRegionGrowingTool ()

@property(readwrite, assign, nonatomic) NSPopover* popover;
@property(readwrite) BOOL popoverDetached;
@property(readwrite, retain) NISegmentationAlgorithm* algorithm;
@property(retain) NSOperation* segmentation;

@end

@implementation NIMPRRegionGrowingTool

@dynamic annotation;
@synthesize popover = _popover;
@synthesize popoverDetached = _popoverDetached;
@synthesize algorithm = _algorithm;
@synthesize segmentation = _segmentation;
@synthesize seedPoint = _seedPoint;

- (id)initWithViewer:(NIMPRWindowController *)viewer {
    if ((self = [super initWithViewer:viewer])) {
        self.algorithm = self.algorithms[0];
        self.seedPoint = NIMaskIndexInvalid;
        [self addObserver:self forKeyPath:@"algorithm" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NIMPRRegionGrowingTool.class];
        [self addObserver:self forKeyPath:@"seedPoint" options:0 context:NIMPRRegionGrowingTool.class];
    }
    
    return self;
}

- (void)dealloc {
    self.annotation = nil;
    [self removeObserver:self forKeyPath:@"seedPoint" context:NIMPRRegionGrowingTool.class];
    [self observeValueForKeyPath:@"algorithm" ofObject:self change:@{ NSKeyValueChangeOldKey: self.algorithm } context:NIMPRRegionGrowingTool.class];
    [self removeObserver:self forKeyPath:@"algorithm" context:NIMPRRegionGrowingTool.class];
    [_popover performClose:nil];
//    [_popover release];
    self.algorithm = nil;
    self.segmentation = nil;
//    [_superviewObserver release];
//    [_observers release];
    [super dealloc];
}

- (void)dismissing {
   [_popover performClose:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != NIMPRRegionGrowingTool.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"algorithm"]) {
        [self observe:NO algorithm:[change[NSKeyValueChangeOldKey] if:NISegmentationAlgorithm.class]];
        [self observe:YES algorithm:[change[NSKeyValueChangeNewKey] if:NISegmentationAlgorithm.class]];
    }
    
    if (object == self.algorithm || [keyPath isEqualToString:@"algorithm"] || ([keyPath isEqualToString:@"seedPoint"] && !NIMaskIndexEqualToMaskIndex(self.seedPoint, NIMaskIndexInvalid))) {
//        if (self.annotation || [keyPath isEqualToString:@"seedPoint"]) {
        NIMaskIndex sp = _seedPoint;
        [self.segmentation cancel];
        if (self.annotation)
            [self.viewer.mutableAnnotations removeObject:self.annotation];
        
        _seedPoint = sp;
        if (!NIMaskIndexEqualToMaskIndex(self.seedPoint, NIMaskIndexInvalid)) {
            NIMask* mask = [[[NIMask alloc] initWithIndexes:@[[NSValue valueWithNIMaskIndex:self.seedPoint]]] autorelease];
            self.annotation = [[[NIMaskAnnotation alloc] initWithMask:mask transform:NIAffineTransformInvert(self.viewer.data.volumeTransform)] autorelease];
            self.annotation.locked = YES;
            [self.viewer.mutableAnnotations addObject:self.annotation];
        
            self.segmentation = [self segmentationWithSeed:self.seedPoint volume:self.viewer.data annotation:self.annotation];
        }
    }
}

- (void)observe:(BOOL)flag algorithm:(NISegmentationAlgorithm*)sa {
    for (NSString* kp in [sa.class keyPathsForValuesAffectingSegmentationAlgorithm])
        if (flag)
            [sa addObserver:self forKeyPath:kp options:0 context:NIMPRRegionGrowingTool.class];
        else [sa removeObserver:self forKeyPath:kp context:NIMPRRegionGrowingTool.class];
}

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^{
        NIVector miv = NIVectorApplyTransform(self.mouseDownLocationVector, view.data.volumeTransform);
        NIMaskIndex mi = {miv.x, miv.y, miv.z};
        self.seedPoint = mi;
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
                    r = NSInsetRect(ir, 0, 5);
                    break;
                }
            }
        _window = [sender window];
        [self.popover showRelativeToRect:r ofView:sender preferredEdge:NSMaxYEdge];
    } else [self.popover performClose:sender];
}

- (NSPopover*)popover {
    if (_popover)
        return _popover;
    
    NSPopover* po = _popover = [[[NSPopover alloc] init] autorelease];
    po.delegate = self;
    po.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    po.contentViewController = [self popoverViewController];
    
    return po;
}

- (void)popoverWillShow:(NSNotification*)notification {
    self.popoverDetached = NO;
    [self.popover.contentViewController.view setNeedsUpdateConstraints:YES];
}

- (void)popoverDidClose:(NSNotification *)notification {
//    _popover.contentViewController = nil;
    _popover = nil;
}

- (BOOL)popoverShouldDetach:(NSPopover*)popover {
    self.popoverDetached = YES;
    [self.popover.contentViewController.view setNeedsUpdateConstraints:YES];
    return YES;
}

- (NSOperation*)segmentationWithSeed:(NIMaskIndex)seed volume:(NIVolumeData*)data annotation:(NIMaskAnnotation*)ma {
    __block NSOperation* op = [NSBlockOperation blockOperationWithBlock:^{
        [self.algorithm processWithSeeds:@[[NSValue valueWithNIMaskIndex:seed]] volume:data annotation:ma operation:op];
        if (op.isCancelled)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.viewer.mutableAnnotations removeObject:ma];
            });
    }];
    
    NSOperationQueue* queue = [[[NSOperationQueue alloc] init] autorelease];
    [queue addOperation:op];

    return op;
}

- (NSArray*)algorithms {
    static NSArray* sas = nil;
    if (!sas)
        sas = [@[ [[[NIThresholdIntervalSegmentation alloc] init] autorelease],
                  [[[NIThresholdSegmentation alloc] init] autorelease] ] retain];
    return sas;
}

- (NSViewController*)popoverViewController {
    NIView* view = [[[NIBackgroundView alloc] initWithFrame:NSZeroRect color:[NSColor.blackColor colorWithAlphaComponent:.8]] autorelease];
    
    NSTextField* label = [NIView labelWithControlSize:NSSmallControlSize];
    label.stringValue = NSLocalizedString(@"Region Growing", nil);
    [label addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:label.fittingSize.width]];
    [view addSubview:label];
    
    NSPopUpButton* algorithms = [[[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO] autorelease];
    algorithms.translatesAutoresizingMaskIntoConstraints = NO;
    algorithms.controlSize = NSSmallControlSize;
    algorithms.font = [NSFont menuFontOfSize:[NSFont systemFontSizeForControlSize:algorithms.controlSize]];
    for (NISegmentationAlgorithm* sac in self.algorithms)
        [algorithms.menu addItemWithTitle:sac.name block:^{
            self.algorithm = sac;
        }];
    [view addSubview:algorithms];
    
    NSView* algorithm = [[[NSView alloc] initWithFrame:NSZeroRect] autorelease];
    algorithm.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:algorithm];
    
    NSView* annotation = [[[NSView alloc] initWithFrame:NSZeroRect] autorelease];
    annotation.translatesAutoresizingMaskIntoConstraints = NO;
    [annotation bind:@"hidden" toObject:self withKeyPath:@"annotation" options:@{ NSValueTransformerNameBindingOption: NSIsNilTransformerName }];
    [view addSubview:annotation];
    
    NSProgressIndicator* pi = [[[NSProgressIndicator alloc] initWithFrame:NSZeroRect] autorelease];
    pi.translatesAutoresizingMaskIntoConstraints = NO;
    pi.indeterminate = YES;
    pi.style = NSProgressIndicatorSpinningStyle;
    pi.controlSize = NSSmallControlSize;
    pi.displayedWhenStopped = NO;
    [pi bind:@"animate" toObject:self withKeyPath:@"segmentation.isExecuting" options:nil]; // @{ NSValueTransformerNameBindingOption: NSIsNilTransformerName }
    [annotation addSubview:pi];
    
    NSButton* cancel = [NIView buttonWithControlSize:NSSmallControlSize bezelStyle:NSRecessedBezelStyle title:NSLocalizedString(@"Cancel", nil) block:^{
        [self cancel];
    }];
    [annotation addSubview:cancel];
    
    NSButton* ok = [NIView buttonWithControlSize:NSSmallControlSize bezelStyle:NSRecessedBezelStyle title:NSLocalizedString(@"OK", nil) block:^{
        self.annotation = nil;
        self.segmentation = nil;
        [self cancel];
    }];
    [annotation addSubview:ok];
    
    NSDictionary* m = @{ @"s": @3, @"h": @8, @"v": @8 };
    [annotation addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[pi]-s-[cancel]-s-[ok]|" options:NSLayoutFormatAlignAllCenterY metrics:m views:NSDictionaryOfVariableBindings(pi, cancel, ok)]];
    [annotation addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[ok]|" options:0 metrics:m views:NSDictionaryOfVariableBindings(ok)]];
    
    return [[[NIViewController alloc] initWithView:view updateConstraints:^{
//        NSLog(@"Updating region growing tool constraints....");
        [view removeAllConstraints];
        NSDictionary* mu = [m dictionaryByAddingObject:(self.popoverDetached? @24 : @7) forKey:@"lmargin"];
        NSMutableString* v = [NSMutableString stringWithString:@"V:|-v-[label]-v-[algorithms]-v-[algorithm]"];

        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-lmargin-[label]-h-|" options:0 metrics:mu views:NSDictionaryOfVariableBindings(label)]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-h-[algorithms]-h-|" options:0 metrics:mu views:NSDictionaryOfVariableBindings(algorithms)]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-h-[algorithm]-h-|" options:0 metrics:mu views:NSDictionaryOfVariableBindings(algorithm)]];
        
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-h-[annotation]-h-|" options:0 metrics:mu views:NSDictionaryOfVariableBindings(annotation)]];
        if (!annotation.isHidden)
            [v appendFormat:@"-v-[annotation]"];
        
        [v appendFormat:@"-v-|"];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:v options:0 metrics:mu views:NSDictionaryOfVariableBindings(label, algorithms, algorithm, annotation)]];
    } and:^(__unsafe_unretained NIRetainer* r) {
        [r retain:[self observeKeyPath:@"algorithm" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew block:^(NSDictionary *change) {
            [algorithm removeAllSubviews];
            NISegmentationAlgorithm* sa = [change[NSKeyValueChangeNewKey] if:NISegmentationAlgorithm.class];
            if (!sa)
                return;
            NSView* view = sa.viewController.view;
            [algorithm addSubview:view];
            [algorithm addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[view]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)]];
            [algorithm addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)]];
        }]];
        [r retain:[self observeKeyPath:@"annotation" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld block:^(NSDictionary *change) {
            view.needsUpdateConstraints = YES;
            [r retain:[[change[NSKeyValueChangeNewKey] if:NIAnnotation.class] observeNotification:NIAnnotationRemovedNotification block:^(NSNotification *notification) {
                [self cancel];
            }] forKey:NIAnnotationRemovedNotification];
        }]];
        [r retain:[view observeKeyPath:@"window.parentWindow.frame" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld block:^(NSDictionary *change) {
            NSValue *nfv = [change[NSKeyValueChangeNewKey] if:NSValue.class], *ofv = [change[NSKeyValueChangeOldKey] if:NSValue.class];
            if (!nfv || !ofv || !_popoverDetached)
                return;
            NSRect frame = view.window.frame, nf = [nfv rectValue], of = [ofv rectValue];
            
            NSPoint delta = NSMakePoint(0, NSMaxY(nf)-NSMaxY(of));
            if (NSMidX(frame) < NSMidX(view.window.parentWindow.frame))
                delta.x = NSMinX(nf)-NSMinX(of);
            else delta.x = NSMaxX(nf)-NSMaxX(of);
            
            frame.origin = NSMakePoint(frame.origin.x+delta.x, frame.origin.y+delta.y);
            [view.window setFrame:frame display:YES];
        }]];
    }] autorelease]; // avoid retain cycles inside this object's retains dictionary
}

- (void)cancel {
    if (self.segmentation.isExecuting)
        [self.segmentation cancel];
    if (self.annotation && [self.viewer.annotations containsObject:self.annotation])
        [self.viewer.mutableAnnotations removeObject:self.annotation];
    self.seedPoint = NIMaskIndexInvalid;
    self.segmentation = nil;
    self.annotation = nil;
//    [self.popover performClose:nil];
}

@end
