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

#import "NIBBGenerator.h"
#import "NIBBGeometry.h"

static const NIBBVector NIBBGeneratorRequestViewMouseOutside = {-CGFLOAT_MAX, -CGFLOAT_MAX, -CGFLOAT_MAX};

static const CGFloat NIBBGeneratorRequestViewRequestLayerZPosition = 1;
static const CGFloat NIBBGeneratorRequestViewIntersectionZPosition = 3;
static const CGFloat NIBBGeneratorRequestViewSpriteZPosition = 5;
static const CGFloat NIBBGeneratorRequestViewRimLayerZPosition = 10;

extern NSString* const NIBBGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotification;

@class NIBBGeneratorRequest;
@class NIBBVolumeData;
@class NIBBFloatImageRep;
@class NIBBGeneratorRequestLayer;
@class NIBBOrientationTextLayer;
@class NIBBScaleBarLayer;
@class NIBBIntersection;
@class NIBBSprite;
@class NIBBBezierPath;
@class NIBBVolumeDataProperties;

@interface NIBBGeneratorRequestView : NSView
{
@private
    CALayer *_volumeDataComposingLayer; // all the volumeDataLayers will be added to this layer
    NSMutableArray *_volumeDataProperties;

    NIBBGeneratorRequest *_generatorRequest;

    NSMutableDictionary *_intersections;
    NSMutableDictionary *_intersectionTrackingAreas;

    NSMutableDictionary *_sprites;

    NSTrackingArea *_mousePositionTrackingArea;
    NIBBVector _mousePosition;

    CALayer *_frameLayer;

    CALayer *_rimLayer;
    NSColor *_rimColor;
    CGFloat _rimThickness;

    NIBBOrientationTextLayer *_topOrientationTextLayer;
    NIBBOrientationTextLayer *_bottomOrientationTextLayer;
    NIBBOrientationTextLayer *_leftOrientationTextLayer;
    NIBBOrientationTextLayer *_rightOrientationTextLayer;

    NIBBScaleBarLayer *_horizontalScaleBar;
    NIBBScaleBarLayer *_verticalScaleBar;

    NIBBGeneratorRequest *_presentedGeneratorRequest;
}

@property (nonatomic, readwrite, retain) NIBBGeneratorRequest *generatorRequest; // this is the generator request that will be drawn.  Animatable
@property (nonatomic, readonly, copy) NIBBGeneratorRequest *presentedGeneratorRequest; // this is the generator request that is currently draw. Continuously updates during animations
@property (nonatomic, readonly, assign) NIBBVector mousePosition; // the current mouse location, the mouseLocation is equal to NIBBGeneratorRequestViewMouseOutside if it is outside the view

- (NSInteger)volumeDataCount;
- (NIBBVolumeDataProperties *)addVolumeData:(NIBBVolumeData *)volumeData;
- (NIBBVolumeDataProperties *)insertVolumeData:(NIBBVolumeData *)volumeData atIndex:(NSUInteger)index;
- (void)removeVolumeDataAtIndex:(NSUInteger)index;
- (NIBBVolumeData *)volumeDataAtIndex:(NSUInteger)index;

- (NIBBVolumeDataProperties *)volumeDataPropertiesAtIndex:(NSUInteger)index;

- (NSPoint)convertPointFromDICOMVector:(NIBBVector)vector;
- (NIBBVector)convertPointToDICOMVector:(NSPoint)point;

- (NSBezierPath *)convertBezierPathFromDICOM:(NIBBBezierPath *)bezierPath;
- (NIBBBezierPath *)convertBezierPathToDICOM:(NSBezierPath *)bezierPath;

@property (nonatomic, readonly, retain) CALayer *frameLayer; // the layer into which subclasses can add layers, this layer lays out sublayers using the CAConstraintLayoutManager
                                                            // Use NIBBGeneratorRequestViewRequestLayerZPosition, etc to specify the depth of the layer you want to add.

@property (nonatomic, readwrite, assign) BOOL displayRim;
@property (nonatomic, readwrite, retain) NSColor *rimColor;
@property (nonatomic, readwrite, assign) CGFloat rimThickness;
@property (nonatomic, readwrite, assign) BOOL displayOrientationLabels;
@property (nonatomic, readwrite, assign) BOOL displayScaleBar;

// intersections
- (void)addIntersection:(NIBBIntersection *)intersection forKey:(NSString *)key; // for now undefined behavior if an intersection already exists for the key
- (NIBBIntersection *)intersectionForKey:(NSString *)key;
- (void)removeAllIntersections;
- (void)removeIntersectionForKey:(NSString *)key;
- (NSArray *)intersectionKeys;
- (void)enumerateIntersectionsWithBlock:(void (^)(NSString *key, NIBBIntersection *intersection, BOOL *stop))block;
- (NSString *)intersectionClosestToPoint:(NSPoint)point closestPoint:(NSPointPointer)rclosestPoint distance:(CGFloat *)rdistance;

//sprites
- (void)addSprite:(NIBBSprite *)sprite forKey:(NSString *)key;
- (NIBBSprite *)spriteForKey:(NSString *)key;
- (void)removeAllSprites;
- (void)removeSpriteForKey:(NSString *)key;
- (NSArray *)spriteKeys;

//@property (nonatomic, readwrite, assign) BOOL displayWindowLevelWindowWidth;
//@property (nonatomic, readwrite, assign) BOOL displayVolumePosition;
//@property (nonatomic, readwrite, assign) BOOL displayPixelIntensity;

- (void)mouseDragged:(NSEvent *)theEvent NS_REQUIRES_SUPER;

@end








