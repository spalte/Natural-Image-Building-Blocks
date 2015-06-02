//  Created by Joël Spaltenstein on 3/2/15.
//  Copyright (c) 2015 Spaltenstein Natural Image
//  Copyright (c) 2015 Michael Hilker and Andreas Holzamer
//  Copyright (c) 2015 volz io
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "NIGeneratorRequestView.h"
#import "NIFloatImageRep.h"
#import "NIGeneratorRequestLayer.h"
#import "NIOrientationTextLayer.h"
#import "NIScaleBarLayer.h"
#import "NIIntersection.h"
#import "NIIntersectionPrivate.h"
#import "NIObliqueSliceIntersectionLayer.h"
#import "NISprite.h"
#import "NISpritePrivate.h"
#import "NIVolumeDataProperties.h"
#import "NIVolumeDataPropertiesPrivate.h"

#import "NIVolumeData.h"
#import "NIGenerator.h"
#import "NIGeneratorRequest.h"

NSString* const NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotification = @"NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotification";

@interface NIGeneratorRequestView ()
@property (nonatomic, readwrite, copy) NIGeneratorRequest *presentedGeneratorRequest;
@property (nonatomic, readwrite, assign) NIVector mousePosition;

- (NIAffineTransform)_sliceToDicomTransform;
- (void)_updateLabelContraints;

@end

@interface NIGeneratorRequestViewOverlayDelegate : NSObject
{
    NIGeneratorRequestView *_view; // not retained
}
@property (nonatomic, readwrite, assign) NIGeneratorRequestView *view;
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
@end

@implementation NIGeneratorRequestViewOverlayDelegate
@synthesize view = _view;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO]];
    [_view drawOverlay];
    [NSGraphicsContext restoreGraphicsState];
}

@end

@interface NIGeneratorRequestViewLayoutManager : NSObject
{
    NIGeneratorRequestView *_view; // not retained
}
@property (nonatomic, readwrite, assign) NIGeneratorRequestView *view;
- (void)layoutSublayersOfLayer:(CALayer *)layer;
@end

@implementation NIGeneratorRequestViewLayoutManager
@synthesize view = _view;
- (void)layoutSublayersOfLayer:(CALayer *)layer;
{
    if ([_view inLiveResize]) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
    }
    for (CALayer *sublayer in layer.sublayers) {
        sublayer.frame = layer.bounds;

        if ([_view inLiveResize] && [sublayer.name isEqualToString:@"NIFrameLayer"]) {
            [sublayer layoutSublayers];
            for (CALayer *subsublayer in sublayer.sublayers) {
                [subsublayer layoutSublayers];
                if ([subsublayer.name isEqualToString:@"volumeDataComposingLayer"]) {
                    for (CALayer *generatorRequestLayer in subsublayer.sublayers) {
                        if ([generatorRequestLayer.name isEqualToString:@"NIGeneratorRequestLayer"]) {
                            [generatorRequestLayer display];
                            break;
                        }
                    }
                }
            }
        }
        [sublayer layoutSublayers];
    }
    if ([_view inLiveResize]) {
        [CATransaction commit];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    NSPoint pointInView = [_view convertPoint:theEvent.locationInWindow fromView:nil];
    _view.mousePosition = [_view convertPointToDICOMVector:pointInView];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    _view.mousePosition = NIGeneratorRequestViewMouseOutside;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    NSPoint pointInView = [_view convertPoint:theEvent.locationInWindow fromView:nil];
    _view.mousePosition = [_view convertPointToDICOMVector:pointInView];
}
@end


@implementation NIGeneratorRequestView

@synthesize generatorRequest = _generatorRequest;
@synthesize rimColor = _rimColor;
@synthesize frameLayer = _frameLayer;
@synthesize presentedGeneratorRequest = _presentedGeneratorRequest;
@synthesize mousePosition = _mousePosition;
@synthesize rimThickness = _rimThickness;

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initializeNIGeneratorRequestView];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializeNIGeneratorRequestView];
    }
    return self;
}

- (void)initializeNIGeneratorRequestView
{
    [self setWantsLayer:YES];
    
    [self setupFrameLayer];
    NIGeneratorRequestViewLayoutManager *layoutManager = [[[NIGeneratorRequestViewLayoutManager alloc] init] autorelease];
    layoutManager.view = self;
    self.layer.layoutManager = layoutManager;
    [self.layer addSublayer:_frameLayer];
    
    [self setupVolumeDataComposingLayer];
    _volumeDataProperties = [[NSMutableArray alloc] init];
    
    _intersections = [[NSMutableDictionary alloc] init];
    _intersectionTrackingAreas = [[NSMutableDictionary alloc] init];
    _sprites = [[NSMutableDictionary alloc] init];
    
    _mousePosition = NIGeneratorRequestViewMouseOutside;
    _mousePositionTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                              options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved| NSTrackingActiveInKeyWindow)
                                                                owner:self.layer.layoutManager
                                                             userInfo:nil];
    [self addTrackingArea:_mousePositionTrackingArea];

    [self setupRimLayer];
    [self setupOrientationLayers];
    [self setupScaleBarLayers];
    [self _updateLabelContraints];
    [self setupOverlayLayer];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_generatorRequest release];
    _generatorRequest = nil;

    _frameLayer.delegate = nil;
    [_frameLayer release];
    _frameLayer = nil;

    _rimLayer.delegate = nil;
    [_rimLayer release];
    _rimLayer = nil;

    _overlayLayer.delegate = nil;
    [_overlayLayer release];
    _overlayLayer = nil;
    _overlayLayerDelegate.view = nil;
    [_overlayLayerDelegate release];
    _overlayLayerDelegate = nil;

    for (NSString *intersectionKey in _intersections) {
        [(NIIntersection *)_intersections[intersectionKey] setGeneratorRequestView:nil];
    }
    [_intersections release];
    _intersections = nil;

    for (NSString *spriteKey in _sprites) {
        [(NISprite *)_sprites[spriteKey] setGeneratorRequestView:nil];
    }
    [_sprites release];
    _sprites = nil;

    [_intersectionTrackingAreas release];
    _intersectionTrackingAreas = nil;

     // This is because the layoutManager (which is also used as the _mousePositionTrackingArea owner) keeps a non-retained reference to the view
    [self removeTrackingArea:_mousePositionTrackingArea];
    self.layer.layoutManager = nil;
    [_mousePositionTrackingArea release];
    _mousePositionTrackingArea = nil;

    [_topOrientationTextLayer release];
    _topOrientationTextLayer = nil;
    [_bottomOrientationTextLayer release];
    _bottomOrientationTextLayer = nil;
    [_leftOrientationTextLayer release];
    _leftOrientationTextLayer = nil;
    [_rightOrientationTextLayer release];
    _rightOrientationTextLayer = nil;

    [_horizontalScaleBar release];
    _horizontalScaleBar = nil;
    [_verticalScaleBar release];
    _verticalScaleBar = nil;

    [_rimColor release];
    _rimColor = 0;

    for (NIVolumeDataProperties *properties in _volumeDataProperties) {
        properties.generatorRequestLayer = nil;
    }
    [_volumeDataProperties release];
    _volumeDataProperties = nil;

    if ([[_volumeDataComposingLayer sublayers] count]) {
        [[_volumeDataComposingLayer sublayers][0] removeObserver:self forKeyPath:@"presentedGeneratorRequest"];
    }
    [_volumeDataComposingLayer release];
    _volumeDataComposingLayer = nil;

    [_presentedGeneratorRequest release];
    _presentedGeneratorRequest = nil;

    [super dealloc];
}

- (void)setupFrameLayer
{
    _frameLayer = [[CALayer alloc] init];
    _frameLayer.contentsScale = self.layer.contentsScale;
    _frameLayer.name = @"NIFrameLayer";
    _frameLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
}

- (void)setupVolumeDataComposingLayer
{
    _volumeDataComposingLayer = [[CALayer alloc] init];

    _volumeDataComposingLayer.zPosition = NIGeneratorRequestViewRequestLayerZPosition;
    _volumeDataComposingLayer.name = @"volumeDataComposingLayer";
    _volumeDataComposingLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    [_volumeDataComposingLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
    [_volumeDataComposingLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
    [_volumeDataComposingLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
    [_volumeDataComposingLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];

    [_frameLayer addSublayer:_volumeDataComposingLayer];

}

- (void)setupRimLayer
{
    _rimLayer = [[CALayer alloc] init];
    _rimLayer.contentsScale = self.layer.contentsScale;
    _rimLayer.delegate = self;
    _rimLayer.needsDisplayOnBoundsChange = YES;
    _rimLayer.zPosition = NIGeneratorRequestViewRimLayerZPosition;
    [_rimLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
    [_rimLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
    [_rimLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
    [_rimLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];
    _rimThickness = 3;
}

- (void)setupOverlayLayer
{
    _overlayLayer = [[CALayer alloc] init];
    _overlayLayerDelegate = [[NIGeneratorRequestViewOverlayDelegate alloc] init];
    _overlayLayerDelegate.view = self;
    _overlayLayer.contentsScale = self.layer.contentsScale;
    _overlayLayer.delegate = _overlayLayerDelegate;
    _overlayLayer.name = @"overlayLayer";
    _overlayLayer.needsDisplayOnBoundsChange = YES;
    _overlayLayer.zPosition = NIGeneratorRequestViewRimLayerZPosition - 1;
    [_overlayLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
    [_overlayLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
    [_overlayLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
    [_overlayLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];
    [_frameLayer addSublayer:_overlayLayer];
}

- (void)setupOrientationLayers
{
    _topOrientationTextLayer = [[NIOrientationTextLayer alloc] init];
    _topOrientationTextLayer.contentsScale = self.layer.contentsScale;
    _topOrientationTextLayer.zPosition = NIGeneratorRequestViewRimLayerZPosition;
    _topOrientationTextLayer.name = @"topOrientationTextLayer";

    _bottomOrientationTextLayer = [[NIOrientationTextLayer alloc] init];
    _bottomOrientationTextLayer.contentsScale = self.layer.contentsScale;
    _bottomOrientationTextLayer.zPosition = NIGeneratorRequestViewRimLayerZPosition;
    _bottomOrientationTextLayer.name = @"bottomOrientationTextLayer";

    _leftOrientationTextLayer = [[NIOrientationTextLayer alloc] init];
    _leftOrientationTextLayer.contentsScale = self.layer.contentsScale;
    _leftOrientationTextLayer.zPosition = NIGeneratorRequestViewRimLayerZPosition;
    _leftOrientationTextLayer.name = @"leftOrientationTextLayer";

    _rightOrientationTextLayer = [[NIOrientationTextLayer alloc] init];
    _rightOrientationTextLayer.contentsScale = self.layer.contentsScale;
    _rightOrientationTextLayer.zPosition = NIGeneratorRequestViewRimLayerZPosition;
    _rightOrientationTextLayer.name = @"rightOrientationTextLayer";
}

- (void)setupScaleBarLayers
{
    _horizontalScaleBar = [[NIScaleBarLayer alloc] init];
    _horizontalScaleBar.contentsScale = self.layer.contentsScale;
    _horizontalScaleBar.orientation = NIScaleBarLayerHorizontalOrientation;
    _horizontalScaleBar.zPosition = NIGeneratorRequestViewRimLayerZPosition;
    _horizontalScaleBar.name = @"horizontalScaleBar";

    _verticalScaleBar = [[NIScaleBarLayer alloc] init];
    _verticalScaleBar.contentsScale = self.layer.contentsScale;
    _verticalScaleBar.orientation = NIScaleBarLayerVerticalOrientation;
    _verticalScaleBar.zPosition = NIGeneratorRequestViewRimLayerZPosition;
    _verticalScaleBar.name = @"verticalScaleBar";
}


- (void)setOverlayNeedsDisplay
{
    [_overlayLayer setNeedsDisplay];
}

- (void)drawOverlay
{
    
}

- (void)setDisplayRim:(BOOL)displayRim
{
    if (displayRim && [_rimLayer superlayer] == nil) {
        [_frameLayer addSublayer:_rimLayer];
    } else {
        [_rimLayer removeFromSuperlayer];
    }
}

- (BOOL)displayRim
{
    return [_rimLayer superlayer] != 0;
}

- (void)setDisplayOrientationLabels:(BOOL)displayOrientationLabels
{
    if (displayOrientationLabels && [_topOrientationTextLayer superlayer] == nil) {
        [_frameLayer addSublayer:_topOrientationTextLayer];
        [_frameLayer addSublayer:_bottomOrientationTextLayer];
        [_frameLayer addSublayer:_leftOrientationTextLayer];
        [_frameLayer addSublayer:_rightOrientationTextLayer];
    } else {
        [_topOrientationTextLayer removeFromSuperlayer];
        [_bottomOrientationTextLayer removeFromSuperlayer];
        [_leftOrientationTextLayer removeFromSuperlayer];
        [_rightOrientationTextLayer removeFromSuperlayer];
    }
    [self _updateLabelContraints];
}

- (BOOL)displayOrientationLabels
{
    return [_topOrientationTextLayer superlayer] != 0;
}

- (void)setDisplayScaleBar:(BOOL)displayScaleBar
{
    if (displayScaleBar && [_horizontalScaleBar superlayer] == nil) {
        [_frameLayer addSublayer:_horizontalScaleBar];
        [_frameLayer addSublayer:_verticalScaleBar];
    } else {
        [_horizontalScaleBar removeFromSuperlayer];
        [_verticalScaleBar removeFromSuperlayer];
    }
    [self _updateLabelContraints];
}

- (BOOL)displayScaleBar
{
    return [_horizontalScaleBar superlayer] != 0;
}

- (void)setGeneratorRequest:(NIGeneratorRequest *)generatorRequest
{
    if ([_generatorRequest isEqual:generatorRequest] == NO)
    {
        [_generatorRequest release];
        _generatorRequest = [generatorRequest retain];
        for (NIGeneratorRequestLayer *generatorRequestLayer in [_volumeDataComposingLayer sublayers]) {
            generatorRequestLayer.generatorRequest = _generatorRequest;
        }
    }
}

- (NSInteger)volumeDataCount
{
    return [[_volumeDataComposingLayer sublayers] count];
}

- (NIVolumeDataProperties *)addVolumeData:(NIVolumeData *)volumeData
{
    return [self insertVolumeData:volumeData atIndex:[self volumeDataCount]];
}

- (NIVolumeDataProperties *)insertVolumeData:(NIVolumeData *)volumeData atIndex:(NSUInteger)index
{
    [self willChangeValueForKey:@"volumeDataProperties"];
    NIGeneratorRequestLayer *generatorRequestLayer = [[[NIGeneratorRequestLayer alloc] init] autorelease];
    generatorRequestLayer.volumeData = volumeData;
    generatorRequestLayer.generatorRequest = _generatorRequest;
    generatorRequestLayer.preferredInterpolationMode = NIInterpolationModeNone;
#if CGFLOAT_IS_DOUBLE
    generatorRequestLayer.contentsScale = [self convertRectToBacking:self.bounds].size.width / self.bounds.size.width; // contentsScale on CAOpenGLLayers appears to be buggy in 32bit
#endif
    generatorRequestLayer.name = @"NIGeneratorRequestLayer";
    [generatorRequestLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
    [generatorRequestLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
    [generatorRequestLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
    [generatorRequestLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];

    if ([[_volumeDataComposingLayer sublayers] count] && index == 0) {
        [[_volumeDataComposingLayer sublayers][0] removeObserver:self forKeyPath:@"presentedGeneratorRequest"];
    }

    [_volumeDataComposingLayer insertSublayer:generatorRequestLayer atIndex:(unsigned)index];

    NIVolumeDataProperties *volumeDataProperties = [[[NIVolumeDataProperties alloc] init] autorelease];
    [volumeDataProperties setGeneratorRequestLayer:generatorRequestLayer];
    [_volumeDataProperties insertObject:volumeDataProperties atIndex:index];

    if (index == 0) {
        [generatorRequestLayer addObserver:self forKeyPath:@"presentedGeneratorRequest" options:(NSKeyValueObservingOptionNew) context:_volumeDataComposingLayer];
    }
    [self didChangeValueForKey:@"volumeDataProperties"];

    return volumeDataProperties;
}

- (void)removeVolumeDataAtIndex:(NSUInteger)index
{
    [self willChangeValueForKey:@"volumeDataProperties"];
    if ([[_volumeDataComposingLayer sublayers] count] && index == 0) {
        [[_volumeDataComposingLayer sublayers][0] removeObserver:self forKeyPath:@"presentedGeneratorRequest"];

        if ([[_volumeDataComposingLayer sublayers] count]) {
            [[_volumeDataComposingLayer sublayers][0] addObserver:self forKeyPath:@"presentedGeneratorRequest" options:(NSKeyValueObservingOptionNew) context:_volumeDataComposingLayer];
        }
    }

    [[_volumeDataComposingLayer sublayers][index] removeFromSuperview];
    [_volumeDataProperties[index] setGeneratorRequestLayer:nil];
    [_volumeDataProperties removeObjectAtIndex:index];
    [self didChangeValueForKey:@"volumeDataProperties"];
}

- (NIVolumeData *)volumeDataAtIndex:(NSUInteger)index
{
    return [[_volumeDataComposingLayer sublayers][index] volumeData];
}

- (NSMutableDictionary *)volumeDataPropertiesAtIndex:(NSUInteger)index
{
    return [_volumeDataProperties objectAtIndex:index];
}

- (void)setRimColor:(NSColor *)rimColor
{
    if (rimColor != _rimColor) {
        [_rimColor release];
        _rimColor = [rimColor retain];
        [_rimLayer setNeedsDisplay];
    }
}

- (void)setRimThickness:(CGFloat)rimThickness {
    if (_rimThickness != rimThickness) {
        _rimThickness = rimThickness;
        [_rimLayer setNeedsDisplay];
    }
}

- (NIAffineTransform)_sliceToDicomTransform // this is not smart enough yet to handle curved slices
{
    NIGeneratorRequest *generatorRequest = self.presentedGeneratorRequest;

    if ([generatorRequest isKindOfClass:[NIObliqueSliceGeneratorRequest class]]) {
        NIObliqueSliceGeneratorRequest *obliqueGeneratorRequest = (NIObliqueSliceGeneratorRequest *)generatorRequest;
        NIAffineTransform sliceTransform = obliqueGeneratorRequest.sliceToDicomTransform;
        sliceTransform = NIAffineTransformConcat(NIAffineTransformMakeScale((CGFloat)generatorRequest.pixelsWide / _volumeDataComposingLayer.bounds.size.width,
                                                                            (CGFloat)generatorRequest.pixelsHigh / _volumeDataComposingLayer.bounds.size.height, 1), sliceTransform);
        return sliceTransform;
    } else {
        return NIAffineTransformIdentity;
    }
}

- (void)addIntersection:(NIIntersection *)intersection forKey:(NSString *)key
{
    NIObliqueSliceIntersectionLayer *newLayer = [[[NIObliqueSliceIntersectionLayer alloc] init] autorelease];
    intersection.intersectionLayer = newLayer;
    intersection.generatorRequestView = self;

    newLayer.contentsScale = self.layer.contentsScale;
    newLayer.zPosition = NIGeneratorRequestViewIntersectionZPosition;
    newLayer.name = [NSString stringWithFormat:@"IntersectionLayer: %@", key];
    newLayer.sliceToDicomTransform = [self _sliceToDicomTransform];
    [newLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
    [newLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
    [newLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
    [newLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];

    NSTrackingArea *trackingArea = [[[NSTrackingArea alloc] initWithRect:self.bounds
                                                                 options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow)
                                                                 owner:intersection
                                                             userInfo:nil] autorelease];
    [_frameLayer addSublayer:newLayer];
    [self addTrackingArea:trackingArea];
    [_intersections setObject:intersection forKey:key];
    [_intersectionTrackingAreas setObject:trackingArea forKey:key];
}

- (NIIntersection *)intersectionForKey:(NSString *)key
{
    return [_intersections objectForKey:key];
}

- (void)removeAllIntersections
{
    NSArray *intersectionKeys = [self intersectionKeys];
    for (NSString *key in intersectionKeys) {
        [self removeIntersectionForKey:key];
    }
}

- (void)removeIntersectionForKey:(NSString *)key
{
    NIIntersection *intersection = [self intersectionForKey:key];
    CALayer<NISliceIntersectionLayer> *intersectionLayer = intersection.intersectionLayer;
    [intersectionLayer removeFromSuperlayer];
    intersection.generatorRequestView = nil;
    [_intersections removeObjectForKey:key];
    [self removeTrackingArea:[_intersectionTrackingAreas objectForKey:key]];
    [_intersectionTrackingAreas removeObjectForKey:key];
}

- (NSArray *)intersectionKeys
{
    return [_intersections allKeys];
}

- (void)enumerateIntersectionsWithBlock:(void (^)(NSString *key, NIIntersection *intersection, BOOL *stop))block {
    [_intersections enumerateKeysAndObjectsUsingBlock:block];
}

- (NSString *)intersectionClosestToPoint:(NSPoint)point closestPoint:(NSPoint *)rclosestPoint distance:(CGFloat *)rdistance
{
    NSString * closestKey = nil;
    CGFloat closestDistance = CGFLOAT_MAX;
    NSPoint closestPoint;
    
    for (NSString *iterKey in _intersections) {
        NSPoint iterClosestPoint;
        CGFloat iterDistance = [(NIIntersection *)_intersections[iterKey] distanceToPoint:point closestPoint:&iterClosestPoint];
        if (iterDistance < closestDistance) {
            closestDistance = iterDistance;
            closestKey = iterKey;
            closestPoint = iterClosestPoint;
        }
    }
    
    if (closestKey) {
        if (rdistance)
            *rdistance = closestDistance;
        if (rclosestPoint)
            *rclosestPoint = closestPoint;
    }
    
    return closestKey;
}

- (void)addSprite:(NISprite *)sprite forKey:(NSString *)key
{
    sprite.layer.contentsScale = self.layer.contentsScale;
    sprite.layer.zPosition = NIGeneratorRequestViewSpriteZPosition;
    sprite.layer.name = [NSString stringWithFormat:@"SpriteLayer: %@", key];
    sprite.generatorRequestView = self;

    [_sprites setObject:sprite forKey:key];
}

- (NISprite *)spriteForKey:(NSString *)key
{
    return [_sprites objectForKey:key];
}

- (void)removeAllSprites
{
    for (NSString *key in _sprites) {
        [self removeSpriteForKey:key];
    }
}

- (void)removeSpriteForKey:(NSString *)key
{
    NISprite *sprite = [self spriteForKey:key];
    [sprite.layer removeFromSuperlayer];
    [_sprites removeObjectForKey:key];
}

- (NSArray *)spriteKeys
{
    return [_sprites allKeys];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    for (id intersection in [_intersections allValues]) {
        [intersection mouseMoved:(NSEvent *)theEvent];
    }
    [self.layer.layoutManager mouseMoved:(NSEvent *)theEvent];
    [super mouseDragged:theEvent];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    for (NSTrackingArea *trackingArea in [_intersectionTrackingAreas allValues]) {
        [self removeTrackingArea:trackingArea];
    }
    [_intersectionTrackingAreas removeAllObjects];

    for (NSString *key in _intersections) {
        NIIntersection *intersection = [_intersections objectForKey:key];
        NSTrackingArea *trackingArea = [[[NSTrackingArea alloc] initWithRect:self.bounds
                                                                     options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow)
                                                                       owner:intersection
                                                                    userInfo:nil] autorelease];
        [_intersectionTrackingAreas setObject:trackingArea forKey:key];
        [self addTrackingArea:trackingArea];
    }
    [self removeTrackingArea:_mousePositionTrackingArea];
    [_mousePositionTrackingArea release];
    _mousePositionTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                              options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow)
                                                                owner:self.layer.layoutManager
                                                             userInfo:nil];
    [self addTrackingArea:_mousePositionTrackingArea];

}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    if (layer == _rimLayer) {
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO]];

        // align the bounds to pixel boundries
        NSRect boundsRect = NSRectFromCGRect(_rimLayer.bounds);
        boundsRect.size.width *= _rimLayer.contentsScale;
        boundsRect.size.height *= _rimLayer.contentsScale;
        boundsRect = NSIntegralRectWithOptions(boundsRect, NSAlignMinXOutward | NSAlignMinYOutward | NSAlignMaxXInward | NSAlignMaxYInward);
        boundsRect.size.width /= _rimLayer.contentsScale;
        boundsRect.size.height /= _rimLayer.contentsScale;

        [_rimColor set];
        CGFloat rimThickness = self.rimThickness;

        NSRect drawRect = boundsRect;
        drawRect.size.height = rimThickness;
        NSRectFill(drawRect);

        drawRect.origin.y = boundsRect.size.height - rimThickness;
        NSRectFill(drawRect);

        drawRect = boundsRect;
        drawRect.origin.y = rimThickness;
        drawRect.size.height = boundsRect.size.height - (rimThickness / 2.0);
        drawRect.size.width = rimThickness;
        NSRectFill(drawRect);

        drawRect.origin.x = boundsRect.size.width - rimThickness;
        NSRectFill(drawRect);

        // corner square
        CGFloat squareSize = 12.0;
        drawRect.size.width = squareSize - rimThickness;
        drawRect.size.height = squareSize - rimThickness;
        drawRect.origin.x = boundsRect.size.width - squareSize;
        drawRect.origin.y = boundsRect.size.height - squareSize;
        NSRectFill(drawRect);

        [NSGraphicsContext restoreGraphicsState];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"presentedGeneratorRequest"] && context == _volumeDataComposingLayer) {
        self.presentedGeneratorRequest = [(NIGeneratorRequestLayer *)object presentedGeneratorRequest];
        [[NSNotificationCenter defaultCenter] postNotificationName:NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotification object:self];
        if ([self inLiveResize] == NO) {
            NSPoint pointInView = [self convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];
            if (NSPointInRect(pointInView, self.bounds)) {
                self.mousePosition = [self convertPointToDICOMVector:pointInView];
            } else {
                self.mousePosition = NIGeneratorRequestViewMouseOutside;
            }
        }

        [_overlayLayer setNeedsDisplay];

        if ([self.presentedGeneratorRequest isKindOfClass:[NIObliqueSliceGeneratorRequest class]]) {
            NIObliqueSliceGeneratorRequest *obliqueRequest = (NIObliqueSliceGeneratorRequest *)self.generatorRequest;
            _bottomOrientationTextLayer.orientationVector = NIVectorInvert(obliqueRequest.directionY);
            _topOrientationTextLayer.orientationVector = obliqueRequest.directionY;
            _leftOrientationTextLayer.orientationVector = NIVectorInvert(obliqueRequest.directionX);
            _rightOrientationTextLayer.orientationVector = obliqueRequest.directionX;

            _horizontalScaleBar.pointSpacing = NIVectorDistance([self convertPointToDICOMVector:NSZeroPoint], [self convertPointToDICOMVector:NSMakePoint(0, 1)]);
            _verticalScaleBar.pointSpacing = NIVectorDistance([self convertPointToDICOMVector:NSZeroPoint], [self convertPointToDICOMVector:NSMakePoint(0, 1)]);

            NIAffineTransform sliceToDicomTransfrom = [self _sliceToDicomTransform];
            for (NIIntersection *intersection in [_intersections allValues]) {
                [(NIObliqueSliceIntersectionLayer *)intersection.intersectionLayer setSliceToDicomTransform:sliceToDicomTransfrom];
            }
        } else {
            _bottomOrientationTextLayer.orientationVector = NIVectorZero;
            _topOrientationTextLayer.orientationVector = NIVectorZero;
            _leftOrientationTextLayer.orientationVector = NIVectorZero;
            _rightOrientationTextLayer.orientationVector = NIVectorZero;
            _horizontalScaleBar.pointSpacing = 0;
            _verticalScaleBar.pointSpacing = 0;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSPoint)convertPointFromDICOMVector:(NIVector)vector
{
    NIGeneratorRequest *presentedGeneratorRequest = [self presentedGeneratorRequest];
    if (presentedGeneratorRequest == nil) {
        return NSZeroPoint;
    }

    NIVector requestVector = [presentedGeneratorRequest convertVolumeVectorFromDICOMVector:vector];

    requestVector.x += 0.5;
    requestVector.y += 0.5;

    requestVector.x *= self.bounds.size.width / presentedGeneratorRequest.pixelsWide;
    requestVector.y *= self.bounds.size.height / presentedGeneratorRequest.pixelsHigh;

    return NSPointFromNIVector(requestVector);
}

- (NIVector)convertPointToDICOMVector:(NSPoint)point
{
    NIGeneratorRequest *presentedGeneratorRequest = [self presentedGeneratorRequest];
    if (presentedGeneratorRequest == nil) {
        return NIVectorZero;
    }

    point.x *= presentedGeneratorRequest.pixelsWide / self.bounds.size.width;
    point.y *= presentedGeneratorRequest.pixelsHigh / self.bounds.size.height;

    point.x -= .5;
    point.y -= .5;

    return [presentedGeneratorRequest convertVolumeVectorToDICOMVector:NIVectorMakeFromNSPoint(point)];
}

- (NSBezierPath *)convertBezierPathFromDICOM:(NIBezierPath *)bezierPath
{
    NSBezierPath *newBezierPath = [NSBezierPath bezierPath];
    NSUInteger elementCount = [bezierPath elementCount];
    NSUInteger i;
    NIBezierPathElement pathElement;
    NIVector control1;
    NIVector control2;
    NIVector endPoint;

    for (i = 0; i < elementCount; i++) {
        pathElement = [bezierPath elementAtIndex:i control1:&control1 control2:&control2 endpoint:&endPoint];

        switch (pathElement) {
            case NIMoveToBezierPathElement:
                [newBezierPath moveToPoint:[self convertPointFromDICOMVector:endPoint]];
                break;
            case NILineToBezierPathElement:
                 [newBezierPath lineToPoint:[self convertPointFromDICOMVector:endPoint]];
                break;
            case NICurveToBezierPathElement:
                 [newBezierPath curveToPoint:[self convertPointFromDICOMVector:endPoint]
                               controlPoint1:[self convertPointFromDICOMVector:control1]
                               controlPoint2:[self convertPointFromDICOMVector:control2]];
                break;
            case NICloseBezierPathElement:
                [newBezierPath closePath];
                break;
        }
    }

    return newBezierPath;
}

- (NIBezierPath *)convertBezierPathToDICOM:(NSBezierPath *)bezierPath
{
    NSAssert(NO, @"Implement me");
    return nil;
}

- (void)_updateLabelContraints
{
    NSString *prevLayerName;
    NSMutableArray *constraints;

    // work on the left
    prevLayerName = nil;
    constraints = [NSMutableArray array];
    if (_leftOrientationTextLayer.superlayer) {
        [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
        [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX offset:7]];
        prevLayerName = @"leftOrientationTextLayer";
    }
    _leftOrientationTextLayer.constraints = constraints;
    constraints = [NSMutableArray array];
    if (_verticalScaleBar.superlayer) {
        [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
        if (prevLayerName) {
            [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:prevLayerName attribute:kCAConstraintMaxX offset:3]];
        } else {
            [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX offset:8]];
        }
    }
    _verticalScaleBar.constraints = constraints;

    // work on the bottom
    prevLayerName = nil;
    constraints = [NSMutableArray array];
    if (_bottomOrientationTextLayer.superlayer) {
        [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
        [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY offset:5]];
        prevLayerName = @"bottomOrientationTextLayer";
    }
    _bottomOrientationTextLayer.constraints = constraints;
    constraints = [NSMutableArray array];
    if (_horizontalScaleBar.superlayer) {
        [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
        if (prevLayerName) {
            [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:prevLayerName attribute:kCAConstraintMaxY offset:3]];
        } else {
            [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY offset:8]];
        }
    }
    _horizontalScaleBar.constraints = constraints;

    // work on right
    constraints = [NSMutableArray array];
    if (_rightOrientationTextLayer.superlayer) {
        [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX offset:-7]];
        [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
    }
    _rightOrientationTextLayer.constraints = constraints;

    // work on top
    constraints = [NSMutableArray array];
    if (_topOrientationTextLayer.superlayer) {
        [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
        [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:-5]];
    }
    _topOrientationTextLayer.constraints = constraints;
}

@end








