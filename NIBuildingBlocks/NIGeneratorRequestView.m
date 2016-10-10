//  Created by Joël Spaltenstein on 3/2/15.
//  Copyright (c) 2016 Spaltenstein Natural Image
//  Copyright (c) 2016 Michael Hilker and Andreas Holzamer
//  Copyright (c) 2016 volz io
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
#import "NITextLabelGroupLayer.h"

#import "NIVolumeData.h"
#import "NIGenerator.h"
#import "NIGeneratorRequest.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotification = @"NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotification";
NSString * const NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotificationNewRequestKey = @"new";
NSString * const NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotificationOldRequestKey = @"old";

@interface NIGeneratorRequestView ()
@property (nonatomic, readwrite, copy) NIGeneratorRequest *presentedGeneratorRequest;
@property (nonatomic, readwrite, assign) NIVector mousePosition;

// not sure if these should be public or not
- (NSMutableArray *)mutableTextLabelsForLocation:(NITextLabelLocation)labelLocation;
+ (NSString *)keyForTextLabelLocation:(NITextLabelLocation)labelLocation;
+ (NITextLabelLocation)textLabelLocationForKey:(NSString *)key;

- (NIAffineTransform)_sliceToModelTransform;
- (void)_updateLabelContraints;

@end

@interface NIGeneratorRequestViewOverlayDelegate : NSObject <CALayerDelegate>
{
    NIGeneratorRequestView *_view; // not retained
}
@property (nullable, nonatomic, readwrite, assign) NIGeneratorRequestView *view;
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

- (nullable id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)key
{
    if ([key isEqualToString:@"contents"]) {
        return (id<CAAction>)[NSNull null];
    } else {
        return nil;
    }
}

@end

@interface NIGeneratorRequestViewLayoutManager : NSObject <CALayoutManager>
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
    _view.mousePosition = [_view convertPointToModelVector:pointInView];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    _view.mousePosition = NIGeneratorRequestViewMouseOutside;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    NSPoint pointInView = [_view convertPoint:theEvent.locationInWindow fromView:nil];
    _view.mousePosition = [_view convertPointToModelVector:pointInView];
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
        [self _initNIGeneratorRequestView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _initNIGeneratorRequestView];
    }
    return self;
}

- (void)_initNIGeneratorRequestView
{
    [self setWantsLayer:YES];
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
    
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
    [self setupTextLabelLayers];
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

    [_textLabelLayers release];
    _textLabelLayers = nil;

    NSInteger i = 0;
    for (i = 0; i < NITextLabelLocationCount; i++) {
        [_textLabelLayers[i] setLabelLocation:(NITextLabelLocation)i];
    }

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
    NSAssert(_overlayLayer == nil, @"_overlayLayer already initialized");
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

- (void)setupTextLabelLayers
{
    _textLabelLayers = [@[[NITextLabelGroupLayer layer], [NITextLabelGroupLayer layer], [NITextLabelGroupLayer layer],
                          [NITextLabelGroupLayer layer], [NITextLabelGroupLayer layer], [NITextLabelGroupLayer layer]] retain];

    NSInteger i = 0;
    for (i = 0; i < NITextLabelLocationCount; i++) {
        NITextLabelGroupLayer *textLayer = _textLabelLayers[i];
        textLayer.labelLocation = (NITextLabelLocation)i;

        if (textLayer.labelLocation == NITextLabelLocationTopLeftEdgeSite || textLayer.labelLocation == NITextLabelLocationBottomLeftEdgeSite) {
            [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
        } else if (textLayer.labelLocation == NITextLabelLocationTopEdgeSite || textLayer.labelLocation == NITextLabelLocationBottomEdgeSite) {
            [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
        } else if (textLayer.labelLocation == NITextLabelLocationTopRightEdgeSite || textLayer.labelLocation == NITextLabelLocationBottomRightEdgeSite) {
            [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
        }

        if (textLayer.labelLocation == NITextLabelLocationTopLeftEdgeSite || textLayer.labelLocation == NITextLabelLocationTopEdgeSite || textLayer.labelLocation == NITextLabelLocationTopRightEdgeSite) {
            [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY]];
        } else if (textLayer.labelLocation == NITextLabelLocationBottomLeftEdgeSite || textLayer.labelLocation == NITextLabelLocationBottomEdgeSite || textLayer.labelLocation == NITextLabelLocationBottomRightEdgeSite) {
            [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
        }

        switch ((NITextLabelLocation)i) {
            case NITextLabelLocationTopLeftEdgeSite:
                textLayer.name = @"TopLeftLabelGroup";
                break;
            case NITextLabelLocationBottomLeftEdgeSite:
                textLayer.name = @"BottomLeftLabelGroup";
                break;
            case NITextLabelLocationTopEdgeSite:
                textLayer.name = @"TopLabelGroup";
                break;
            case NITextLabelLocationBottomEdgeSite:
                textLayer.name = @"BottomLabelGroup";
                break;
            case NITextLabelLocationTopRightEdgeSite:
                textLayer.name = @"TopRightLabelGroup";
                break;
            case NITextLabelLocationBottomRightEdgeSite:
                textLayer.name = @"BottomRightLabelGroup";
                break;
            default:;
        }

        textLayer.zPosition = NIGeneratorRequestViewRimLayerZPosition + 1;
        textLayer.contentsScale = self.layer.contentsScale;
        [_frameLayer addSublayer:textLayer];
    }
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

- (void)displayIfNeeded
{
    [super displayIfNeeded];

    for (NIGeneratorRequestLayer *generatorRequestLayer in [_volumeDataComposingLayer sublayers]) {
        [generatorRequestLayer displayIfNeeded];
    }

    [_overlayLayer displayIfNeeded];
}

+ (NSString *)keyForTextLabelLocation:(NITextLabelLocation)labelLocation
{
    switch (labelLocation) {
        case NITextLabelLocationTopLeftEdgeSite:
            return @"topLeftLabels";
            break;
        case NITextLabelLocationTopRightEdgeSite:
            return @"topRightLabels";
            break;
        case NITextLabelLocationBottomLeftEdgeSite:
            return @"bottomLeftLabels";
            break;
        case NITextLabelLocationBottomRightEdgeSite:
            return @"bottomRightLabels";
            break;
        case NITextLabelLocationTopEdgeSite:
            return @"topLabels";
            break;
        case NITextLabelLocationBottomEdgeSite:
            return @"bottomLabels";
            break;

        default:
            NSAssert(NO, @"Unknown Text Label Location");
            return nil;
    }
}

+ (NITextLabelLocation)textLabelLocationForKey:(NSString *)key
{
    if ([key isEqualToString:@"topLeftLabels"]) {
        return NITextLabelLocationTopLeftEdgeSite;
    } else if ([key isEqualToString:@"topRightLabels"]) {
        return NITextLabelLocationTopRightEdgeSite;
    } else if ([key isEqualToString:@"bottomLeftLabels"]) {
        return NITextLabelLocationBottomLeftEdgeSite;
    } else if ([key isEqualToString:@"bottomRightLabels"]) {
        return NITextLabelLocationBottomRightEdgeSite;
    } else if ([key isEqualToString:@"topLabels"]) {
        return NITextLabelLocationTopEdgeSite;
    } else if ([key isEqualToString:@"bottomLabels"]) {
        return NITextLabelLocationBottomEdgeSite;
    } else {
        return NITextLabelLocationUnknownSite;
    }
}

- (NSMutableArray *)mutableTextLabelsForLocation:(NITextLabelLocation)labelLocation
{
    return [_textLabelLayers[labelLocation] mutableArrayValueForKey:@"textLabels"];
}

- (NSMutableArray *)mutableArrayValueForKey:(NSString *)key
{
    NITextLabelLocation labelLocation = [[self class] textLabelLocationForKey:key];

    if (labelLocation != NITextLabelLocationUnknownSite) {
        return [self mutableTextLabelsForLocation:labelLocation];
    } else {
        return [super mutableArrayValueForKey:key];
    }
}

- (NSArray *)topLeftLabels
{
    return [(NITextLabelGroupLayer *)_textLabelLayers[NITextLabelLocationTopLeftEdgeSite] textLabels];
}

- (void)setTopLeftLabels:(NSArray *)labels
{
    [[self mutableTextLabelsForLocation:NITextLabelLocationTopLeftEdgeSite] setArray:labels];
}

- (NSArray *)topRightLabels
{
    return [(NITextLabelGroupLayer *)_textLabelLayers[NITextLabelLocationTopRightEdgeSite] textLabels];
}

- (void)setTopRightLabels:(NSArray *)labels
{
    [[self mutableTextLabelsForLocation:NITextLabelLocationTopRightEdgeSite] setArray:labels];
}

- (NSArray *)bottomLeftLabels
{
    return [(NITextLabelGroupLayer *)_textLabelLayers[NITextLabelLocationBottomLeftEdgeSite] textLabels];
}

- (void)setBottomLeftLabels:(NSArray *)labels
{
    [[self mutableTextLabelsForLocation:NITextLabelLocationBottomLeftEdgeSite] setArray:labels];
}

- (NSArray *)bottomRightLabels
{
    return [(NITextLabelGroupLayer *)_textLabelLayers[NITextLabelLocationBottomRightEdgeSite] textLabels];
}

- (void)setBottomRightLabels:(NSArray *)labels
{
    [[self mutableTextLabelsForLocation:NITextLabelLocationBottomRightEdgeSite] setArray:labels];
}

- (NSArray *)topLabels
{
    return [(NITextLabelGroupLayer *)_textLabelLayers[NITextLabelLocationTopEdgeSite] textLabels];
}

- (void)setTopLabels:(NSArray *)labels
{
    [[self mutableTextLabelsForLocation:NITextLabelLocationTopEdgeSite] setArray:labels];
}

- (NSArray *)bottomLabels
{
    return [(NITextLabelGroupLayer *)_textLabelLayers[NITextLabelLocationBottomEdgeSite] textLabels];
}

- (void)setBottomLabels:(NSArray *)labels
{
    [[self mutableTextLabelsForLocation:NITextLabelLocationBottomEdgeSite] setArray:labels];
}

// These might be useful to have one day
//- (NSUInteger)countOfTopLeftLabels {
//    return [[(NITextLabelGroupLayer *)_textLabelLayers[NITextLabelLocationTopLeftEdgeSite] textLabels] count];
//}
//
//- (id)objectInTopLeftLabelsAtIndex:(NSUInteger)index {
//    return [[(NITextLabelGroupLayer *)_textLabelLayers[NITextLabelLocationTopLeftEdgeSite] textLabels] objectAtIndex:index];
//}
//
//- (NSArray *)topLeftLabelsAtIndexes:(NSIndexSet *)indexes {
//    return [[(NITextLabelGroupLayer *)_textLabelLayers[NITextLabelLocationTopLeftEdgeSite] textLabels] objectsAtIndexes:indexes];
//}
//
//- (void)insertObject:(NSString *)label inTopLeftLabelsAtIndex:(NSUInteger)index {
//    [[self mutableTextLabelsForLocation:NITextLabelLocationTopLeftEdgeSite] insertObject:label atIndex:index];
//}
//
//- (void)insertTopLeftLabels:(NSArray *)labelsArray atIndexes:(NSIndexSet *)indexes {
//    [[self mutableTextLabelsForLocation:NITextLabelLocationTopLeftEdgeSite] insertObjects:labelsArray atIndexes:indexes];
//}
//
//- (void)removeObjectFromTopLeftLabelsAtIndex:(NSUInteger)index {
//    [[self mutableTextLabelsForLocation:NITextLabelLocationTopLeftEdgeSite] removeObjectAtIndex:index];
//}
//
//- (void)removeTopLeftLabelsAtIndexes:(NSIndexSet *)indexes {
//    [[self mutableTextLabelsForLocation:NITextLabelLocationTopLeftEdgeSite] removeObjectsAtIndexes:indexes];
//}
//
//- (void)replaceObjectInTopLeftLabelsAtIndex:(NSUInteger)index withObject:(id)anObject {
//    [[self mutableTextLabelsForLocation:NITextLabelLocationTopLeftEdgeSite] replaceObjectAtIndex:index withObject:anObject];
//}
//
//- (void)replaceTopLeftLabelsAtIndexes:(NSIndexSet *)indexes withTopLeftLabels:(NSArray *)labelsArray {
//    [[self mutableTextLabelsForLocation:NITextLabelLocationTopLeftEdgeSite] replaceObjectsAtIndexes:indexes withObjects:labelsArray];
//}

- (void)setDisplayRim:(BOOL)displayRim
{
    if (displayRim && [_rimLayer superlayer] == nil) {
        [_frameLayer addSublayer:_rimLayer];
    } else if (displayRim == NO) {
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
    } else if (displayOrientationLabels == NO) {
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
    } else if (displayScaleBar == NO) {
        [_horizontalScaleBar removeFromSuperlayer];
        [_verticalScaleBar removeFromSuperlayer];
    }
    [self _updateLabelContraints];
}

- (BOOL)displayScaleBar
{
    return [_horizontalScaleBar superlayer] != 0;
}

- (void)setGeneratorRequest:(nullable NIGeneratorRequest *)generatorRequest
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
        [generatorRequestLayer addObserver:self forKeyPath:@"presentedGeneratorRequest" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:_volumeDataComposingLayer];
    }
    [self didChangeValueForKey:@"volumeDataProperties"];

    return volumeDataProperties;
}

- (void)removeVolumeDataAtIndex:(NSUInteger)index
{
    [self willChangeValueForKey:@"volumeDataProperties"];
    if ([[_volumeDataComposingLayer sublayers] count] && index == 0) {
        [[_volumeDataComposingLayer sublayers][0] removeObserver:self forKeyPath:@"presentedGeneratorRequest"];
    }

    [[_volumeDataComposingLayer sublayers][index] removeFromSuperlayer];
    [_volumeDataProperties[index] setGeneratorRequestLayer:nil];
    [_volumeDataProperties removeObjectAtIndex:index];

    if ([[_volumeDataComposingLayer sublayers] count] && index == 0) {
        [[_volumeDataComposingLayer sublayers][0] addObserver:self forKeyPath:@"presentedGeneratorRequest" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:_volumeDataComposingLayer];
    }

    [self didChangeValueForKey:@"volumeDataProperties"];
}

- (NIVolumeData *)volumeDataAtIndex:(NSUInteger)index
{
    return [(NIGeneratorRequestLayer *)[_volumeDataComposingLayer sublayers][index] volumeData];
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

- (NIAffineTransform)_sliceToModelTransform // this is not smart enough yet to handle curved slices
{
    NIGeneratorRequest *generatorRequest = self.presentedGeneratorRequest;

    if ([generatorRequest isKindOfClass:[NIObliqueSliceGeneratorRequest class]]) {
        NIObliqueSliceGeneratorRequest *obliqueGeneratorRequest = (NIObliqueSliceGeneratorRequest *)generatorRequest;
        NIAffineTransform sliceTransform = obliqueGeneratorRequest.sliceToModelTransform;
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
    newLayer.sliceToModelTransform = [self _sliceToModelTransform];
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

- (nullable NIIntersection *)intersectionForKey:(NSString *)key
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

- (void)enumerateIntersectionsWithBlock:(void (^)(NSString *key, __kindof NIIntersection *intersection, BOOL *stop))block {
    [_intersections enumerateKeysAndObjectsUsingBlock:block];
}

- (nullable NSString *)intersectionClosestToPoint:(NSPoint)point closestPoint:(nullable NSPoint *)rclosestPoint distance:(CGFloat *)rdistance
{
    NSString * closestKey = nil;
    CGFloat closestDistance = CGFLOAT_MAX;
    NSPoint closestPoint = NSZeroPoint;
    
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
        [intersection mouseMoved:theEvent];
    }
    [(NSResponder *)self.layer.layoutManager mouseMoved:theEvent]; // cast to base class for -mouseMoved: to silence compiler warning
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

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary *)change context:(nullable void *)context
{
    if ([keyPath isEqualToString:@"presentedGeneratorRequest"] && context == _volumeDataComposingLayer) {
        self.presentedGeneratorRequest = [(NIGeneratorRequestLayer *)object presentedGeneratorRequest];
        [[NSNotificationCenter defaultCenter] postNotificationName:NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotification object:self userInfo:@{ NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotificationNewRequestKey: change[NSKeyValueChangeNewKey], NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotificationOldRequestKey: change[NSKeyValueChangeOldKey] }];
        if ([self inLiveResize] == NO) {
            NSPoint pointInView = [self convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];
            if (NSPointInRect(pointInView, self.bounds)) {
                self.mousePosition = [self convertPointToModelVector:pointInView];
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

            _horizontalScaleBar.pointSpacing = NIVectorDistance([self convertPointToModelVector:NSZeroPoint], [self convertPointToModelVector:NSMakePoint(0, 1)]);
            _verticalScaleBar.pointSpacing = NIVectorDistance([self convertPointToModelVector:NSZeroPoint], [self convertPointToModelVector:NSMakePoint(0, 1)]);

            NIAffineTransform sliceToModelTransfrom = [self _sliceToModelTransform];
            for (NIIntersection *intersection in [_intersections allValues]) {
                [(NIObliqueSliceIntersectionLayer *)intersection.intersectionLayer setSliceToModelTransform:sliceToModelTransfrom];
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

- (NSPoint)convertPointFromModelVector:(NIVector)vector
{
    NIGeneratorRequest *presentedGeneratorRequest = [self presentedGeneratorRequest];
    if (presentedGeneratorRequest == nil) {
        return NSZeroPoint;
    }

    NIVector requestVector = [presentedGeneratorRequest convertVolumeVectorFromModelVector:vector];

    requestVector.x += 0.5;
    requestVector.y += 0.5;

    requestVector.x *= self.bounds.size.width / presentedGeneratorRequest.pixelsWide;
    requestVector.y *= self.bounds.size.height / presentedGeneratorRequest.pixelsHigh;

    return NSPointFromNIVector(requestVector);
}

- (NIVector)convertPointToModelVector:(NSPoint)point
{
    NIGeneratorRequest *presentedGeneratorRequest = [self presentedGeneratorRequest];
    if (presentedGeneratorRequest == nil) {
        return NIVectorZero;
    }

    point.x *= presentedGeneratorRequest.pixelsWide / self.bounds.size.width;
    point.y *= presentedGeneratorRequest.pixelsHigh / self.bounds.size.height;

    point.x -= .5;
    point.y -= .5;

    return [presentedGeneratorRequest convertVolumeVectorToModelVector:NIVectorMakeFromNSPoint(point)];
}

- (nullable NSBezierPath *)convertBezierPathFromModel:(NIBezierPath *)bezierPath
{
    // we don't know how to convert beziers when the transformation is not affine.
    if ([self.presentedGeneratorRequest isKindOfClass:[NIObliqueSliceGeneratorRequest class]] == NO) {
        return nil;
    }

    NIAffineTransform fromModelTransform = NIAffineTransformIdentity;

    *(NSPoint *)&fromModelTransform.m41 = [self convertPointFromModelVector:NIVectorZero];
    *(NSPoint *)&fromModelTransform.m11 = [self convertPointFromModelVector:NIVectorXBasis];
    *(NSPoint *)&fromModelTransform.m21 = [self convertPointFromModelVector:NIVectorYBasis];
    *(NSPoint *)&fromModelTransform.m31 = [self convertPointFromModelVector:NIVectorZBasis];

    *(NIVector *)&fromModelTransform.m11 = NIVectorSubtract(*(NIVector *)&fromModelTransform.m11, *(NIVector *)&fromModelTransform.m41);
    *(NIVector *)&fromModelTransform.m21 = NIVectorSubtract(*(NIVector *)&fromModelTransform.m21, *(NIVector *)&fromModelTransform.m41);
    *(NIVector *)&fromModelTransform.m31 = NIVectorSubtract(*(NIVector *)&fromModelTransform.m31, *(NIVector *)&fromModelTransform.m41);

    // at this point fromModelTransform applies the correct transform, but it is not guaranteed to not be a degenerate matrix
    // so we will fill out m13...m33 with values that make sure that is not the case
    NIVector yColumn = NIVectorCrossProduct(NIVectorMake(fromModelTransform.m11, fromModelTransform.m21, fromModelTransform.m31),
                                            NIVectorMake(fromModelTransform.m12, fromModelTransform.m22, fromModelTransform.m32));
    fromModelTransform.m13 = yColumn.x;
    fromModelTransform.m23 = yColumn.y;
    fromModelTransform.m33 = yColumn.z;

    return [[bezierPath bezierPathByApplyingTransform:fromModelTransform] NSBezierPath];
}

- (nullable NIBezierPath *)convertBezierPathToModel:(NSBezierPath *)bezierPath
{
    // we don't know how to convert beziers when the transformation is not affine.
    if ([self.presentedGeneratorRequest isKindOfClass:[NIObliqueSliceGeneratorRequest class]] == NO) {
        return nil;
    }

    NIAffineTransform toModelTransform = NIAffineTransformIdentity;
    *(NIVector *)&toModelTransform.m41 = [self convertPointToModelVector:NSMakePoint(0, 0)];
    *(NIVector *)&toModelTransform.m11 = [self convertPointToModelVector:NSMakePoint(1, 0)];
    *(NIVector *)&toModelTransform.m21 = [self convertPointToModelVector:NSMakePoint(0, 1)];

    *(NIVector *)&toModelTransform.m11 = NIVectorSubtract(*(NIVector *)&toModelTransform.m11, *(NIVector *)&toModelTransform.m41);
    *(NIVector *)&toModelTransform.m21 = NIVectorSubtract(*(NIVector *)&toModelTransform.m21, *(NIVector *)&toModelTransform.m41);

    // make sure that the transform is not degenerate
    *(NIVector *)&toModelTransform.m31 = NIVectorCrossProduct(*(NIVector *)&toModelTransform.m11, *(NIVector *)&toModelTransform.m21);

    NIMutableBezierPath *convertedBezierPath = [NIMutableBezierPath bezierPathWithNSBezierPath:bezierPath];
    [convertedBezierPath applyAffineTransform:toModelTransform];
    return convertedBezierPath;
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
        [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"BottomLabelGroup" attribute:kCAConstraintMaxY offset:5]];
        prevLayerName = @"bottomOrientationTextLayer";
    }
    _bottomOrientationTextLayer.constraints = constraints;
    constraints = [NSMutableArray array];
    if (_horizontalScaleBar.superlayer) {
        [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
        if (prevLayerName) {
            [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:prevLayerName attribute:kCAConstraintMaxY offset:3]];
        } else {
            [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"BottomLabelGroup" attribute:kCAConstraintMaxY offset:8]];
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
        [constraints addObject:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"TopLabelGroup" attribute:kCAConstraintMinY offset:-5]];
    }
    _topOrientationTextLayer.constraints = constraints;
}

@end

NS_ASSUME_NONNULL_END
