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


#import <Cocoa/Cocoa.h>

#import "NIGenerator.h"
#import "NIGeometry.h"

static const NIVector NIGeneratorRequestViewMouseOutside = {-CGFLOAT_MAX, -CGFLOAT_MAX, -CGFLOAT_MAX};

static const CGFloat NIGeneratorRequestViewRequestLayerZPosition = 1;
static const CGFloat NIGeneratorRequestViewIntersectionZPosition = 3;
static const CGFloat NIGeneratorRequestViewSpriteZPosition = 5;
static const CGFloat NIGeneratorRequestViewRimLayerZPosition = 10;

extern NSString* const NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotification;

@class NIGeneratorRequest;
@class NIVolumeData;
@class NIFloatImageRep;
@class NIGeneratorRequestLayer;
@class NIOrientationTextLayer;
@class NIScaleBarLayer;
@class NIIntersection;
@class NISprite;
@class NIBezierPath;
@class NIVolumeDataProperties;
@class NIGeneratorRequestViewOverlayDelegate;

@interface NIGeneratorRequestView : NSView
{
@private
    CALayer *_volumeDataComposingLayer; // all the volumeDataLayers will be added to this layer
    NSMutableArray *_volumeDataProperties;

    NIGeneratorRequest *_generatorRequest;

    NSMutableDictionary *_intersections;
    NSMutableDictionary *_intersectionTrackingAreas;

    NSMutableDictionary *_sprites;

    NSTrackingArea *_mousePositionTrackingArea;
    NIVector _mousePosition;

    CALayer *_frameLayer;

    NIGeneratorRequestViewOverlayDelegate *_overlayLayerDelegate;
    CALayer *_overlayLayer;

    CALayer *_rimLayer;
    NSColor *_rimColor;
    CGFloat _rimThickness;

    NIOrientationTextLayer *_topOrientationTextLayer;
    NIOrientationTextLayer *_bottomOrientationTextLayer;
    NIOrientationTextLayer *_leftOrientationTextLayer;
    NIOrientationTextLayer *_rightOrientationTextLayer;

    NIScaleBarLayer *_horizontalScaleBar;
    NIScaleBarLayer *_verticalScaleBar;

    NIGeneratorRequest *_presentedGeneratorRequest;
}

@property (nonatomic, readwrite, retain) NIGeneratorRequest *generatorRequest; // this is the generator request that will be drawn.  Animatable
@property (nonatomic, readonly, copy) NIGeneratorRequest *presentedGeneratorRequest; // this is the generator request that is currently draw. Continuously updates during animations
@property (nonatomic, readonly, assign) NIVector mousePosition; // the current mouse location, the mouseLocation is equal to NIGeneratorRequestViewMouseOutside if it is outside the view

- (NSInteger)volumeDataCount;
- (NIVolumeDataProperties *)addVolumeData:(NIVolumeData *)volumeData;
- (NIVolumeDataProperties *)insertVolumeData:(NIVolumeData *)volumeData atIndex:(NSUInteger)index;
- (void)removeVolumeDataAtIndex:(NSUInteger)index;
- (NIVolumeData *)volumeDataAtIndex:(NSUInteger)index;

- (NIVolumeDataProperties *)volumeDataPropertiesAtIndex:(NSUInteger)index;

- (NSPoint)convertPointFromDICOMVector:(NIVector)vector;
- (NIVector)convertPointToDICOMVector:(NSPoint)point;

- (NSBezierPath *)convertBezierPathFromDICOM:(NIBezierPath *)bezierPath;
- (NIBezierPath *)convertBezierPathToDICOM:(NSBezierPath *)bezierPath;

@property (nonatomic, readonly, retain) CALayer *frameLayer; // the layer into which subclasses can add layers, this layer lays out sublayers using the CAConstraintLayoutManager
                                                            // Use NIGeneratorRequestViewRequestLayerZPosition, etc to specify the depth of the layer you want to add.

@property (nonatomic, readwrite, assign) BOOL displayRim;
@property (nonatomic, readwrite, retain) NSColor *rimColor;
@property (nonatomic, readwrite, assign) CGFloat rimThickness;
@property (nonatomic, readwrite, assign) BOOL displayOrientationLabels;
@property (nonatomic, readwrite, assign) BOOL displayScaleBar;

// intersections
- (void)addIntersection:(NIIntersection *)intersection forKey:(NSString *)key; // for now undefined behavior if an intersection already exists for the key
- (NIIntersection *)intersectionForKey:(NSString *)key;
- (void)removeAllIntersections;
- (void)removeIntersectionForKey:(NSString *)key;
- (NSArray *)intersectionKeys;
- (void)enumerateIntersectionsWithBlock:(void (^)(NSString *key, NIIntersection *intersection, BOOL *stop))block;
- (NSString *)intersectionClosestToPoint:(NSPoint)point closestPoint:(NSPointPointer)rclosestPoint distance:(CGFloat *)rdistance;

//sprites
- (void)addSprite:(NISprite *)sprite forKey:(NSString *)key;
- (NISprite *)spriteForKey:(NSString *)key;
- (void)removeAllSprites;
- (void)removeSpriteForKey:(NSString *)key;
- (NSArray *)spriteKeys;

- (void)setOverlayNeedsDisplay;
- (void)drawOverlay; // to be implemented by subclasses that want to do some rendering over the displayed images

//@property (nonatomic, readwrite, assign) BOOL displayWindowLevelWindowWidth;
//@property (nonatomic, readwrite, assign) BOOL displayVolumePosition;
//@property (nonatomic, readwrite, assign) BOOL displayPixelIntensity;

- (void)mouseDragged:(NSEvent *)theEvent NS_REQUIRES_SUPER;

@end







