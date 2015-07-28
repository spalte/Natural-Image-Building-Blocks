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

- (void)translateFromSlicePoint:(NSPoint)from toSlicePoint:(NSPoint)to view:(NIAnnotatedGeneratorRequestView*)view event:(NSEvent*)event {
    NSLog(@"Warning: -[%@ translateFromSlicePoint:toSlicePoint:view:event:]", self.className);
}

@end

@interface NIAnnotationBlockHandle ()

@property(copy) void (^block)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector dd);

@end

@implementation NIAnnotationBlockHandle

@synthesize block = _block;

+ (instancetype)handleAtSliceVector:(NIVector)sliceVector block:(void(^)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector dd))block {
    return [self.class handleAtSlicePoint:NSPointFromNIVector(sliceVector) block:block];
}

+ (instancetype)handleAtSlicePoint:(NSPoint)slicePoint block:(void(^)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector dd))block {
    return [[[self.class alloc] initWithSlicePoint:slicePoint block:block] autorelease];
}

- (id)initWithSlicePoint:(NSPoint)slicePoint block:(void(^)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector dd))block {
    if ((self = [super initWithSlicePoint:slicePoint])) {
        self.block = block;
    }
    
    return self;
}

- (void)dealloc {
    self.block = nil;
    [super dealloc];
}

- (void)translateFromSlicePoint:(NSPoint)from toSlicePoint:(NSPoint)to view:(NIAnnotatedGeneratorRequestView*)view event:(NSEvent*)event {
    self.block(view, event, NIVectorSubtract(NIVectorApplyTransform(NIVectorMakeFromNSPoint(to), view.presentedGeneratorRequest.sliceToDicomTransform), NIVectorApplyTransform(NIVectorMakeFromNSPoint(from), view.presentedGeneratorRequest.sliceToDicomTransform)));
}

@end

@interface NIPlanarAnnotationHandle ()

@property(retain) NIAnnotation<NITransformAnnotation>* annotation;

@end

@implementation NIPlanarAnnotationHandle

@synthesize annotation = _annotation;

- (id)initWithSlicePoint:(NSPoint)slicePoint annotation:(NIAnnotation<NITransformAnnotation>*)a {
    if ((self = [super initWithSlicePoint:slicePoint])) {
        self.annotation = a;
    }
    
    return self;
}

- (void)dealloc {
    self.annotation = nil;
    [super dealloc];
}

- (void)translateFromSlicePoint:(NSPoint)sfrom toSlicePoint:(NSPoint)sto view:(NIAnnotatedGeneratorRequestView *)view event:(NSEvent*)event {
    NIAffineTransform sliceToPlaneTransform = NIAffineTransformConcat(view.presentedGeneratorRequest.sliceToDicomTransform, NIAffineTransformInvert(self.annotation.modelToDicomTransform));
    NIVector pfrom = NILineIntersectionWithPlane(NILineApplyTransform(NILineMake(NIVectorMakeFromNSPoint(sfrom), NIVectorZBasis), sliceToPlaneTransform), NIPlaneZZero);
    NIVector pto = NILineIntersectionWithPlane(NILineApplyTransform(NILineMake(NIVectorMakeFromNSPoint(sto), NIVectorZBasis), sliceToPlaneTransform), NIPlaneZZero);
    [self translateFromPlaneVector:pfrom toPlaneVector:pto view:view event:event];
}

- (void)translateFromPlaneVector:(NIVector)vfrom toPlaneVector:(NIVector)vto view:(NIAnnotatedGeneratorRequestView *)view event:(NSEvent*)event {
    NSLog(@"Warning: -[%@ translateFromPlaneVector:toPlaneVector:view:event:] is missing", self.className);
}

@end

@interface NIPlanarAnnotationBlockHandle ()

@property(copy) void (^block)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector pd);

@end

@implementation NIPlanarAnnotationBlockHandle

@synthesize block = _block;

+ (instancetype)handleAtSliceVector:(NIVector)sliceVector annotation:(NIAnnotation<NITransformAnnotation>*)a block:(void(^)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector pd))block {
    return [self.class handleAtSlicePoint:NSPointFromNIVector(sliceVector) annotation:a block:block];
}

+ (instancetype)handleAtSlicePoint:(NSPoint)slicePoint annotation:(NIAnnotation<NITransformAnnotation>*)a block:(void(^)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector pd))block {
    return [[[self.class alloc] initWithSlicePoint:slicePoint annotation:a block:block] autorelease];
}

- (id)initWithSlicePoint:(NSPoint)slicePoint annotation:(NIAnnotation<NITransformAnnotation>*)a block:(void(^)(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector pd))block {
    if ((self = [super initWithSlicePoint:slicePoint annotation:a])) {
        self.block = block;
    }
    
    return self;
}

- (void)dealloc {
    self.block = nil;
    [super dealloc];
}

- (void)translateFromPlaneVector:(NIVector)vfrom toPlaneVector:(NIVector)vto view:(NIAnnotatedGeneratorRequestView *)view event:(NSEvent*)event {
    self.block(view, event, NIVectorSubtract(vto, vfrom));
}

@end
