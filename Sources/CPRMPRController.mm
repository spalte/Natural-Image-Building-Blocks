//
//  MPRController.m
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRController.h"
#import <OsiriXAPI/CPRVolumeData.h>
#import "CPRIntersection.h"
#import "CPRMPRQuaternion.hpp"
#import "CPRMPRMenuAdditions.h"

@interface CPRMPRController ()

//@property N3AffineTransform transform;
@property(retain, readwrite) CPRMPRQuaternion *x, *y, *z;

@end

@implementation CPRMPRController

@synthesize leftrightSplit = _leftrightSplit;
@synthesize topbottomSplit = _topbottomSplit;
@synthesize topleftView = _topleftView;
@synthesize bottomleftView = _bottomleftView;
@synthesize rightView = _rightView;

@synthesize volumeData = _volumeData;
@synthesize windowWidth = _windowWidth, windowLevel = _windowLevel;
@synthesize displayOrientationLabels = _displayOrientationLabels, displayScaleBars = _displayScaleBars;
@synthesize menu = _menu;

@synthesize point = _point;
@synthesize x = _x, y = _y, z = _z;

@synthesize flags = _flags;

- (instancetype)initWithData:(CPRVolumeData*)volumeData {
    if ((self = [super initWithWindowNibName:@"CPRMPR" owner:self])) {
        self.volumeData = volumeData;
    }
    
    return self;
}

- (void)awakeFromNib {
    self.topleftView.color = [NSColor orangeColor];
    self.bottomleftView.color = [NSColor purpleColor];
    self.rightView.color = [NSColor blueColor];
    
    [self view:self.topleftView addIntersections:@{ @"abscissa": self.bottomleftView, @"ordinate": self.rightView }];
    [self view:self.bottomleftView addIntersections:@{ @"abscissa": self.rightView, @"ordinate": self.topleftView }];
    [self view:self.rightView addIntersections:@{ @"abscissa": self.bottomleftView, @"ordinate": self.topleftView }];

    for (CPRMPRView* view in @[ self.topleftView, self.bottomleftView, self.rightView ]) {
        [view bind:@"volumeData" toObject:self withKeyPath:@"volumeData" options:nil];
        [view bind:@"point" toObject:self withKeyPath:@"point" options:nil];
        [view bind:@"menu" toObject:self withKeyPath:@"menu" options:nil];
        [view bind:@"windowWidth" toObject:self withKeyPath:@"windowWidth" options:nil];
        [view bind:@"windowLevel" toObject:self withKeyPath:@"windowLevel" options:nil];
        [view bind:@"displayOrientationLabels" toObject:self withKeyPath:@"displayOrientationLabels" options:nil];
        [view bind:@"displayScaleBar" toObject:self withKeyPath:@"displayScaleBars" options:nil];
    }
    
    [self addObserver:self forKeyPath:@"volumeData" options:NSKeyValueObservingOptionInitial context:CPRMPRController.class];
    
    self.menu = [[NSMenu alloc] init];
    
    [self.menu addItemWithTitle:NSLocalizedString(@"Reset", nil) block:^{
        [self resetNormals];
    }];
    [self.menu addItemWithTitle:NSLocalizedString(@"Rotate view to orthogonal", nil) block:^{
        if ([self.window.firstResponder respondsToSelector:@selector(rotateToInitial)])
            [self.window.firstResponder performSelector:@selector(rotateToInitial) withObject:nil];
    }];
    [self.menu addItemWithTitle:NSLocalizedString(@"Rotate all to orthogonal", nil) block:^{
        for (CPRMPRView* view in @[ self.topleftView, self.bottomleftView, self.rightView ])
            [view rotateToInitial];
    }];

    [self.menu addItem:[NSMenuItem separatorItem]];
    
    [[self.menu addItemWithTitle:NSLocalizedString(@"Display orientation labels", nil) block:^{
        self.displayOrientationLabels = !self.displayOrientationLabels;
    }] bind:@"state" toObject:self withKeyPath:@"displayOrientationLabels" options:nil];
    
    [[self.menu addItemWithTitle:NSLocalizedString(@"Display scale bars", nil) block:^{
        self.displayScaleBars = !self.displayScaleBars;
    }] bind:@"state" toObject:self withKeyPath:@"displayScaleBars" options:nil];
    
}

- (void)view:(CPRMPRView*)view addIntersections:(NSDictionary*)others {
    [others enumerateKeysAndObjectsUsingBlock:^(NSString* key, CPRMPRView* other, BOOL* stop) {
        CPRIntersection* intersection = [[[CPRIntersection alloc] init] autorelease];
        intersection.thickness = 1;
        intersection.maskAroundMouseRadius = intersection.maskCirclePointRadius = 30;
        [intersection bind:@"color" toObject:other withKeyPath:@"color" options:nil];
        [intersection bind:@"intersectingObject" toObject:other withKeyPath:@"generatorRequest" options:nil];
        [view addIntersection:intersection forKey:key];
    }];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"volumeData" context:CPRMPRController.class];
    self.x = self.y = self.z = nil;
    self.volumeData = nil;
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != CPRMPRController.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"volumeData"]) {
        self.point = N3VectorApplyTransform(N3VectorMake(self.volumeData.pixelsWide/2, self.volumeData.pixelsHigh/2, self.volumeData.pixelsDeep/2), N3AffineTransformInvert(self.volumeData.volumeTransform));

        [self resetNormals];
        
        NSArray* views = @[ self.topleftView, self.bottomleftView, self.rightView ];
        
        CGFloat pixelSpacing = 0, pixelSpacingSize = 0;
        for (CPRMPRView* view in views) {
            CGFloat pss = fmin(NSWidth(view.frame), NSHeight(view.frame)), ps = pss/N3VectorDistance(N3VectorZero, N3VectorMake(self.volumeData.pixelsWide, self.volumeData.pixelsHigh, self.volumeData.pixelsDeep));
            if (!pixelSpacing || ps < pixelSpacing) {
                pixelSpacing = ps;
                pixelSpacingSize = pss;
            }
        }

        for (CPRMPRView* view in views)
            view.pixelSpacing = pixelSpacing/pixelSpacingSize*fmin(NSWidth(view.frame), NSHeight(view.frame));
    }
}

- (void)rotate:(CGFloat)rads axis:(N3Vector)axis excluding:(CPRMPRView*)eview {
    for (CPRMPRQuaternion* quaternion in @[ self.x, self.y, self.z ])
        [quaternion rotate:rads axis:axis];
    for (CPRMPRView* view in @[ self.topleftView, self.bottomleftView, self.rightView ])
        if (view != eview)
            [view rotate:rads axis:axis];
}

- (void)resetNormals {
    CPRMPRQuaternion* x = self.x = [CPRMPRQuaternion quaternion:N3VectorApplyTransformToDirectionalVector(N3VectorMake(1,0,0), self.volumeData.volumeTransform)];
    CPRMPRQuaternion* y = self.y = [CPRMPRQuaternion quaternion:N3VectorApplyTransformToDirectionalVector(N3VectorMake(0,1,0), self.volumeData.volumeTransform)];
    CPRMPRQuaternion* z = self.z = [CPRMPRQuaternion quaternion:N3VectorApplyTransformToDirectionalVector(N3VectorMake(0,0,1), self.volumeData.volumeTransform)];
    [self.topleftView setNormal:[x.copy autorelease]:[y.copy autorelease]:[z.copy autorelease] reference:y];
    [self.bottomleftView setNormal:[z.copy autorelease]:[x.copy autorelease]:[y.copy autorelease] reference:x];
    [self.rightView setNormal:[y.copy autorelease]:[x.copy autorelease]:[z.copy autorelease] reference:x];
}

@end
