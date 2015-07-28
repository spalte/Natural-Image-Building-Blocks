//
//  NIAnnotationHandle.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <NIBuildingBlocks/NIGeometry.h>
#import "NIAnnotation.h"

@class NIAnnotatedGeneratorRequestView;
@class NIAnnotation;

extern const CGFloat NIAnnotationHandleSize;
extern const CGFloat NIAnnotationDistant;


@interface NIAnnotationHandle : NSObject {
    NSPoint _slicePoint;
}

@property NSPoint slicePoint;

- (id)initWithSlicePoint:(NSPoint)slicePoint;

- (void)translateFromSlicePoint:(NSPoint)from toSlicePoint:(NSPoint)to view:(NIAnnotatedGeneratorRequestView*)view event:(NSEvent*)event;

@end

@interface NIAnnotationBlockHandle : NIAnnotationHandle {
    void (^_block)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector deltaDicomVector);
}

+ (instancetype)handleAtSliceVector:(NIVector)sliceVector block:(void(^)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector deltaDicomVector))handler;
+ (instancetype)handleAtSlicePoint:(NSPoint)slicePoint block:(void(^)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector deltaDicomVector))handler;

@end

@interface NIPlanarAnnotationHandle : NIAnnotationHandle {
    NIAnnotation<NITransformAnnotation>* _annotation;
}

- (id)initWithSlicePoint:(NSPoint)slicePoint annotation:(NIAnnotation<NITransformAnnotation>*)a;

- (void)translateFromPlaneVector:(NIVector)vfrom toPlaneVector:(NIVector)vto view:(NIAnnotatedGeneratorRequestView *)view event:(NSEvent*)event;

@end

@interface NIPlanarAnnotationBlockHandle : NIPlanarAnnotationHandle {
    void (^_block)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector deltaPlaneVector);
}

+ (instancetype)handleAtSliceVector:(NIVector)sliceVector annotation:(NIAnnotation<NITransformAnnotation>*)a block:(void(^)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector deltaPlaneVector))handler;
+ (instancetype)handleAtSlicePoint:(NSPoint)slicePoint annotation:(NIAnnotation<NITransformAnnotation>*)a block:(void(^)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector deltaPlaneVector))handler;

@end