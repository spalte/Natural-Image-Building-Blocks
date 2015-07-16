//
//  NIPointAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/8/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIPointAnnotation.h"
#import <NIBuildingBlocks/NIGeneratorRequest.h>

@implementation NIPointAnnotation

@synthesize vector = _vector;
//@dynamic x, y, z;

+ (NSSet*)keyPathsForValuesAffectingAnnotation {
    return [[super keyPathsForValuesAffectingAnnotation] setByAddingObject:@"vector"];
}

- (instancetype)initWithVector:(NIVector)vector {
    if ((self = [super init])) {
        self.vector = vector;
    }
    
    return self;
}

- (NSBezierPath*)drawInView:(NIAnnotatedGeneratorRequestView*)view {
    NIObliqueSliceGeneratorRequest* req = view.presentedGeneratorRequest;

    CGFloat distanceToPlane = CGFloatMax(NIVectorDistanceToPlane(self.vector, req.plane) - req.slabWidth/2, 0), maximumDistanceToPlane = view.maximumDistanceToPlane;
    
    NSPoint p = [view convertPointFromDICOMVector:self.vector];
    
    CGFloat minRadius = 0.5, maxRadius = 2, radius = CGFloatMax(minRadius, maxRadius-(maxRadius-minRadius)/maximumDistanceToPlane*(distanceToPlane-maximumDistanceToPlane));
    NSRect ovalRect = NSMakeRect(p.x - radius, p.y - radius, radius*2, radius*2);
    
    NSColor* color = self.color;
    if (distanceToPlane > maximumDistanceToPlane)
        color = [color colorWithAlphaComponent:color.alphaComponent*.2];
    
    NSBezierPath* path = [NSBezierPath bezierPathWithOvalInRect:ovalRect];
    
    [color setFill];
    [path fill];
    [[[NSColor blackColor] colorWithAlphaComponent:color.alphaComponent*.6] setStroke];
    [path stroke];
    
    return path;
}

- (CGFloat)distanceToPoint:(NSPoint)point view:(NIAnnotatedGeneratorRequestView*)view closestPoint:(NSPoint*)closestPoint {
    NSPoint vpoint = NSPointFromNIVector(NIVectorApplyTransform(self.vector, NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform)));
    if (closestPoint) *closestPoint = vpoint;
    return NIVectorDistance(NIVectorMakeFromNSPoint(point), NIVectorMakeFromNSPoint(vpoint));
}

@end
