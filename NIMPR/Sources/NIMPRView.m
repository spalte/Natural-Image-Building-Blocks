//
//  MPRView.m
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRView+Private.h"
#import "NIMPRView+Events.h"
#import "NIMPRController.h"
#import "NIMPRTool.h"
#import "NIMPRQuaternion.h"
#import <NIBuildingBlocks/NIVolumeDataProperties.h>
#import <NIBuildingBlocks/NIGeneratorRequest.h>
//#import <OsiriXAPI/NSImage+N2.h>
#import <Quartz/Quartz.h>

@implementation NIMPRView

@synthesize data = _data, dataProperties = _dataProperties, windowLevel = _windowLevel, windowWidth = _windowWidth, slabWidth = _slabWidth;
@synthesize point = _point, normal = _normal, xdir = _xdir, ydir = _ydir, reference = _reference;
@synthesize pixelSpacing = _pixelSpacing;
@synthesize menu = _menu;
@synthesize eventModifierFlags = _eventModifierFlags;
@synthesize blockGeneratorRequestUpdates = _blockGeneratorRequestUpdates;
@synthesize track = _track;
@synthesize flags = _flags;
@synthesize ltool = _ltool, rtool = _rtool, ltcAtSecondClick = _ltcAtSecondClick;
@synthesize mouseDown = _mouseDown;

- (void)initialize:(Class)class {
    [super initialize:class];

    if (class != NIGeneratorRequestView.class)
        return;
    
    [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"data" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"windowLevel" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"windowWidth" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"slabWidth" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"point" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"normal" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"xdir" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"ydir" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"pixelSpacing" options:0 context:NIMPRView.class];
//    [self bind:@"windowLevel" toObject:self withKeyPath:@"dataProperties.windowLevel" options:0];
//    [self bind:@"windowWidth" toObject:self withKeyPath:@"dataProperties.windowWidth" options:0];
    [self addObserver:self forKeyPath:@"window.windowController.spacebarDown" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"window.windowController.ltool" options:0 context:NIMPRView.class];

    self.rimThickness = 1;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"window.windowController.ltool" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"window.windowController.spacebarDown" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"pixelSpacing" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"ydir" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"xdir" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"normal" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"point" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"slabWidth" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"windowWidth" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"windowLevel" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"data" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"frame" context:NIMPRView.class];
    self.data = nil;
    self.ltool = self.rtool = nil;
    self.menu = nil;
    self.normal = self.xdir = self.ydir = self.reference = nil;
    self.track = nil;
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != NIMPRView.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"data"]) {
        NIVolumeData *o = [change[NSKeyValueChangeOldKey] if:NIVolumeData.class], *n = [change[NSKeyValueChangeNewKey] if:NIVolumeData.class];
        if (o) [self removeVolumeDataAtIndex:0];
        if (n) [self insertVolumeData:n atIndex:0];
        self.dataProperties = (n? [self volumeDataPropertiesAtIndex:0] : nil);
        self.dataProperties.preferredInterpolationMode = NIInterpolationModeCubic;
    }
    
    if ([keyPath isEqualToString:@"point"] || [keyPath isEqualToString:@"normal"] || [keyPath isEqualToString:@"xdir"] || [keyPath isEqualToString:@"ydir"] || [keyPath isEqualToString:@"pixelSpacing"] || [keyPath isEqualToString:@"slabWidth"]) {
        [self updateGeneratorRequest];
    }
    
    if ([keyPath isEqualToString:@"windowLevel"])
        self.dataProperties.windowLevel = self.windowLevel;
    if ([keyPath isEqualToString:@"windowWidth"])
        self.dataProperties.windowWidth = self.windowWidth;
    
    if ([keyPath isEqualToString:@"frame"]) {
        NSRect o = [change[NSKeyValueChangeOldKey] rectValue], n = [change[NSKeyValueChangeNewKey] rectValue];

        if (self.track) [self removeTrackingArea:self.track];
        [self addTrackingArea:(self.track = [[[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved+NSTrackingActiveInActiveApp owner:self userInfo:@{ @"NIMPRViewTrackingArea": @YES }] autorelease])];

        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        self.pixelSpacing = self.pixelSpacing / fmin(NSWidth(n), NSHeight(n)) * fmin(NSWidth(o), NSHeight(o));
        
        [CATransaction commit];
    }
    
    if ([keyPath isEqualToString:@"window.windowController.spacebarDown"] || [keyPath isEqualToString:@"window.windowController.ltool"]) {
        [self hover:nil location:[self convertPoint:[self.window convertPointFromScreen:[NSEvent mouseLocation]] fromView:nil]];
    }
}

- (void)setNormal:(NIMPRQuaternion*)normal :(NIMPRQuaternion*)xdir :(NIMPRQuaternion*)ydir reference:(NIMPRQuaternion*)reference {
    [self lockGeneratorRequestUpdates];
    self.xdir = xdir;
    self.ydir = ydir;
    self.normal = normal;
    self.reference = reference;
    [self unlockGeneratorRequestUpdates];
}

- (void)rotate:(CGFloat)rads axis:(NIVector)axis {
    [self lockGeneratorRequestUpdates];
    for (NIMPRQuaternion* quaternion in @[ self.normal, self.xdir, self.ydir ])
        [quaternion rotate:rads axis:axis];
    [self unlockGeneratorRequestUpdates];
}

- (void)rotateToInitial {
    [self rotate:NIVectorAngleBetweenVectorsAroundVector(self.xdir.vector, self.reference.vector, self.normal.vector) axis:self.normal.vector];
}

- (void)updateGeneratorRequest {
    if (self.blockGeneratorRequestUpdates)
        return;
    
    if (!self.pixelSpacing)
        return;
    
    NIVector edges[] = {{0,0,0},{1,1,1},{1,0,0},{0,1,1},{0,1,0},{1,0,1},{1,1,0},{0,0,1}}; // these 8 points define the 4 volume diagonals (1-2, 3-4, 5-6, 7-8)
    NIVectorApplyTransformToVectors(NIAffineTransformMakeScale(self.data.pixelsWide, self.data.pixelsHigh, self.data.pixelsDeep), edges, 8);
    NIVectorApplyTransformToVectors(self.data.volumeTransform, edges, 8);
    CGFloat maxdiameter = 0;
    for (size_t i = 0; i < 4; ++i)
        maxdiameter = fmax(maxdiameter, NIVectorDistance(edges[i*2], edges[i*2+1]));
    
    NIObliqueSliceGeneratorRequest* req = [[[NIObliqueSliceGeneratorRequest alloc] initWithCenter:self.point pixelsWide:NSWidth(self.frame) pixelsHigh:NSHeight(self.frame) xBasis:NIVectorScalarMultiply(self.xdir.vector, self.pixelSpacing) yBasis:NIVectorScalarMultiply(self.ydir.vector, self.pixelSpacing)] autorelease];
    if (self.slabWidth > 0) {
        req.slabWidth = self.slabWidth*maxdiameter;
        req.projectionMode = NIProjectionModeMIP;
    } else {
        req.slabWidth = 0;
        req.projectionMode = NIProjectionModeNone;
    }
    
    if (![req isEqual:self.generatorRequest])
        self.generatorRequest = req;
}

- (void)lockGeneratorRequestUpdates {
    ++self.blockGeneratorRequestUpdates;
}

- (void)unlockGeneratorRequestUpdates {
    [self generatorRequestUpdatesUnlock:YES];
}

- (void)generatorRequestUpdatesUnlock:(BOOL)update {
    if (--self.blockGeneratorRequestUpdates == 0)
        if (update)
            [self updateGeneratorRequest];
}

- (NIMPRTool*)ltool {
    return (_ltool? _ltool : [self.window.windowController ltool]);
}

- (NIMPRTool*)rtool {
    return (_rtool? _rtool : [self.window.windowController rtool]);
}

@end