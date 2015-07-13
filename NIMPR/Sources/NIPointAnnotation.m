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

- (void)drawInView:(NIAnnotatedGeneratorRequestView*)view {
    NIObliqueSliceGeneratorRequest* req = (id)view.presentedGeneratorRequest;

    CGFloat distanceToPlane = CGFloatMax(NIVectorDistanceToPlane(self.vector, req.plane) - req.slabWidth/2, 0), maximumDistanceToPlane = view.maximumDistanceToPlane;
    if (distanceToPlane > maximumDistanceToPlane)
        return;
    
    NSPoint p = [view convertPointFromDICOMVector:self.vector];
    
    CGFloat minRadius = 0.5, maxRadius = 2, radius = maxRadius-(maxRadius-minRadius)/maximumDistanceToPlane*(distanceToPlane-maximumDistanceToPlane);
    NSRect ovalRect = NSMakeRect(p.x - radius, p.y - radius, radius*2, radius*2);
    
    NSColor* color = self.color;
    
    [color setFill];
    [[NSBezierPath bezierPathWithOvalInRect:ovalRect] fill];
    [[[NSColor blackColor] colorWithAlphaComponent:color.alphaComponent*.6] setStroke];
    [[NSBezierPath bezierPathWithOvalInRect:ovalRect] stroke];
    
//    NSFont* font = [NSFont fontWithName:@"Helvetica" size:24];
//    [@"Click Me" drawWithRect:NSMakeRect(p.x, p.y, 100, 100) options:0
//                   attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [NSColor yellowColor]}];

    
}

//static NSString* const NIPointAnnotationCoordinates = @"coordinates";
//
//- (CGFloat)x {
//    return _coordinates.x;
//}
//
//- (void)setX:(CGFloat)x {
//    [self willChangeValueForKey:NIPointAnnotationCoordinates];
//    _coordinates.x = x;
//    [self didChangeValueForKey:NIPointAnnotationCoordinates];
//}
//
//- (CGFloat)y {
//    return _coordinates.y;
//}
//
//- (void)setY:(CGFloat)y {
//    [self willChangeValueForKey:NIPointAnnotationCoordinates];
//    _coordinates.y = y;
//    [self didChangeValueForKey:NIPointAnnotationCoordinates];
//}
//
//- (CGFloat)z {
//    return _coordinates.z;
//}
//
//- (void)setZ:(CGFloat)z {
//    [self willChangeValueForKey:NIPointAnnotationCoordinates];
//    _coordinates.z = z;
//    [self didChangeValueForKey:NIPointAnnotationCoordinates];
//}

@end
