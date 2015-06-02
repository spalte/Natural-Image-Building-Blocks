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

@synthesize slabWidth = _slabWidth;

@synthesize spacebarDown = _spacebarDown;

- (instancetype)initWithData:(NIVolumeData*)data window:(CGFloat)wl :(CGFloat)ww {
    if ((self = [super initWithWindowNibName:@"NIMPR" owner:self])) {
        self.data = data;
        self.initialWindowLevel = self.windowLevel = wl;
        self.initialWindowWidth = self.windowWidth = ww;
        self.ltoolTag = NIMPRToolWLWW;
        self.rtoolTag = NIMPRToolZoom;
        self.displayRims = YES;
    }
    
    return self;
}

- (void)awakeFromNib {
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
        [view bind:@"slabWidth" toObject:self withKeyPath:@"slabWidth" options:nil];
    }
    
    [self addObserver:self forKeyPath:@"data" options:NSKeyValueObservingOptionInitial context:NIMPRController.class];
    [self addObserver:self forKeyPath:@"ltoolTag" options:NSKeyValueObservingOptionInitial context:NIMPRController.class];
    [self addObserver:self forKeyPath:@"rtoolTag" options:NSKeyValueObservingOptionInitial context:NIMPRController.class];
    
    self.menu = [[NSMenu alloc] init];
    
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
    [self removeObserver:self forKeyPath:@"rtoolTag" context:NIMPRController.class];
    [self removeObserver:self forKeyPath:@"ltoolTag" context:NIMPRController.class];
    [self removeObserver:self forKeyPath:@"data" context:NIMPRController.class];
    self.ltool = self.rtool = nil;
    self.x = self.y = self.z = nil;
    self.data = nil;
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
        self.ltool = [NIMPRTool toolForTag:self.ltoolTag];
    }
    
    if (object == self && [keyPath isEqualToString:@"rtoolTag"]) {
        self.rtool = [NIMPRTool toolForTag:self.rtoolTag];
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

- (void)reset {
    NIMPRQuaternion* x = self.x = [NIMPRQuaternion quaternion:NIVectorApplyTransformToDirectionalVector(NIVectorMake(1,0,0), self.data.volumeTransform)];
    NIMPRQuaternion* y = self.y = [NIMPRQuaternion quaternion:NIVectorApplyTransformToDirectionalVector(NIVectorMake(0,1,0), self.data.volumeTransform)];
    NIMPRQuaternion* z = self.z = [NIMPRQuaternion quaternion:NIVectorApplyTransformToDirectionalVector(NIVectorMake(0,0,1), self.data.volumeTransform)];
    
    [self.axialView setNormal:[x.copy autorelease]:[y.copy autorelease]:[z.copy autorelease] reference:y];
    [self.sagittalView setNormal:[z.copy autorelease]:[x.copy autorelease]:[y.copy autorelease] reference:x];
    [self.coronalView setNormal:[y.copy autorelease]:[x.copy autorelease]:[z.copy autorelease] reference:x];
    
    self.point = NIVectorApplyTransform(NIVectorMake(self.data.pixelsWide/2, self.data.pixelsHigh/2, self.data.pixelsDeep/2), NIAffineTransformInvert(self.data.volumeTransform));
    
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

@end
