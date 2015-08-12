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

@interface NIMPRPopUpButtonCell : NSPopUpButtonCell {
    NSString* (^_titleBlock)();
}

@property(copy) NSString* (^titleBlock)();

@end

@implementation NIMPRPopUpButtonCell

@synthesize titleBlock = _titleBlock;

- (void)dealloc {
    self.titleBlock = nil;
    [super dealloc];
}

- (NSString*)title {
    if (self.titleBlock)
        return self.titleBlock();
    return [super title];
}

@end

@interface NIMPRPopUpButton : NSPopUpButton {
    CGFloat _extraWidth;
}

@property(retain) NIMPRPopUpButtonCell* cell;

@end

@implementation NIMPRPopUpButton

@dynamic cell;

- (id)initWithFrame:(NSRect)buttonFrame pullsDown:(BOOL)flag {
    if ((self = [super initWithFrame:buttonFrame pullsDown:flag])) {
        self.cell = [[NIMPRPopUpButtonCell alloc] init];
    }
    
    return self;
}

- (void)updateConstraints {
 //   [self removeAllConstraints];
    [super updateConstraints];

    NSDictionary* attrs = @{ NSFontAttributeName: self.font };

    NSLayoutConstraint* wc = [[self.constraints filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"firstAttribute = %d", NSLayoutAttributeWidth]] lastObject];
    if (!_extraWidth) {
        CGFloat maxw = 0;
        for (NSString* title in self.itemTitles)
            maxw = CGFloatMax(maxw, [title sizeWithAttributes:attrs].width);
        _extraWidth = wc.constant - maxw;
    }
    
    [self removeConstraints:@[wc]];
    
    wc = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:[self.cell.title sizeWithAttributes:attrs].width+_extraWidth];
    wc.priority = NSLayoutPriorityDragThatCanResizeWindow;
    [self addConstraint:wc];
//    [self setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
//    [self setContentCompressionResistancePriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationHorizontal];
}

- (CGFloat)cellWidth {
    return 100;
}

@end

@interface NIMPRRegionGrowingTool ()

@property(readwrite, assign, nonatomic) NSPopover* popover;
@property(readwrite) BOOL popoverDetached;
@property(readwrite, retain) NISegmentationAlgorithm* algorithm;
@property(retain) NSOperation* segmentation;
@property(retain) NSArrayController* segmentationAlgorithms;

@end

@implementation NIMPRRegionGrowingTool

@dynamic annotation;
@synthesize popover = _popover;
@synthesize popoverDetached = _popoverDetached;
@synthesize algorithm = _algorithm;
@synthesize segmentation = _segmentation;
@synthesize seedPoint = _seedPoint;
@synthesize segmentationAlgorithms = _segmentationAlgorithms;

- (id)initWithViewer:(NIMPRWindowController *)viewer {
    if ((self = [super initWithViewer:viewer])) {
        self.seedPoint = NIMaskIndexInvalid;
        self.segmentationAlgorithms = [[[NSArrayController alloc] initWithContent:self.algorithms] autorelease];
        _segmentationAlgorithmsSelectionObserver = [[self.segmentationAlgorithms observeKeyPath:@"selection" options:NSKeyValueObservingOptionInitial block:^(NSDictionary *change) {
            self.algorithm = [self.segmentationAlgorithms.selectedObjects lastObject];
        }] retain];
        [self addObserver:self forKeyPath:@"algorithm" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NIMPRRegionGrowingTool.class];
        [self addObserver:self forKeyPath:@"seedPoint" options:0 context:NIMPRRegionGrowingTool.class];
//        [[self observeKeyPath:@"algorithm" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld block:^(NSDictionary *change) {
//            NSLog(@"%@", change);
//        }] retain];
    }
    
    return self;
}

- (void)dealloc {
    self.annotation = nil;
    [self removeObserver:self forKeyPath:@"seedPoint" context:NIMPRRegionGrowingTool.class];
    [self observeValueForKeyPath:@"algorithm" ofObject:self change:@{ NSKeyValueChangeOldKey: self.algorithm } context:NIMPRRegionGrowingTool.class];
    [self removeObserver:self forKeyPath:@"algorithm" context:NIMPRRegionGrowingTool.class];
    [_segmentationAlgorithmsSelectionObserver release]; _segmentationAlgorithmsSelectionObserver = nil;
    [_popover performClose:nil];
//    [_popover release];
//    self.algorithm = nil;
    self.segmentation = nil;
    self.segmentationAlgorithms = nil;
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

//+ (NSSet*)keyPathsForValuesAffectingAlgorithm {
//    return [NSSet setWithObject:@"segmentationAlgorithms.selectedObjects"];
//}
//
//- (NISegmentationAlgorithm*)algorithm {
//    return self.segmentationAlgorithms.selectedObjects.lastObject;
//}
//
//- (void)setAlgorithm:(NISegmentationAlgorithm *)algorithm {
//    [self.segmentationAlgorithms setSelectedObjects:@[algorithm]];
//}

//static NSString* const NIMPRRegionGrowingToolMenuDidCloseNotification = @"NIMPRRegionGrowingToolMenuDidCloseNotification";

- (NSViewController*)popoverViewController {
    NIView* view = [[[NIBackgroundView alloc] initWithFrame:NSZeroRect color:[NSColor.blackColor colorWithAlphaComponent:.8]] autorelease];
    
    NSTextField* label = [NIView labelWithControlSize:NSSmallControlSize];
    label.stringValue = NSLocalizedString(@"Region Growing", nil);
    [label addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:label.fittingSize.width]];
    [view addSubview:label];
    
    NIMPRPopUpButton* algorithms = [[[NIMPRPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO] autorelease];
    algorithms.translatesAutoresizingMaskIntoConstraints = NO;
    algorithms.controlSize = NSSmallControlSize;
    algorithms.font = [NSFont menuFontOfSize:[NSFont systemFontSizeForControlSize:algorithms.controlSize]];
    algorithms.menu.delegate = self;
//    for (NISegmentationAlgorithm* sac in self.algorithms)
//        [algorithms.menu addItemWithTitle:sac.name alt:sac.shortName block:^{
//            self.algorithm = sac;
//        }];
    [algorithms bind:@"content" toObject:self.segmentationAlgorithms withKeyPath:@"arrangedObjects" options:nil];
    [algorithms bind:@"contentObjects" toObject:self.segmentationAlgorithms withKeyPath:@"arrangedObjects" options:nil];
    [algorithms bind:@"contentValues" toObject:self.segmentationAlgorithms withKeyPath:@"arrangedObjects.name" options:nil];
    [algorithms bind:@"selectedIndex" toObject:self.segmentationAlgorithms withKeyPath:@"selectionIndex" options:nil];
    algorithms.cell.titleBlock = ^NSString*() {
        return [self.segmentationAlgorithms.selectedObjects.lastObject shortName];
    };
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

        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-lmargin-[label]->=h-|" options:0 metrics:mu views:NSDictionaryOfVariableBindings(label)]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-h-[algorithms]-h-|" options:0 metrics:mu views:NSDictionaryOfVariableBindings(algorithms)]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-h-[algorithm]-h-|" options:0 metrics:mu views:NSDictionaryOfVariableBindings(algorithm)]];
        
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-h-[annotation]-h-|" options:0 metrics:mu views:NSDictionaryOfVariableBindings(annotation)]];
        if (!annotation.isHidden)
            [v appendFormat:@"-v-[annotation]"];
        
        [v appendFormat:@"-v-|"];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:v options:0 metrics:mu views:NSDictionaryOfVariableBindings(label, algorithms, algorithm, annotation)]];
        
        NSLayoutConstraint* wc = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:CGFloatMax(view.fittingSize.width, 150)];
        wc.priority = NSLayoutPriorityDragThatCanResizeWindow;
        [view addConstraint:wc];
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
            view.needsUpdateConstraints = YES;
        }]];
        [r retain:[self observeKeyPaths:@[@"annotation", ] options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld block:^(NSDictionary *change) {
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
//        __unsafe_unretained __block NSLayoutConstraint* algorithmsWidthConstraint = nil;
//        [r retain:[algorithms.menu observeNotification:NSPopUpButtonWillPopUpNotification block:^(NSNotification *notification) {
//            [algorithms addConstraint:(algorithmsWidthConstraint = [NSLayoutConstraint constraintWithItem:algorithms attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:algorithms.frame.size.width])];
//        }]];
//        [r retain:[algorithms.menu observeNotification:NIMPRRegionGrowingToolMenuDidCloseNotification block:^(NSNotification *notification) {
//            [algorithms removeConstraint:algorithmsWidthConstraint];
//        }]];
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

//- (void)menuWillOpen:(NSMenu *)menu {
//    [menu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem* mi, NSUInteger i, BOOL* stop) {
//        mi.title = [self.segmentationAlgorithms.arrangedObjects[i] name];
//    }];
//}
//
//- (void)menuDidClose:(NSMenu *)menu {
//    [[NSNotificationCenter defaultCenter] postNotificationName:NIMPRRegionGrowingToolMenuDidCloseNotification object:menu];
//    [menu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem* mi, NSUInteger i, BOOL* stop) {
//        mi.title = [self.segmentationAlgorithms.arrangedObjects[i] shortName];
//    }];
//}

@end
