//
//  NIMPRAnnotatedGeneratorRequestView.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/8/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <NIBuildingBlocks/NIBuildingBlocks.h>

@class NIAnnotation;
@class NIAnnotationHandle;

@interface NIAnnotatedGeneratorRequestView : NIGeneratorRequestView {
    CALayer* _annotationsLayer;
    NSMutableSet* _annotations;
    NSMutableSet* _highlightedAnnotations;
    NSMutableSet* _selectedAnnotations;
    CGFloat _annotationsBaseAlpha;
    NSMutableDictionary* _annotationsCaches;
}

@property(readonly, retain) CALayer* annotationsLayer;
@property CGFloat annotationsBaseAlpha;

@property(readonly, copy) NSSet* annotations;
- (NSMutableSet*)mutableAnnotations;
@property(readonly, copy) NSSet* highlightedAnnotations;
- (NSMutableSet*)mutableHighlightedAnnotations;
@property(readonly, copy) NSSet* selectedAnnotations;
- (NSMutableSet*)mutableSelectedAnnotations;

- (CGFloat)maximumDistanceToPlane;

- (NIAnnotation*)annotationClosestToSlicePoint:(NSPoint)location closestPoint:(NSPoint*)closestPoint distance:(CGFloat*)distance;
- (NIAnnotation*)annotationClosestToSlicePoint:(NSPoint)location closestPoint:(NSPoint*)closestPoint distance:(CGFloat*)distance filter:(BOOL (^)(NIAnnotation* annotation))filter;

- (NSSet*)annotationsIntersectingWithSliceRect:(NSRect)sliceRect;

- (NIAnnotationHandle*)handleForSlicePoint:(NSPoint)location;
+ (NSBezierPath*)NSBezierPathForHandle:(NIAnnotationHandle*)handle;

@end

@interface NIAnnotatedGeneratorRequestView (Super)

// NIAnnotations currently only support NIAffineTransform-based requests
@property (nonatomic, readwrite, retain) NIObliqueSliceGeneratorRequest* generatorRequest;
@property (nonatomic, readonly, copy) NIObliqueSliceGeneratorRequest* presentedGeneratorRequest;

@end