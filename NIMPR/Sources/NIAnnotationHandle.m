//
//  NIAnnotationHandle.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotationHandle.h"

const CGFloat NIAnnotationHandleSize = 4;

@implementation NIAnnotationHandle

@synthesize slicePoint = _slicePoint;

- (id)initWithSlicePoint:(NSPoint)slicePoint {
    if ((self = [super init])) {
        self.slicePoint = slicePoint;
    }
    
    return self;
}

- (void)translateFromSlicePoint:(NSPoint)from toSlicePoint:(NSPoint)to view:(NIAnnotatedGeneratorRequestView*)view; {
    NSLog(@"Warning: -[%@ translateFrom:to:view:]", self.className);
}

@end

@interface NIHandlerAnnotationHandle ()

@property(copy) void (^handler)(NIAnnotatedGeneratorRequestView* view, NIVector dd);

@end

@implementation NIHandlerAnnotationHandle

@synthesize handler = _handler;

+ (instancetype)handleAtSliceVector:(NIVector)sliceVector handler:(void(^)(NIAnnotatedGeneratorRequestView* view, NIVector dd))handler {
    return [self.class handleAtSlicePoint:NSPointFromNIVector(sliceVector) handler:handler];
}

+ (instancetype)handleAtSlicePoint:(NSPoint)slicePoint handler:(void(^)(NIAnnotatedGeneratorRequestView* view, NIVector dd))handler {
    return [[[self.class alloc] initWithSlicePoint:slicePoint handler:handler] autorelease];
}

- (id)initWithSlicePoint:(NSPoint)slicePoint handler:(void(^)(NIAnnotatedGeneratorRequestView* view, NIVector dd))handler {
    if ((self = [super initWithSlicePoint:slicePoint])) {
        self.handler = handler;
    }
    
    return self;
}

- (void)dealloc {
    self.handler = nil;
    [super dealloc];
}

- (void)translateFromSlicePoint:(NSPoint)from toSlicePoint:(NSPoint)to view:(NIAnnotatedGeneratorRequestView*)view {
    self.handler(view, NIVectorSubtract(NIVectorApplyTransform(NIVectorMakeFromNSPoint(to), view.presentedGeneratorRequest.sliceToDicomTransform), NIVectorApplyTransform(NIVectorMakeFromNSPoint(from), view.presentedGeneratorRequest.sliceToDicomTransform)));
}

@end

@interface NIPlaneAnnotationHandle ()

@property(retain) NIAnnotation<NIPlaneAnnotation>* annotation;

@end

@implementation NIPlaneAnnotationHandle

@synthesize annotation = _annotation;

- (id)initWithSlicePoint:(NSPoint)slicePoint annotation:(NIAnnotation<NIPlaneAnnotation>*)a {
    if ((self = [super initWithSlicePoint:slicePoint])) {
        self.annotation = a;
    }
    
    return self;
}

- (void)dealloc {
    self.annotation = nil;
    [super dealloc];
}

- (void)translateFromSlicePoint:(NSPoint)sfrom toSlicePoint:(NSPoint)sto view:(NIAnnotatedGeneratorRequestView *)view {
    NIAffineTransform sliceToPlaneTransform = NIAffineTransformConcat(view.presentedGeneratorRequest.sliceToDicomTransform, NIAffineTransformInvert(self.annotation.planeToDicomTransform));
    NIVector pfrom = NILineIntersectionWithPlane(NILineApplyTransform(NILineMake(NIVectorMakeFromNSPoint(sfrom), NIVectorZBasis), sliceToPlaneTransform), NIPlaneZZero);
    NIVector pto = NILineIntersectionWithPlane(NILineApplyTransform(NILineMake(NIVectorMakeFromNSPoint(sto), NIVectorZBasis), sliceToPlaneTransform), NIPlaneZZero);
    [self translateFromPlaneVector:pfrom toPlaneVector:pto view:view];
}

- (void)translateFromPlaneVector:(NIVector)vfrom toPlaneVector:(NIVector)vto view:(NIAnnotatedGeneratorRequestView *)view {
    NSLog(@"Warning: -[%@ translateFromVector:toVector:view:] is missing", self.className);
}

@end

@interface NIHandlerPlaneAnnotationHandle ()

@property(copy) void (^handler)(NIAnnotatedGeneratorRequestView* view, NIVector pd);

@end

@implementation NIHandlerPlaneAnnotationHandle

@synthesize handler = _handler;

+ (instancetype)handleAtSliceVector:(NIVector)sliceVector annotation:(NIAnnotation<NIPlaneAnnotation>*)a handler:(void(^)(NIAnnotatedGeneratorRequestView* view, NIVector pd))handler {
    return [self.class handleAtSlicePoint:NSPointFromNIVector(sliceVector) annotation:a handler:handler];
}

+ (instancetype)handleAtSlicePoint:(NSPoint)slicePoint annotation:(NIAnnotation<NIPlaneAnnotation>*)a handler:(void(^)(NIAnnotatedGeneratorRequestView* view, NIVector pd))handler {
    return [[[self.class alloc] initWithSlicePoint:slicePoint annotation:a handler:handler] autorelease];
}

- (id)initWithSlicePoint:(NSPoint)slicePoint annotation:(NIAnnotation<NIPlaneAnnotation>*)a handler:(void(^)(NIAnnotatedGeneratorRequestView* view, NIVector pd))handler {
    if ((self = [super initWithSlicePoint:slicePoint annotation:a])) {
        self.handler = handler;
    }
    
    return self;
}

- (void)dealloc {
    self.handler = nil;
    [super dealloc];
}

- (void)translateFromPlaneVector:(NIVector)vfrom toPlaneVector:(NIVector)vto view:(NIAnnotatedGeneratorRequestView *)view {
    self.handler(view, NIVectorSubtract(vto, vfrom));
}

@end
