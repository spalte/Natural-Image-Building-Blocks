//
//  NIMPRAnnotation.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/8/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotatedGeneratorRequestView.h"

extern NSString* const NIAnnotationChangeNotification; // to observe an annotation's changes you can either observe these notifications or observe the annotation's changed property

extern NSString* const NIAnnotationDrawCache;

extern CGFloat const NIAnnotationDistant;

@interface NIAnnotation : NSObject {
    NSColor* _color;
//    NSDictionary* _userInfo;
    NSMutableDictionary* _changes;
}

@property(retain, nonatomic) NSColor* color;

+ (id)pointWithVector:(NIVector)vector;
+ (id)segmentWithPoints:(NSPoint)p :(NSPoint)q transform:(NIAffineTransform)sliceToDicomTransform;
+ (id)rectangleWithBounds:(NSRect)bounds transform:(NIAffineTransform)sliceToDicomTransform;
+ (id)ellipseWithBounds:(NSRect)bounds transform:(NIAffineTransform)sliceToDicomTransform;

+ (NSColor*)defaultColor;
+ (void)setDefaultColor:(NSColor*)color;

@property(readonly) BOOL annotation; // the value of this property is always YES, but you can observe it in order to observe changes in the annotation's properties
+ (NSSet*)keyPathsForValuesAffectingAnnotation;

- (NSBezierPath*)drawInView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache layer:(CALayer*)layer context:(CGContextRef)ctx; // return the border path
- (void)glowInView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache layer:(CALayer*)layer context:(CGContextRef)ctx path:(NSBezierPath*)path;

- (CGFloat)distanceToSlicePoint:(NSPoint)point cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view closestPoint:(NSPoint*)rpoint; // point is on slice
- (BOOL)intersectsSliceRect:(NSRect)rect cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view;

- (NSSet*)handles;

@end

@interface NIAnnotationHandle : NSObject {
    NIVector _vector;
}

@property NIVector vector;

+ (instancetype)handleWithVector:(NIVector)vector;

@end
