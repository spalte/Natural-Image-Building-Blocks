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

@interface NIHandlerAnnotationHandle : NIAnnotationHandle {
    void (^_handler)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector deltaDicomVector);
}

+ (instancetype)handleAtSliceVector:(NIVector)sliceVector handler:(void(^)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector deltaDicomVector))handler;
+ (instancetype)handleAtSlicePoint:(NSPoint)slicePoint handler:(void(^)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector deltaDicomVector))handler;

@end

@interface NIPlaneAnnotationHandle : NIAnnotationHandle {
    NIAnnotation<NIPlaneAnnotation>* _annotation;
}

- (id)initWithSlicePoint:(NSPoint)slicePoint annotation:(NIAnnotation<NIPlaneAnnotation>*)a;

- (void)translateFromPlaneVector:(NIVector)vfrom toPlaneVector:(NIVector)vto view:(NIAnnotatedGeneratorRequestView *)view event:(NSEvent*)event;

@end

@interface NIHandlerPlaneAnnotationHandle : NIPlaneAnnotationHandle {
    void (^_handler)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector deltaPlaneVector);
}

+ (instancetype)handleAtSliceVector:(NIVector)sliceVector annotation:(NIAnnotation<NIPlaneAnnotation>*)a handler:(void(^)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector deltaPlaneVector))handler;
+ (instancetype)handleAtSlicePoint:(NSPoint)slicePoint annotation:(NIAnnotation<NIPlaneAnnotation>*)a handler:(void(^)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector deltaPlaneVector))handler;

@end