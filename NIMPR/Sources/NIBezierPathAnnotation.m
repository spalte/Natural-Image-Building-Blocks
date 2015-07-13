//
//  NIBezierPathAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/9/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIBezierPathAnnotation.h"

@implementation NIBezierPathAnnotation

- (NIBezierPath*)NIBezierPath {
    [NSException raise:NSInvalidArgumentException format:@"Method -[%@ NIBezierPath] must be implemented for all NIBezierPathAnnotation subclasses", self.className];
    return nil;
}

+ (NSSet*)keyPathsForValuesAffectingAnnotation {
    return [[super keyPathsForValuesAffectingAnnotation] setByAddingObject:@"NIBezierPath"];
}

- (void)drawInView:(NIAnnotatedGeneratorRequestView*)view {
    NIObliqueSliceGeneratorRequest* req = (id)view.presentedGeneratorRequest;
    NIAffineTransform dicomToSliceTransform = NIAffineTransformInvert(req.sliceToDicomTransform);
    
    NSColor* color = self.color;
    
    NIBezierPath* path = [self.NIBezierPath bezierPathByApplyingTransform:dicomToSliceTransform];
    
    [[color colorWithAlphaComponent:color.alphaComponent*.2] setStroke];
    [path.NSBezierPath stroke];
    
    // clip and draw the part in the current slab
    
    [color set];
    
    CGFloat sl = CGFloatMax(req.slabWidth/2, view.maximumDistanceToPlane);
    
    NIMutableBezierPath* mpath = [[path mutableCopy] autorelease];
    [mpath addEndpointsAtIntersectionsWithPlane:NIPlaneMake(NIVectorMake(0,0,sl),NIVectorMake(0,0,1))];
    [mpath addEndpointsAtIntersectionsWithPlane:NIPlaneMake(NIVectorMake(0,0,-sl),NIVectorMake(0,0,1))];
    
    NIMutableBezierPath* cpath = [NIMutableBezierPath bezierPath];
    NSMutableArray* cpathp = [NSMutableArray array];
    NIVector ip, bp; BOOL ipset = NO, bpin = NO;
    NIVector c1, c2, ep;
    NSInteger elementCount = mpath.elementCount;
    for (NSInteger i = 0; i < elementCount; ++i)
        switch ([mpath elementAtIndex:i control1:&c1 control2:&c2 endpoint:&ep]) {
            case NIMoveToBezierPathElement: {
                bp = ep; bpin = NO;
                if (!ipset) ip = ep;
            } break;
            case NILineToBezierPathElement: {
                CGFloat mpz = (bp.z+ep.z)/2;
                if (mpz <= sl && mpz >= -sl) {
                    if (!bpin)
                        [cpath moveToVector:bp];
                    [cpath lineToVector:ep];
                    [cpathp addObject:@[ [NSValue valueWithNIVector:bp], [NSValue valueWithNIVector:ep] ]];
                    bpin = YES;
                } else
                    bpin = NO;
                bp = ep;
            } break;
            case NICurveToBezierPathElement: {
                CGFloat mpz = (bp.z+ep.z)/2;
                if (mpz <= sl && mpz >= -sl) {
                    if (!bpin)
                        [cpath moveToVector:bp];
                    [cpath curveToVector:ep controlVector1:c1 controlVector2:c2];
                    [cpathp addObject:@[ [NSValue valueWithNIVector:bp], [NSValue valueWithNIVector:ep] ]];
                    bpin = YES;
                } else
                    bpin = NO;
                bp = ep;
            } break;
            case NICloseBezierPathElement: {
                [cpath close];
            } break;
        }
    
    [cpath.NSBezierPath stroke];
    
    // points
    
    const CGFloat radius = 0.5;
    for (NSValue* pv in [path intersectionsWithPlane:NIPlaneMake(NIVectorZero,NIVectorMake(0,0,1))]) { // TODO: maybe only draw these where the corresponding bezier line segment has distance(bp,ep) < 1 to avoid drawing twice (especially for when we'll have opacity)
        NIVector p = pv.NIVectorValue;
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(p.x-radius, p.y-radius, radius*2, radius*2)] fill];
    }
}

@end

@implementation NINSBezierPathAnnotation

@synthesize sliceToDicomTransform = _sliceToDicomTransform;

- (instancetype)initWithTransform:(NIAffineTransform)sliceToDicomTransform {
    if ((self = [super init])) {
        self.sliceToDicomTransform = sliceToDicomTransform;
    }
    
    return self;
}

- (NIBezierPath*)NIBezierPath {
    NIMutableBezierPath* p = [NIMutableBezierPath bezierPath];
    NIAffineTransform transform = self.sliceToDicomTransform;
    
    NSBezierPath* nsp = self.NSBezierPath;
    NSPoint points[3];
    NSInteger elementCount = nsp.elementCount;
    for (NSInteger i = 0; i < elementCount; ++i)
        switch ([nsp elementAtIndex:i associatedPoints:points]) {
            case NSMoveToBezierPathElement: {
                [p moveToVector:NIVectorApplyTransform(NIVectorMakeFromNSPoint(points[0]), transform)];
            } break;
            case NSLineToBezierPathElement: {
                [p lineToVector:NIVectorApplyTransform(NIVectorMakeFromNSPoint(points[0]), transform)];
            } break;
            case NSCurveToBezierPathElement: {
                [p curveToVector:NIVectorApplyTransform(NIVectorMakeFromNSPoint(points[2]), transform) controlVector1:NIVectorApplyTransform(NIVectorMakeFromNSPoint(points[0]), transform) controlVector2:NIVectorApplyTransform(NIVectorMakeFromNSPoint(points[1]), transform)];
            } break;
            case NSClosePathBezierPathElement: {
                [p close];
            } break;
        }
    
    return p;
}

+ (NSSet*)keyPathsForValuesAffectingNIBezierPath {
    return [NSSet setWithObject:@"NSBezierPath"];
}

- (NSBezierPath*)NSBezierPath {
    [NSException raise:NSInvalidArgumentException format:@"Method -[%@ NSBezierPath] must be implemented for all NINSBezierPathAnnotation subclasses", self.className];
    return nil;
}

@end