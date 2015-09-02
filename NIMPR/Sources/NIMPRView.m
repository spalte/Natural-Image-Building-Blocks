//
//  MPRView.m
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRView+Private.h"
#import "NIMPRView+Events.h"
#import "NIMPRWindowController.h"
#import "NIMPRTool.h"
#import "NIMPRQuaternion.h"
#import <NIBuildingBlocks/NIVolumeDataProperties.h>
#import <NIBuildingBlocks/NIGeneratorRequest.h>
#import "NIImageAnnotation.h"

@implementation NIMPRView

@synthesize data = _data, dataProperties = _dataProperties, windowLevel = _windowLevel, windowWidth = _windowWidth, slabWidth = _slabWidth, projectionMode = _projectionMode, projectionFlag = _projectionFlag;
@synthesize point = _point, normal = _normal, xdir = _xdir, ydir = _ydir, reference = _reference;
@synthesize pixelSpacing = _pixelSpacing;
@synthesize menu = _menu;
@synthesize eventModifierFlags = _eventModifierFlags;
@synthesize blockGeneratorRequestUpdates = _blockGeneratorRequestUpdates;
@synthesize track = _track;
@synthesize flags = _flags;
@synthesize ltool = _ltool, rtool = _rtool, ltcAtSecondClick = _ltcAtSecondClick;
@synthesize mouseDown = _mouseDown;
@synthesize displayOverlays = _displayOverlays, displayAnnotations = _displayAnnotations;
@synthesize toolsLayer = _toolsLayer;

- (void)initNIGeneratorRequestView {
    [super initNIGeneratorRequestView];
    
    CALayer* layer = self.toolsLayer = [[[CALayer alloc] init] autorelease];
    layer.delegate = self;
    layer.needsDisplayOnBoundsChange = YES;
    layer.zPosition = NIGeneratorRequestViewRimLayerZPosition+1;
    layer.contentsScale = self.frameLayer.contentsScale;
    [layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
    [layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
    [layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
    [layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];
    [self.frameLayer addSublayer:layer];
    
    self.projectionMode = NIProjectionModeMIP;
    
    [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"data" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"windowLevel" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"windowWidth" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"projectionFlag" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"projectionMode" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"slabWidth" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"point" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"normal" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"xdir" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"ydir" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"pixelSpacing" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"displayOverlays" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"displayAnnotations" options:0 context:NIMPRView.class];
//    [self bind:@"windowLevel" toObject:self withKeyPath:@"dataProperties.windowLevel" options:0];
//    [self bind:@"windowWidth" toObject:self withKeyPath:@"dataProperties.windowWidth" options:0];
    [self addObserver:self forKeyPath:@"window.windowController.spacebarDown" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"window.windowController.ltool" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"annotations" options:0 context:NIMPRView.class];
    [self addObserver:self forKeyPath:@"selectedAnnotations" options:0 context:NIMPRView.class];

    self.rimThickness = 1;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"selectedAnnotations" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"annotations" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"window.windowController.ltool" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"window.windowController.spacebarDown" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"displayAnnotations" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"displayOverlays" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"pixelSpacing" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"ydir" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"xdir" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"normal" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"point" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"slabWidth" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"projectionMode" context:NIMPRView.class];
    [self removeObserver:self forKeyPath:@"projectionFlag" context:NIMPRView.class];
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
    
    if ([keyPath isEqualToString:@"displayOverlays"]) {
        [self updateGeneratorRequest];
    }
    
    if ([keyPath isEqualToString:@"displayAnnotations"]) {
        [self.annotationsLayer setHidden:!self.displayAnnotations];
    }
    
    if ([keyPath isEqualToString:@"point"] || [keyPath isEqualToString:@"normal"] || [keyPath isEqualToString:@"xdir"] || [keyPath isEqualToString:@"ydir"] || [keyPath isEqualToString:@"pixelSpacing"] || [keyPath isEqualToString:@"projectionFlag"] || [keyPath isEqualToString:@"projectionMode"] || [keyPath isEqualToString:@"slabWidth"]) {
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
        
        [self updateGeneratorRequest];
    }
    
    if ([keyPath isEqualToString:@"window.windowController.spacebarDown"] || [keyPath isEqualToString:@"window.windowController.ltool"]) {
        [self flagsChanged:nil];
    }
    
    if ([keyPath isEqualToString:@"annotations"] || [keyPath isEqualToString:@"selectedAnnotations"]) {
        [self flagsChanged:[NSApp currentEvent]];
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
    
    CGFloat maxd = [self.data maximumDiagonal];
    
    NIObliqueSliceGeneratorRequest* req = [[[NIObliqueSliceGeneratorRequest alloc] initWithCenter:self.point pixelsWide:NSWidth(self.frame) pixelsHigh:NSHeight(self.frame) xBasis:NIVectorScalarMultiply(self.xdir.vector, self.pixelSpacing) yBasis:NIVectorScalarMultiply(self.ydir.vector, self.pixelSpacing)] autorelease];
    req.interpolationMode = NIInterpolationModeCubic;
    if (self.projectionFlag) {
        req.slabWidth = self.slabWidth*maxd;
        req.projectionMode = req.slabWidth? self.projectionMode : NIProjectionModeNone;
        if (req.slabWidth)
            req.interpolationMode = NIInterpolationModeNone; // the superposition of many slices should result in a smooth render anyway...
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

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if (layer == self.toolsLayer) {
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO]];
        
        for (NIMPRTool* tool in [self.rtools arrayByAddingObjectsFromArray:self.ltools])
            [tool drawInView:self];
        
        [NSGraphicsContext restoreGraphicsState];
    }
    
    [super drawLayer:layer inContext:ctx];
}

+ (NSSet*)keyPathsForValuesAffectingRimColor {
    return [NSSet setWithObject:@"displayOverlays"];
}

- (NSColor*)rimColor {
    if (self.displayOverlays)
        return [super rimColor];
    return [NSColor clearColor];
}

- (NIAnnotation*)annotationAtLocation:(NSPoint)location {
    NIAnnotation* annotation = nil;
    
    if (NSPointInRect(location, self.bounds))
        for (size_t i = 0; i < 2; ++i) { // first try by filtering out image annotations, then with them
            CGFloat distance;
            
            if (!i)
                annotation = [super annotationClosestToSlicePoint:location closestPoint:NULL distance:&distance filter:^BOOL(NIAnnotation* annotation) {
                    return ![annotation isKindOfClass:NIImageAnnotation.class];
                }];
            else
                annotation = [super annotationClosestToSlicePoint:location closestPoint:NULL distance:&distance];
            
            if (annotation && distance > NIAnnotationDistant)
                annotation = nil;
            
            if (annotation)
                break;
        }
    
    return annotation;
}

@end
