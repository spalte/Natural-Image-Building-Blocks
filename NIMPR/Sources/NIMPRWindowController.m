//
//  MPRController.m
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRWindowController+Private.h"
#import "NIMPRWindowController+Toolbar.h"
#import <NIBuildingBlocks/NIIntersection.h>
#import <NIBuildingBlocks/NIVolumeData.h>
#import <NIBuildingBlocks/NIMaskData.h>
#import <objc/runtime.h>
#import "NIMPRWindow.h"
#import "NIMPRView.h"
#import "NIMPRQuaternion.h"
#import "NSMenu+NIMPR.h"
#import "NIPolyAnnotation.h"
#import "NSView+NI.h"
#import "NIJSON.h"
#import "NSData+zlib.h"

#import "NIImageAnnotation.h"
#import "NIMaskAnnotation.h"
#import "NIMPRRegionGrowingTool.h"

@implementation NIMPRWindowController

//@synthesize leftrightSplit = _leftrightSplit;
//@synthesize topbottomSplit = _topbottomSplit;
@synthesize axialView = _axialView;
@synthesize sagittalView = _sagittalView;
@synthesize coronalView = _coronalView;

@synthesize data = _data;
@synthesize windowWidth = _windowWidth, windowLevel = _windowLevel, initialWindowLevel = _initialWindowLevel, initialWindowWidth = _initialWindowWidth;
@synthesize displayOrientationLabels = _displayOrientationLabels, displayScaleBars = _displayScaleBars, displayRims = _displayRims, displayAnnotations = _displayAnnotations;
@synthesize menu = _menu;

@synthesize point = _point;
@synthesize x = _x, y = _y, z = _z;

@synthesize flags = _flags;

@synthesize ltoolTag = _ltoolTag, rtoolTag = _rtoolTag;
@synthesize ltool = _ltool, rtool = _rtool;

@synthesize viewsLayout = _viewsLayout;

@synthesize projectionFlag = _projectionFlag;
@synthesize projectionMode = _projectionMode;
@synthesize slabWidth = _slabWidth;

@synthesize spacebarDown = _spacebarDown;

@synthesize displayOverlays = _displayOverlays;

@synthesize annotations = _annotations;
@synthesize highlightedAnnotations = _highlightedAnnotations;
@synthesize selectedAnnotations = _selectedAnnotations;

- (instancetype)initWithData:(NIVolumeData*)data wl:(CGFloat)wl ww:(CGFloat)ww {
    return [self initWithData:data window:[[[NIMPRWindow alloc] initWithContentRect:NSMakeRect(10, 10, 800, 600)
                                                                          styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask
                                                                            backing:NSBackingStoreBuffered
                                                                              defer:NO] autorelease]
                           wl:wl ww:ww];
}

- (instancetype)initWithData:(NIVolumeData*)data window:(NSWindow*)window wl:(CGFloat)wl ww:(CGFloat)ww {
    if ((self = [super initWithWindow:window])) { // Path:[NIMPR.bundle pathForResource:@"NIMPR" ofType:]
        self.data = data;
        self.initialWindowLevel = self.windowLevel = wl;
        self.initialWindowWidth = self.windowWidth = ww;
        self.ltoolTag = NIMPRToolWLWW;
        self.rtoolTag = NIMPRToolZoom;
        self.displayRims = self.displayOverlays = self.displayAnnotations = YES;
        self.projectionMode = NIProjectionModeMIP;
        
        _annotations = [[NSMutableSet alloc] init];
        _highlightedAnnotations = [[NSMutableSet alloc] init];
        _selectedAnnotations = [[NSMutableSet alloc] init];
        
        window.delegate = self;
        window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
        window.titleVisibility = NSWindowTitleHidden;
        
        NSToolbar* toolbar = [[[NSToolbar alloc] initWithIdentifier:@"NIMPR"] autorelease];
        toolbar.allowsUserCustomization = window.toolbar.autosavesConfiguration = YES;
        toolbar.displayMode = NSToolbarDisplayModeIconOnly;
        toolbar.sizeMode = NSToolbarSizeModeSmall;
        toolbar.delegate = self;
        window.toolbar = toolbar;
        window.showsToolbarButton = YES;
        
        Class mprViewClass = [self.class mprViewClass];
        if (![mprViewClass isSubclassOfClass:NIMPRView.class])
            NSLog(@"Warning: MPR view class %@ should be a subclass of %@, will very likely crash", mprViewClass.className, NIMPRView.className);
        
        NSRect frame = NSMakeRect(0, 0, 100, 100);
        self.axialView = [[[mprViewClass alloc] initWithFrame:frame] autorelease];
        self.axialView.rimColor = [NSColor orangeColor];
        self.sagittalView = [[[mprViewClass alloc] initWithFrame:frame] autorelease];
        self.sagittalView.rimColor = [NSColor purpleColor];
        self.coronalView = [[[mprViewClass alloc] initWithFrame:frame] autorelease];
        self.coronalView.rimColor = [NSColor blueColor];

        [self view:self.axialView addIntersections:@{ @"abscissa": self.sagittalView, @"ordinate": self.coronalView }];
        [self view:self.sagittalView addIntersections:@{ @"abscissa": self.coronalView, @"ordinate": self.axialView }];
        [self view:self.coronalView addIntersections:@{ @"abscissa": self.sagittalView, @"ordinate": self.axialView }];

        for (NIMPRView* view in @[ self.axialView, self.sagittalView, self.coronalView ]) {
            [view bind:@"data" toObject:self withKeyPath:@"data" options:nil];
            [view bind:@"windowLevel" toObject:self withKeyPath:@"windowLevel" options:nil];
            [view bind:@"windowWidth" toObject:self withKeyPath:@"windowWidth" options:nil];
            [view bind:@"point" toObject:self withKeyPath:@"point" options:nil];
            [view bind:@"menu" toObject:self withKeyPath:@"menu" options:nil];
            [view bind:@"displayOrientationLabels" toObject:self withKeyPath:@"displayOrientationLabels" options:nil];
            [view bind:@"displayScaleBar" toObject:self withKeyPath:@"displayScaleBars" options:nil];
            [view bind:@"displayRim" toObject:self withKeyPath:@"displayRims" options:nil];
            [view bind:@"projectionFlag" toObject:self withKeyPath:@"projectionFlag" options:nil];
            [view bind:@"projectionMode" toObject:self withKeyPath:@"projectionMode" options:nil];
            [view bind:@"slabWidth" toObject:self withKeyPath:@"slabWidth" options:nil];
            [view bind:@"displayOverlays" toObject:self withKeyPath:@"displayOverlays" options:nil];
            [view bind:@"displayAnnotations" toObject:self withKeyPath:@"displayAnnotations" options:nil];
            [view addObserver:self forKeyPath:@"annotations" options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIMPRWindowController.class];
            [view addObserver:self forKeyPath:@"highlightedAnnotations" options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIMPRWindowController.class];
            [view addObserver:self forKeyPath:@"selectedAnnotations" options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIMPRWindowController.class];
        }
        
        [self addObserver:self forKeyPath:@"viewsLayout" options:NSKeyValueObservingOptionInitial+NSKeyValueObservingOptionNew context:NIMPRWindowController.class];
        [self addObserver:self forKeyPath:@"data" options:NSKeyValueObservingOptionInitial context:NIMPRWindowController.class];
        [self addObserver:self forKeyPath:@"ltoolTag" options:NSKeyValueObservingOptionInitial context:NIMPRWindowController.class];
        [self addObserver:self forKeyPath:@"rtoolTag" options:NSKeyValueObservingOptionInitial context:NIMPRWindowController.class];
        [self addObserver:self forKeyPath:@"annotations" options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIMPRWindowController.class];
        [self addObserver:self forKeyPath:@"highlightedAnnotations" options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIMPRWindowController.class];
        [self addObserver:self forKeyPath:@"selectedAnnotations" options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIMPRWindowController.class];
        
        [self reset];
        
        self.menu = [[[NSMenu alloc] init] autorelease];
        self.menu.delegate = self;
        
        [self.menu addItemWithTitle:NSLocalizedString(@"Reset this view's rotation", nil) block:^{
            if ([self.window.firstResponder isKindOfClass:NIMPRView.class])
                [(NIMPRView*)self.window.firstResponder rotateToInitial];
        }];
        [self.menu addItemWithTitle:NSLocalizedString(@"Reset all rotations", nil) block:^{
            [self rotateToInitial];
        }];
        [self.menu addItemWithTitle:NSLocalizedString(@"Reset all", nil) keyEquivalent:@"r" block:^{
            [self reset];
        }];
        
        [self.menu addItem:[NSMenuItem separatorItem]];
        
        [[self.menu addItemWithTitle:NSLocalizedString(@"Display orientation labels", nil) block:^{
            self.displayOrientationLabels = !self.displayOrientationLabels;
        }] bind:@"state" toObject:self withKeyPath:@"displayOrientationLabels" options:nil];
        
        [[self.menu addItemWithTitle:NSLocalizedString(@"Display scale bars", nil) block:^{
            self.displayScaleBars = !self.displayScaleBars;
        }] bind:@"state" toObject:self withKeyPath:@"displayScaleBars" options:nil];
        
        [[self.menu addItemWithTitle:NSLocalizedString(@"Display rims", nil) block:^{
            self.displayRims = !self.displayRims;
        }] bind:@"state" toObject:self withKeyPath:@"displayRims" options:nil];

        [self.menu addItem:[NSMenuItem separatorItem]];
        
        [self.menu addItemWithTitle:NSLocalizedString(@"Save annotations...", nil) block:^{
            NISavePanel* sp = (NISavePanel*)[NISavePanel savePanel];
            NSDictionary* ftds; [NIJSON fileTypes:&ftds];
            sp.allowedFileTypesDictionary = ftds;
            [sp beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
                if (result == NSFileHandlingPanelCancelButton)
                    return;
                [sp close];
                @try {
                    NSString* json = [NIJSONArchiver archivedStringWithRootObject:self.annotations.allObjects];
                    NSData* data = [json dataUsingEncoding:NSUTF8StringEncoding];
                    NSError* err = nil;
                    
                    if ([sp.URL.pathExtension.lowercaseString isEqualToString:NIJSONDeflatedAnnotationsFileType])
                        data = [data zlibDeflatedDataWithError:&err];
                    if (err) return [[NSAlert alertWithError:err] beginSheetModalForWindow:self.window completionHandler:nil];
                    
                    [data writeToURL:sp.URL options:NSDataWritingAtomic error:&err];
                    if (err) return [[NSAlert alertWithError:err] beginSheetModalForWindow:self.window completionHandler:nil];
                } @catch (NSException* e) {
                    [[NSAlert alertWithException:e] beginSheetModalForWindow:self.window completionHandler:nil];
                }
            }];
        }];
        
        [self.menu addItemWithTitle:NSLocalizedString(@"Load annotations...", nil) block:^{
            NSOpenPanel* op = [NSOpenPanel openPanel];
            op.allowedFileTypes = [NIJSON fileTypes:NULL];
            [op beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
                if (result == NSFileHandlingPanelCancelButton)
                    return;
                [op close];
                @try {
                    NSData* data = [NSData dataWithContentsOfURL:op.URL];
                    @try {
                        NSError* err = nil;
                        NSData* idata = [data zlibInflatedDataWithError:&err];
                        if (!err && idata) data = idata;
                    } @catch (...) {
                    }
                    
                    NSString* json = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
                    NSArray* ans = [NIJSONUnarchiver unarchiveObjectWithString:json];
                    [self.mutableAnnotations addObjectsFromArray:ans];
                } @catch (NSException* e) {
                    [[NSAlert alertWithException:e] beginSheetModalForWindow:self.window completionHandler:nil];
                }
            }];
        }];
}
    
    return self;
}

- (void)view:(NIMPRView*)view addIntersections:(NSDictionary*)others {
    [others enumerateKeysAndObjectsUsingBlock:^(NSString* key, NIMPRView* other, BOOL* stop) {
        NIIntersection* intersection = [[[NIIntersection alloc] init] autorelease];
        intersection.thickness = 1;
        intersection.maskAroundMouseRadius = intersection.maskCirclePointRadius = 30;
        [intersection bind:@"color" toObject:other withKeyPath:@"rimColor" options:nil];
        [intersection bind:@"intersectingObject" toObject:other withKeyPath:@"generatorRequest" options:nil];
        [view addIntersection:intersection forKey:key];
    }];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"viewsLayout" context:NIMPRWindowController.class];
    [self removeObserver:self forKeyPath:@"selectedAnnotations" context:NIMPRWindowController.class];
    [self removeObserver:self forKeyPath:@"highlightedAnnotations" context:NIMPRWindowController.class];
    [self observeValueForKeyPath:@"annotations" ofObject:self change:@{ NSKeyValueChangeOldKey: self.annotations } context:NIMPRWindowController.class];
    [self removeObserver:self forKeyPath:@"annotations" context:NIMPRWindowController.class];
    [self removeObserver:self forKeyPath:@"rtoolTag" context:NIMPRWindowController.class];
    [self removeObserver:self forKeyPath:@"ltoolTag" context:NIMPRWindowController.class];
    [self removeObserver:self forKeyPath:@"data" context:NIMPRWindowController.class];
    self.ltool = self.rtool = nil;
    self.x = self.y = self.z = nil;
    self.data = nil;
    [_selectedAnnotations release];
    [_highlightedAnnotations release];
    [_annotations release];
    
    self.axialView = nil;
    self.sagittalView = nil;
    self.coronalView = nil;
    
    [super dealloc];
}

- (NSApplicationPresentationOptions)window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions {
    return NSApplicationPresentationAutoHideDock|NSApplicationPresentationAutoHideMenuBar|NSApplicationPresentationFullScreen|NSApplicationPresentationAutoHideToolbar;
}

+ (Class)mprViewClass {
    return NIMPRView.class;
}

- (NSView*)mprViewsContainer {
    return [self.window contentView];
}

- (NSArray*)mprViews {
    return @[ self.axialView, self.sagittalView, self.coronalView ];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != NIMPRWindowController.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if (object == self && [keyPath isEqualToString:@"data"]) {
        [self reset];
    }
    
    if (object == self && [keyPath isEqualToString:@"ltoolTag"]) {
        if ([self.ltool respondsToSelector:@selector(dismissing)])
            [self.ltool dismissing];
        self.ltool = [[[[self toolClassForTag:self.ltoolTag] alloc] initWithViewer:self] autorelease];
    }
    
    if (object == self && [keyPath isEqualToString:@"rtoolTag"]) {
        if ([self.rtool respondsToSelector:@selector(dismissing)])
            [self.rtool dismissing];
        self.rtool = [[[[self toolClassForTag:self.rtoolTag] alloc] initWithViewer:self] autorelease];
    }
    
    if ([keyPath isEqualToString:@"annotations"]) {
        for (NIAnnotation* a in change[NSKeyValueChangeOldKey])
            [a removeObserver:self forKeyPath:@"annotation" context:NIMPRWindowController.class];
        for (NIAnnotation* a in change[NSKeyValueChangeNewKey])
            [a addObserver:self forKeyPath:@"annotation" options:NSKeyValueObservingOptionInitial context:NIMPRWindowController.class];
        for (id collector in [self.mprViews arrayByAddingObject:self]) {
            NSMutableSet* set = [collector mutableAnnotations];
            for (NIAnnotation* a in change[NSKeyValueChangeOldKey])
                [set removeObject:a];
            for (NIAnnotation* a in change[NSKeyValueChangeNewKey])
                [set addObject:a];
        }
    }
    
    if ([keyPath isEqualToString:@"highlightedAnnotations"]) {
        for (id collector in [self.mprViews arrayByAddingObject:self]) {
            NSMutableSet* set = [collector mutableHighlightedAnnotations];
            for (NIAnnotation* a in change[NSKeyValueChangeOldKey])
                [set removeObject:a];
            for (NIAnnotation* a in change[NSKeyValueChangeNewKey])
                [set addObject:a];
        }
    }
    
    if ([keyPath isEqualToString:@"selectedAnnotations"]) {
        for (id collector in [self.mprViews arrayByAddingObject:self]) {
            NSMutableSet* set = [collector mutableSelectedAnnotations];
            for (NIAnnotation* a in change[NSKeyValueChangeOldKey])
                [set removeObject:a];
            for (NIAnnotation* a in change[NSKeyValueChangeNewKey])
                [set addObject:a];
        }
    }
    
    if ([keyPath isEqualTo:@"annotation"]) {
        NIMask* mask = [object maskForVolume:self.data];
        NIMaskData* md = [[[NIMaskData alloc] initWithMask:[mask maskCroppedToWidth:self.data.pixelsWide height:self.data.pixelsHigh depth:self.data.pixelsDeep] volumeData:self.data] autorelease];
        NSLog(@"%@ mask: %X --- %@", object, mask, md);
    }
    
    if ([keyPath isEqualToString:@"viewsLayout"]) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];

        NSView* container = self.mprViewsContainer;
        [container removeAllSubviews];
        
        switch ([change[NSKeyValueChangeNewKey] integerValue]) {
            case NIMPRLayoutClassic: {
                NSSplitView* lrs = [[[NSSplitView alloc] initWithFrame:NSZeroRect] autorelease];
                lrs.translatesAutoresizingMaskIntoConstraints = NO;
                lrs.dividerStyle = NSSplitViewDividerStyleThin;
                lrs.vertical = YES;
                [container addSubview:lrs];
                [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[lrs]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(lrs)]];
                [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[lrs]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(lrs)]];
                NSSplitView* tbs = [[[NSSplitView alloc] initWithFrame:NSMakeRect(0, 0, (container.frame.size.width-lrs.dividerThickness)/2, container.frame.size.height)] autorelease];
                tbs.translatesAutoresizingMaskIntoConstraints = NO;
                tbs.dividerStyle = NSSplitViewDividerStyleThin;
                [lrs addSubview:tbs];
                [self.axialView setFrame:NSMakeRect(0, 0, (container.frame.size.width-lrs.dividerThickness)/2, (container.frame.size.height-lrs.dividerThickness)/2)];
                [tbs addSubview:self.axialView];
                [self.sagittalView setFrame:NSMakeRect(0, (container.frame.size.height-lrs.dividerThickness)/2+tbs.dividerThickness, (container.frame.size.width-lrs.dividerThickness)/2, (container.frame.size.height-lrs.dividerThickness)/2)];
                [tbs addSubview:self.sagittalView];
                [lrs addSubview:self.coronalView];
                [self.coronalView setFrame:NSMakeRect((container.frame.size.width-lrs.dividerThickness)/2+lrs.dividerThickness, 0, (container.frame.size.width-lrs.dividerThickness)/2, container.frame.size.height)];
                [lrs adjustSubviews];
                [tbs adjustSubviews];
            } break;
            case NIMPRLayoutVertical: {
                NSSplitView* split = [[[NSSplitView alloc] initWithFrame:NSZeroRect] autorelease];
                split.translatesAutoresizingMaskIntoConstraints = NO;
                split.dividerStyle = NSSplitViewDividerStyleThin;
                split.vertical = YES;
                [container addSubview:split];
                [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[split]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(split)]];
                [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[split]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(split)]];
                [self.axialView setFrame:NSMakeRect(0, 0, (container.frame.size.width-split.dividerThickness*2)/3, container.frame.size.height)];
                [split addSubview:self.axialView];
                [self.sagittalView setFrame:NSMakeRect((container.frame.size.width-split.dividerThickness*2)/3+split.dividerThickness, 0, (container.frame.size.width-split.dividerThickness*2)/3, container.frame.size.height)];
                [split addSubview:self.sagittalView];
                [self.coronalView setFrame:NSMakeRect((container.frame.size.width-split.dividerThickness*2)/3*2+split.dividerThickness*2, 0, (container.frame.size.width-split.dividerThickness*2)/3, container.frame.size.height)];
                [split addSubview:self.coronalView];
                [split adjustSubviews];
            } break;
            case NIMPRLayoutHorizontal: {
                NSSplitView* split = [[[NSSplitView alloc] initWithFrame:NSZeroRect] autorelease];
                split.translatesAutoresizingMaskIntoConstraints = NO;
                split.dividerStyle = NSSplitViewDividerStyleThin;
                [container addSubview:split];
                [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[split]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(split)]];
                [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[split]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(split)]];
                [self.axialView setFrame:NSMakeRect(0, 0, container.frame.size.width, (container.frame.size.height-split.dividerThickness*2)/3)];
                [split addSubview:self.axialView];
                [self.sagittalView setFrame:NSMakeRect(0, (container.frame.size.height-split.dividerThickness*2)/3+split.dividerThickness, container.frame.size.width, (container.frame.size.height-split.dividerThickness*2)/3)];
                [split addSubview:self.sagittalView];
                [self.coronalView setFrame:NSMakeRect(0, (container.frame.size.height-split.dividerThickness*2)/3*2+split.dividerThickness*2, container.frame.size.width, (container.frame.size.height-split.dividerThickness*2)/3)];
                [split addSubview:self.coronalView];
                [split adjustSubviews];
            } break;
        }
        
        [CATransaction commit];
    }
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
    [self.window willChangeValueForKey:@"frame"];
    return frameSize;
}

- (void)windowDidResize:(NSNotification *)notification {
    [self.window didChangeValueForKey:@"frame"];
}

- (void)rotate:(CGFloat)rads axis:(NIVector)axis excluding:(NIMPRView*)eview {
    for (NIMPRQuaternion* quaternion in @[ self.x, self.y, self.z ])
        [quaternion rotate:rads axis:axis];
    for (NIMPRView* view in self.mprViews)
        if (view != eview)
            [view rotate:rads axis:axis];
}

- (void)rotateToInitial {
    for (NIMPRView* view in self.mprViews)
        [view rotateToInitial];
}

- (void)moveToInitial {
    self.point = NIVectorApplyTransform(NIVectorMake(self.data.pixelsWide/2, self.data.pixelsHigh/2, self.data.pixelsDeep/2), NIAffineTransformInvert(self.data.volumeTransform));
}

- (void)reset {
    NIMPRQuaternion* x = self.x = [NIMPRQuaternion quaternion:NIVectorApplyTransformToDirectionalVector(NIVectorXBasis, self.data.volumeTransform)];
    NIMPRQuaternion* y = self.y = [NIMPRQuaternion quaternion:NIVectorApplyTransformToDirectionalVector(NIVectorYBasis, self.data.volumeTransform)];
    NIMPRQuaternion* z = self.z = [NIMPRQuaternion quaternion:NIVectorApplyTransformToDirectionalVector(NIVectorZBasis, self.data.volumeTransform)];
    
    [self.axialView setNormal:[x.copy autorelease]:[y.copy autorelease]:[z.copy autorelease] reference:y];
    [self.sagittalView setNormal:[z.copy autorelease]:[x.copy autorelease]:[y.copy autorelease] reference:x];
    [self.coronalView setNormal:[y.copy autorelease]:[x.copy autorelease]:[z.copy autorelease] reference:x];
    
    [self moveToInitial];
    
    self.windowLevel = self.initialWindowLevel;
    self.windowWidth = self.initialWindowWidth;
    
    CGFloat pixelSpacing = 0;//, pixelSpacingSize = 0;
//    for (NIMPRView* view in self.mprViews) {
//        CGFloat pss = fmin(NSWidth(view.frame), NSHeight(view.frame)), ps = pss/NIVectorDistance(NIVectorZero, NIVectorMake(self.data.pixelsWide, self.data.pixelsHigh, self.data.pixelsDeep));
//        if (!pixelSpacing || ps < pixelSpacing) {
//            pixelSpacing = ps;
//            pixelSpacingSize = pss;
//        }
//    }
    
    pixelSpacing = (self.data.pixelSpacingX+self.data.pixelSpacingY+self.data.pixelSpacingZ)/3;
    
    for (NIMPRView* view in self.mprViews)
        view.pixelSpacing = pixelSpacing;
//        view.pixelSpacing = pixelSpacing/pixelSpacingSize*fmin(NSWidth(view.frame), NSHeight(view.frame));
}

static NSString* const NIMPRControllerMenuAnnotationsDelimiter = @"NIMPRControllerMenuAnnotationsDelimiter";

- (void)menuWillOpen:(NSMenu*)menu {
    NSInteger i = 0;
    
    NSMenuItem* delimiter = [[menu.itemArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"representedObject = %@", NIMPRControllerMenuAnnotationsDelimiter]] lastObject];
    if (delimiter) {
        for (i = [menu.itemArray indexOfObject:delimiter]-1; i >= 0; --i)
            if ([[[menu itemAtIndex:i] representedObject] isKindOfClass:NIAnnotation.class])
                [menu removeItemAtIndex:i];
            else break;
        ++i;
    }
    
    for (NIAnnotation* a in self.highlightedAnnotations) {
        NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:[a.class name:a] action:nil keyEquivalent:@""] autorelease];
        mi.representedObject = a;
        mi.submenu = [[[NSMenu alloc] init] autorelease];
        
        [self menu:mi.submenu populateForAnnotation:a];
        
        [menu insertItem:mi atIndex:i++];
    }
    
    if (self.highlightedAnnotations.count) {
        if (!delimiter) {
            NSMenuItem* s = [NSMenuItem separatorItem];
            s.representedObject = NIMPRControllerMenuAnnotationsDelimiter;
            [menu insertItem:s atIndex:i];
        }
    } else if (delimiter)
        [menu removeItem:delimiter];
}

- (void)menu:(NSMenu*)menu populateForAnnotation:(id)a {
    [menu addItemWithTitle:NSLocalizedString(@"Delete", nil) block:^{
        [self.mutableAnnotations removeObject:a];
    }];
    if ([a isKindOfClass:NIPolyAnnotation.class]) {
        NSUInteger i = 0;
        [[menu insertItemWithTitle:NSLocalizedString(@"Smoothen", nil) block:^{
            [a setSmooth:![a smooth]];
        } atIndex:i++] bind:@"state" toObject:a withKeyPath:@"smooth" options:nil];
        [[menu insertItemWithTitle:NSLocalizedString(@"Close", nil) block:^{
            [a setClosed:![a closed]];
        } atIndex:i++] bind:@"state" toObject:a withKeyPath:@"closed" options:nil];
        [menu insertItem:[NSMenuItem separatorItem] atIndex:i++];
    }
}

- (NSMutableSet*)mutableAnnotations {
    return [self mutableSetValueForKey:@"annotations"];
}

- (void)addAnnotationsObject:(id)object {
    [_annotations addObject:object];
}

- (void)removeAnnotationsObject:(id)object {
    [_annotations removeObject:object];
}

- (NSMutableSet*)mutableHighlightedAnnotations {
    return [self mutableSetValueForKey:@"highlightedAnnotations"];
}

- (void)addHighlightedAnnotationsObject:(id)object {
    [_highlightedAnnotations addObject:object];
}

- (void)removeHighlightedAnnotationsObject:(id)object {
    [_highlightedAnnotations removeObject:object];
}

- (NSMutableSet*)mutableSelectedAnnotations {
    return [self mutableSetValueForKey:@"selectedAnnotations"];
}

- (void)addSelectedAnnotationsObject:(id)object {
    [_selectedAnnotations addObject:object];
}

- (void)removeSelectedAnnotationsObject:(id)object {
    [_selectedAnnotations removeObject:object];
}

- (IBAction)testImage:(id)sender {
    NSOpenPanel* op = [NSOpenPanel openPanel];
    op.canChooseFiles = op.resolvesAliases = YES;
    op.canChooseDirectories = op.allowsMultipleSelection = NO;
    op.allowedFileTypes = [NSImage imageTypes];
    op.directoryURL = [NSURL fileURLWithPath:@"~"];
    op.message = NSLocalizedString(@"Select an image to insert.", nil);
    
    [op beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton)
            return;
        
        NIMPRView* view = [[self.window firstResponder] if:NIMPRView.class];
        if (!view)
            view = self.coronalView;
        
        NIImageAnnotation* ia = [[[NIImageAnnotation alloc] initWithData:[NSData dataWithContentsOfURL:op.URL]] autorelease];
        NSPoint center = [view convertPointFromDICOMVector:self.point];
        ia.modelToDicomTransform = NIAffineTransformTranslate(view.presentedGeneratorRequest.sliceToDicomTransform, center.x-ia.image.size.width/2, center.y-ia.image.size.height/2, 0);
//        ia.colorify = YES;
        
        [self.mutableAnnotations addObject:ia];
    }];
}

- (IBAction)testMask:(id)sender {
    NIMask* mask = [NIMask maskWithSphereDiameter:30];
    
    NIAffineTransform modelToDicomTransform = NIAffineTransformMakeTranslationWithVector(NIVectorSubtract(self.point, NIVectorMake(15, 15, 15)));
    
    NIMaskAnnotation* ma = [[[NIMaskAnnotation alloc] initWithMask:mask transform:modelToDicomTransform] autorelease];
    ma.color = [NSColor.redColor colorWithAlphaComponent:0.5];
    
    [self.mutableAnnotations addObject:ma];
}

@end
