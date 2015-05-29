//
//  MPRView.m
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRView+Private.h"
#import "CPRMPRController.h"
#import "CPRMPRTool.h"
#import "CPRMPRQuaternion.h"
#import "CPRVolumeDataProperties.h"
#import <OsiriXAPI/CPRGeneratorRequest.h>
#import <OsiriXAPI/NSImage+N2.h>
#import <Quartz/Quartz.h>

@implementation CPRMPRView

@synthesize data = _data, dataProperties = _dataProperties, windowLevel = _windowLevel, windowWidth = _windowWidth, slabWidth = _slabWidth;
@synthesize point = _point, normal = _normal, xdir = _xdir, ydir = _ydir, reference = _reference;
@synthesize pixelSpacing = _pixelSpacing;//, rotation = _rotation;
@synthesize color = _color;
@synthesize menu = _menu;
@synthesize eventModifierFlags = _eventModifierFlags;
@synthesize blockGeneratorRequestUpdates = _blockGeneratorRequestUpdates;
@synthesize track = _track;
@synthesize flags = _flags;
@synthesize ltool = _ltool, rtool = _rtool;

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        [self initialize];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self initialize];
    }
    
    return self;
}

- (void)initialize {
    [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"data" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"windowLevel" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"windowWidth" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"slabWidth" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"point" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"normal" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"xdir" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"ydir" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"pixelSpacing" options:0 context:CPRMPRView.class];
//    [self bind:@"windowLevel" toObject:self withKeyPath:@"dataProperties.windowLevel" options:0];
//    [self bind:@"windowWidth" toObject:self withKeyPath:@"dataProperties.windowWidth" options:0];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"pixelSpacing" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"ydir" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"xdir" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"normal" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"point" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"slabWidth" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"windowWidth" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"windowLevel" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"data" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"frame" context:CPRMPRView.class];
    self.data = nil;
    self.ltool = self.rtool = nil;
    self.color = nil;
    self.menu = nil;
    self.normal = self.xdir = self.ydir = self.reference = nil;
    self.track = nil;
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != CPRMPRView.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"data"]) {
        CPRVolumeData *o = [change[NSKeyValueChangeOldKey] if:CPRVolumeData.class], *n = [change[NSKeyValueChangeNewKey] if:CPRVolumeData.class];
        if (o) [self removeVolumeDataAtIndex:0];
        if (n) [self insertVolumeData:n atIndex:0];
        self.dataProperties = (n? [self volumeDataPropertiesAtIndex:0] : nil);
        self.dataProperties.preferredInterpolationMode = CPRInterpolationModeCubic;
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
        [self addTrackingArea:(self.track = [[[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseMoved+NSTrackingActiveInActiveApp+NSTrackingInVisibleRect owner:self userInfo:@{ @"CPRMPRViewTrackingArea": @YES }] autorelease])];

        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        self.pixelSpacing = self.pixelSpacing / fmin(NSWidth(n), NSHeight(n)) * fmin(NSWidth(o), NSHeight(o));
        
        [CATransaction commit];
    }
}

- (void)setNormal:(CPRMPRQuaternion*)normal :(CPRMPRQuaternion*)xdir :(CPRMPRQuaternion*)ydir reference:(CPRMPRQuaternion*)reference {
    [self lockGeneratorRequestUpdates];
    self.xdir = xdir;
    self.ydir = ydir;
    self.normal = normal;
    self.reference = reference;
    [self unlockGeneratorRequestUpdates];
}

- (void)rotate:(CGFloat)rads axis:(N3Vector)axis {
    [self lockGeneratorRequestUpdates];
    for (CPRMPRQuaternion* quaternion in @[ self.normal, self.xdir, self.ydir ])
        [quaternion rotate:rads axis:axis];
    [self unlockGeneratorRequestUpdates];
}

- (void)rotateToInitial {
    [self rotate:N3VectorAngleBetweenVectorsAroundVector(self.xdir.vector, self.reference.vector, self.normal.vector) axis:self.normal.vector];
}

- (void)updateGeneratorRequest {
    if (self.blockGeneratorRequestUpdates)
        return;
    
    if (!self.pixelSpacing)
        return;
    
    N3Vector edges[] = {{0,0,0},{1,1,1},{1,0,0},{0,1,1},{0,1,0},{1,0,1},{1,1,0},{0,0,1}};
    N3VectorApplyTransformToVectors(self.data.volumeTransform, edges, 8);
    CGFloat maxdiameter = 0;
    for (size_t i = 0; i < 4; ++i)
        maxdiameter = fmax(maxdiameter, N3VectorDistance(edges[i*2], edges[i*2+1]));
    
    CPRObliqueSliceGeneratorRequest* req = [[[CPRObliqueSliceGeneratorRequest alloc] initWithCenter:self.point pixelsWide:NSWidth(self.frame) pixelsHigh:NSHeight(self.frame) xBasis:N3VectorScalarMultiply(self.xdir.vector, self.pixelSpacing) yBasis:N3VectorScalarMultiply(self.ydir.vector, self.pixelSpacing)] autorelease];
    if (self.slabWidth > 0) {
        req.slabWidth = self.slabWidth*maxdiameter;
        req.projectionMode = CPRProjectionModeMIP;
    } else {
        req.slabWidth = 0;
        req.projectionMode = CPRProjectionModeNone;
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

- (CPRMPRTool*)ltool {
    return (_ltool? _ltool : [self.window.windowController ltool]);
}

- (CPRMPRTool*)rtool {
    return (_rtool? _rtool : [self.window.windowController rtool]);
}

@end
