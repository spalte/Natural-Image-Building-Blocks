//
//  MPRController.m
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRController+Private.h"
#import "NIMPRController+Toolbar.h"
#import <NIBuildingBlocks/NIIntersection.h>
#import <NIBuildingBlocks/NIVolumeData.h>
#import "NIMPRView.h"
#import "NIMPRQuaternion.h"
#import "NSMenu+NIMPR.h"

#import "NIImageAnnotation.h"

@implementation NIMPRController

@synthesize leftrightSplit = _leftrightSplit;
@synthesize topbottomSplit = _topbottomSplit;
@synthesize axialView = _axialView;
@synthesize sagittalView = _sagittalView;
@synthesize coronalView = _coronalView;

@synthesize data = _data;
@synthesize windowWidth = _windowWidth, windowLevel = _windowLevel, initialWindowLevel = _initialWindowLevel, initialWindowWidth = _initialWindowWidth;
@synthesize displayOrientationLabels = _displayOrientationLabels, displayScaleBars = _displayScaleBars, displayRims = _displayRims;
@synthesize menu = _menu;

@synthesize point = _point;
@synthesize x = _x, y = _y, z = _z;

@synthesize flags = _flags;

@synthesize ltoolTag = _ltoolTag, rtoolTag = _rtoolTag;
@synthesize ltool = _ltool, rtool = _rtool;

@synthesize projectionFlag = _projectionFlag;
@synthesize projectionMode = _projectionMode;
@synthesize slabWidth = _slabWidth;

@synthesize spacebarDown = _spacebarDown;

@synthesize displayOverlays = _displayOverlays;

@synthesize annotations = _annotations;
@synthesize highlightedAnnotations = _highlightedAnnotations;
@synthesize selectedAnnotations = _selectedAnnotations;

- (instancetype)initWithData:(NIVolumeData*)data window:(CGFloat)wl :(CGFloat)ww {
    if ((self = [super initWithWindowNibName:@"NIMPR" owner:self])) {
        self.data = data;
        self.initialWindowLevel = self.windowLevel = wl;
        self.initialWindowWidth = self.windowWidth = ww;
        self.ltoolTag = NIMPRToolWLWW;
        self.rtoolTag = NIMPRToolZoom;
        self.displayRims = YES;
        self.displayOverlays = YES;
        self.projectionMode = NIProjectionModeMIP;
        _annotations = [[NSMutableSet alloc] init];
        _highlightedAnnotations = [[NSMutableSet alloc] init];
        _selectedAnnotations = [[NSMutableSet alloc] init];
    }
    
    return self;
}

- (void)awakeFromNib {
    [self.axialView retain];
    [self.sagittalView retain];
    [self.coronalView retain];

    self.axialView.rimColor = [NSColor orangeColor];
    self.sagittalView.rimColor = [NSColor purpleColor];
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
        [view addObserver:self forKeyPath:@"annotations" options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIMPRController.class];
        [view addObserver:self forKeyPath:@"highlightedAnnotations" options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIMPRController.class];
        [view addObserver:self forKeyPath:@"selectedAnnotations" options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIMPRController.class];
    }
    
    [self addObserver:self forKeyPath:@"data" options:NSKeyValueObservingOptionInitial context:NIMPRController.class];
    [self addObserver:self forKeyPath:@"ltoolTag" options:NSKeyValueObservingOptionInitial context:NIMPRController.class];
    [self addObserver:self forKeyPath:@"rtoolTag" options:NSKeyValueObservingOptionInitial context:NIMPRController.class];
    [self addObserver:self forKeyPath:@"annotations" options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIMPRController.class];
    [self addObserver:self forKeyPath:@"highlightedAnnotations" options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIMPRController.class];
    [self addObserver:self forKeyPath:@"selectedAnnotations" options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIMPRController.class];
    
    self.menu = [[NSMenu alloc] init];
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
    [self removeObserver:self forKeyPath:@"selectedAnnotations" context:NIMPRController.class];
    [self removeObserver:self forKeyPath:@"highlightedAnnotations" context:NIMPRController.class];
    [self removeObserver:self forKeyPath:@"annotations" context:NIMPRController.class];
    [self removeObserver:self forKeyPath:@"rtoolTag" context:NIMPRController.class];
    [self removeObserver:self forKeyPath:@"ltoolTag" context:NIMPRController.class];
    [self removeObserver:self forKeyPath:@"data" context:NIMPRController.class];
    self.ltool = self.rtool = nil;
    self.x = self.y = self.z = nil;
    self.data = nil;
    [_selectedAnnotations release];
    [_highlightedAnnotations release];
    [_annotations release];
    
    [self.axialView release];
    [self.sagittalView release];
    [self.coronalView release];
    
    [super dealloc];
}

- (NSArray*)mprViews {
    return @[ self.axialView, self.sagittalView, self.coronalView ];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != NIMPRController.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if (object == self && [keyPath isEqualToString:@"data"]) {
        [self reset];
    }
    
    if (object == self && [keyPath isEqualToString:@"ltoolTag"]) {
        self.ltool = [[[[self toolClassForTag:self.ltoolTag] alloc] init] autorelease];
    }
    
    if (object == self && [keyPath isEqualToString:@"rtoolTag"]) {
        self.rtool = [[[[self toolClassForTag:self.rtoolTag] alloc] init] autorelease];
    }
    
    if ([keyPath isEqualToString:@"annotations"]) {
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
    
    CGFloat pixelSpacing = 0, pixelSpacingSize = 0;
    for (NIMPRView* view in self.mprViews) {
        CGFloat pss = fmin(NSWidth(view.frame), NSHeight(view.frame)), ps = pss/NIVectorDistance(NIVectorZero, NIVectorMake(self.data.pixelsWide, self.data.pixelsHigh, self.data.pixelsDeep));
        if (!pixelSpacing || ps < pixelSpacing) {
            pixelSpacing = ps;
            pixelSpacingSize = pss;
        }
    }
    
    for (NIMPRView* view in self.mprViews)
        view.pixelSpacing = pixelSpacing/pixelSpacingSize*fmin(NSWidth(view.frame), NSHeight(view.frame));
}

static NSString* const NIMPRControllerMenuAnnotationsDelimiter = @"NIMPRControllerMenuAnnotationsDelimiter";

- (void)menuWillOpen:(NSMenu*)menu {
//    [menu remove];
    
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
        NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:a.name action:nil keyEquivalent:@""] autorelease];
        mi.representedObject = a;
        mi.submenu = [[[NSMenu alloc] init] autorelease];
        
        NSArray* smis = a.menuItems;
        if (smis.count) {
            for (NSMenuItem* smi in a.menuItems)
                [mi.submenu addItem:smi];
            [mi.submenu addItem:[NSMenuItem separatorItem]];
        }
        
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

- (IBAction)test:(id)sender {
    NSOpenPanel* op = [NSOpenPanel openPanel];
    op.canChooseFiles = op.resolvesAliases = YES;
    op.canChooseDirectories = op.allowsMultipleSelection = NO;
    op.allowedFileTypes = [NSImage imageTypes];
    op.directoryURL = [NSURL fileURLWithPath:@"~"];
    op.message = NSLocalizedString(@"Select an image to insert.", nil);
    
    [op beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseAbort)
            return;
        
        NIMPRView* view = [[self.window firstResponder] if:NIMPRView.class];
        if (!view)
            view = self.coronalView;
        
        NSImage* image = [[[NSImage alloc] initWithContentsOfURL:op.URL] autorelease];
        
        NSPoint center = [view convertPointFromDICOMVector:self.point];
        
        NIObliqueSliceGeneratorRequest* req = view.presentedGeneratorRequest;
        NIAffineTransform planeToDicomTransform = NIAffineTransformTranslate(req.sliceToDicomTransform, center.x-image.size.width/2, center.y-image.size.height/2, 0);
        
        NIImageAnnotation* ia = [[NIImageAnnotation alloc] initWithImage:image transform:planeToDicomTransform];
//        ia.colorify = YES;
        
        [self.mutableAnnotations addObject:ia];
    }];
}

@end
