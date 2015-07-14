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

+ (NIBezierPath*)bezierPath:(NIBezierPath*)path minmax:(CGFloat)mm external:(NIBezierPath**)repath complete:(BOOL)complete {
    NIMutableBezierPath* mpath = [[path mutableCopy] autorelease];
    [mpath addEndpointsAtIntersectionsWithPlane:NIPlaneMake(NIVectorMake(0, 0, mm), NIVectorMake(0, 0, 1))];
    [mpath addEndpointsAtIntersectionsWithPlane:NIPlaneMake(NIVectorMake(0, 0, -mm), NIVectorMake(0, 0, 1))];

    NIMutableBezierPath* rpath = [NIMutableBezierPath bezierPath];
    
    NIMutableBezierPath* epath = repath? [NIMutableBezierPath bezierPath] : nil;
    if (repath) *repath = epath;
    
    NIVector rip, rbp; BOOL ripset = NO, rbpin = NO;
    NIVector c1, c2, ep;
    NSInteger elementCount = mpath.elementCount;
    for (NSInteger i = 0; i < elementCount; ++i)
        switch ([mpath elementAtIndex:i control1:&c1 control2:&c2 endpoint:&ep]) {
            case NIMoveToBezierPathElement: {
                rbp = ep; rbpin = NO;
            } break;
            case NILineToBezierPathElement: {
                CGFloat mpz = (rbp.z+ep.z)/2;
                if (mpz <= mm && mpz >= -mm) {
                    if (!rbpin) {
                        if (!ripset) {
                            rip = rbp; ripset = YES; }
                        if (!complete || !rpath.elementCount)
                            [rpath moveToVector:rbp];
                        else [rpath lineToVector:rbp]; }
                    [rpath lineToVector:ep];
                    rbpin = YES;
                } else
                    rbpin = NO;
                rbp = ep;
            } break;
            case NICurveToBezierPathElement: {
                CGFloat mpz = (rbp.z+ep.z)/2;
                if (mpz <= mm && mpz >= -mm) {
                    if (!rbpin) {
                        if (!ripset) {
                            rip = rbp; ripset = YES; }
                        if (!complete || !rpath.elementCount)
                            [rpath moveToVector:rbp];
                        else [rpath lineToVector:rbp]; }
                    [rpath curveToVector:ep controlVector1:c1 controlVector2:c2];
                    rbpin = YES;
                } else
                    rbpin = NO;
                rbp = ep;
            } break;
            case NICloseBezierPathElement: {
                if (ripset) {
                    CGFloat mpz = (rbp.z+rip.z)/2;
                    if (mpz <= mm && mpz >= -mm) {
                        if (!rbpin) {
                            if (!complete || !rpath.elementCount)
                                [rpath moveToVector:rbp];
                            else [rpath lineToVector:rbp]; }
                        if (complete) {
                            [rpath lineToVector:rip];
                            rbp = rip;
                        } else
                            [rpath close];
                        rbpin = YES;
                    } else
                        rbpin = NO;
                    rbp = rip;
                }
            } break;
        }
    
    return rpath;
}

- (NIBezierPath*)NIBezierPathForSlabView:(NIAnnotatedGeneratorRequestView*)view external:(NIBezierPath**)repath {
    return [self NIBezierPathForSlabView:view external:repath complete:NO];
}

- (NIBezierPath*)NIBezierPathForSlabView:(NIAnnotatedGeneratorRequestView*)view external:(NIBezierPath**)repath complete:(BOOL)complete {
    NIObliqueSliceGeneratorRequest* req = (id)view.presentedGeneratorRequest;
    NIAffineTransform dicomToSliceTransform = NIAffineTransformInvert(req.sliceToDicomTransform);
    
    NIBezierPath* path = [self.NIBezierPath bezierPathByApplyingTransform:dicomToSliceTransform];
    
    return [self.class bezierPath:path minmax:CGFloatMax(req.slabWidth/2, view.maximumDistanceToPlane) external:repath complete:complete];
}

- (void)drawInView:(NIAnnotatedGeneratorRequestView*)view {
    NIObliqueSliceGeneratorRequest* req = (id)view.presentedGeneratorRequest;
    NIAffineTransform dicomToSliceTransform = NIAffineTransformInvert(req.sliceToDicomTransform);
    
    NIBezierPath* path = [self.NIBezierPath bezierPathByApplyingTransform:dicomToSliceTransform];
    
    NSColor* color = self.color;
    [[color colorWithAlphaComponent:color.alphaComponent*.2] set];
    [path.NSBezierPath stroke];
    
    // clip and draw the part in the current slab
    
    NIBezierPath *epath, *cpath = [self NIBezierPathForSlabView:view external:&epath];
    
    [self.color set];
    [cpath.NSBezierPath stroke];
    // TODO: draw epath with alpha, stop drawing full path
    
    // points
    
    const CGFloat radius = 0.5;
    for (NSValue* pv in [path intersectionsWithPlane:NIPlaneMake(NIVectorZero,NIVectorMake(0,0,1))]) { // TODO: maybe only draw these where the corresponding bezier line segment has distance(bp,ep) < 1 to avoid drawing twice (especially for when we'll have opacity)
        NIVector p = pv.NIVectorValue;
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(p.x-radius, p.y-radius, radius*2, radius*2)] fill];
    }
}

@end

@implementation NINSBezierPathAnnotation

@synthesize planeToDicomTransform = _planeToDicomTransform;

- (instancetype)initWithTransform:(NIAffineTransform)sliceToDicomTransform {
    if ((self = [super init])) {
        self.planeToDicomTransform = sliceToDicomTransform;
    }
    
    return self;
}

- (NIBezierPath*)NIBezierPath {
    NIMutableBezierPath* p = [NIMutableBezierPath bezierPath];
    NIAffineTransform transform = self.planeToDicomTransform;
    
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