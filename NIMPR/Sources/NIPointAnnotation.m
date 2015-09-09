//
//  NIPointAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/8/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIPointAnnotation.h"
#import "NIAnnotationHandle.h"

static NSString* const NIPointAnnotationCoordsKey = @"coords";

@implementation NIPointAnnotation

@synthesize vector = _vector;

+ (NSSet*)keyPathsForValuesAffectingAnnotation {
    return [[super keyPathsForValuesAffectingAnnotation] setByAddingObject:@"vector"];
}

+ (instancetype)pointWithVector:(NIVector)vector {
    return [[[self.class alloc] initWithVector:vector] autorelease];
}

- (instancetype)init {
    if ((self = [super init])) {
    }
    
    return self;
}

- (instancetype)initWithVector:(NIVector)vector {
    if ((self = [self init])) {
        self.vector = vector;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    if ((self = [super initWithCoder:coder])) {
        self.vector = [[[coder decodeObjectForKey:NIPointAnnotationCoordsKey] requireValueWithObjCType:@encode(NIVector)] NIVectorValue];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:[NSValue valueWithNIVector:self.vector] forKey:NIPointAnnotationCoordsKey];
}

- (void)translate:(NIVector)translation {
    self.vector = NIVectorAdd(self.vector, translation);
}

- (NIMask*)maskForVolume:(NIVolumeData *)volume {
    NIVector vv = [volume convertVolumeVectorFromDICOMVector:self.vector];
    return [[NIMask maskWithCubeSize:1] maskByTranslatingByX:vv.x Y:vv.y Z:vv.z];
}

- (void)drawInView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache {
    NIObliqueSliceGeneratorRequest* req = view.presentedGeneratorRequest;

    CGFloat distanceToPlane = CGFloatMax(NIVectorDistanceToPlane(self.vector, req.plane) - req.slabWidth/2, 0), maximumDistanceToPlane = view.maximumDistanceToPlane;
    
    NSPoint p = [view convertPointFromDICOMVector:self.vector];
    
    CGFloat minRadius = 0.5, maxRadius = 2, radius = CGFloatMax(minRadius, maxRadius-(maxRadius-minRadius)/maximumDistanceToPlane*(distanceToPlane-maximumDistanceToPlane));
    NSRect ovalRect = NSMakeRect(p.x - radius, p.y - radius, radius*2, radius*2);
    NSBezierPath* path = [NSBezierPath bezierPathWithOvalInRect:ovalRect];

    NSColor* color = [self.class color:self];
    if ([view.highlightedAnnotations containsObject:self])
        color = [view.highlightColor colorWithAlphaComponent:color.alphaComponent];

    if (distanceToPlane > maximumDistanceToPlane)
        color = [color colorWithAlphaComponent:color.alphaComponent*view.annotationsBaseAlpha];
    
    [color setFill];
    [path fill];
//    [[[NSColor blackColor] colorWithAlphaComponent:color.alphaComponent*.6] setStroke];
//    [path stroke];
}

- (CGFloat)distanceToSlicePoint:(NSPoint)point cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view closestPoint:(NSPoint*)closestPoint {
    NSPoint vpoint = NSPointFromNIVector(NIVectorApplyTransform(self.vector, NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform)));
    if (closestPoint) *closestPoint = vpoint;
    return NIVectorDistance(NIVectorMakeFromNSPoint(point), NIVectorMakeFromNSPoint(vpoint));
}

- (BOOL)intersectsSliceRect:(NSRect)rect cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view {
    NSPoint point = NSPointFromNIVector(NIVectorApplyTransform(self.vector, NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform)));
    return NSPointInRect(point, rect);
}

- (NSSet*)handlesInView:(NIAnnotatedGeneratorRequestView*)view {
    return [NSSet setWithObjects:
            [NIAnnotationBlockHandle handleAtSlicePoint:NSPointFromNIVector(NIVectorApplyTransform(self.vector, NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform)))
                                                  block:^(NIAnnotatedGeneratorRequestView* view, NSEvent* event, NIVector deltaDicomVector) {
                                                      self.vector = NIVectorAdd(self.vector, deltaDicomVector);
                                                  }], nil];
}

@end
