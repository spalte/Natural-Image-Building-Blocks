//
//  NIBezierPathAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/9/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIBezierPathAnnotation.h"
#import "NSBezierPath+NIMPR.h"
#import <objc/runtime.h>

@implementation NIBezierPathAnnotation

+ (void)load {
    [self.class retain:[NSBundle observeNotification:NSBundleDidLoadNotification block:^(NSNotification* n) {
        for (NSString* className in n.userInfo[NSLoadedClasses]) {
            Class class = [n.object classNamed:className];
            if (class_getClassMethod(class, @selector(isAbstract)) == class_getClassMethod(class_getSuperclass(class), @selector(isAbstract)) || !class.isAbstract)
                for (Class sc = class_getSuperclass(class); sc; sc = class_getSuperclass(sc))
                    if (sc == NIBezierPathAnnotation.class) {
                        if (class_getMethodImplementation(object_getClass(class), @selector(keyPathsForValuesAffectingNIBezierPath)) == class_getMethodImplementation(object_getClass(NIBezierPathAnnotation.class), @selector(keyPathsForValuesAffectingNIBezierPath)))
                            NSLog(@"Warning: missing method implementation +[%@ keyPathsForValuesAffectingNIBezierPath]", className);
                    }
        }
    }]];
}

@synthesize fill = _fill;

- (instancetype)init {
    if ((self = [super init])) {
        self.fill = [self.class defaultFill];
    }
    
    return self;
}

static NSString* const NIBezierPathAnnotationFill = @"fill";

- (instancetype)initWithCoder:(NSCoder*)coder {
    if ((self = [super initWithCoder:coder])) {
        if ([coder containsValueForKey:NIBezierPathAnnotationFill])
            self.fill = [coder decodeBoolForKey:NIBezierPathAnnotationFill];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [super encodeWithCoder:coder];
    if (self.fill != [self.class defaultFill])
        [coder encodeBool:self.fill forKey:NIBezierPathAnnotationFill];
}

+ (BOOL)defaultFill {
    return YES;
}

+ (NSSet*)keyPathsForValuesAffectingAnnotation {
    return [[super keyPathsForValuesAffectingAnnotation] setByAddingObject:@"NIBezierPath"];
}

+ (BOOL)isAbstract {
    return YES;
}

+ (NSSet*)keyPathsForValuesAffectingNIBezierPath {
    return [NSSet set];
}

- (NIBezierPath*)NIBezierPath {
    [NSException raise:NSInvalidArgumentException format:@"Method -[%@ NIBezierPath] must be implemented for all NIBezierPathAnnotation subclasses", self.className];
    return nil;
}

- (NIMask*)maskForVolume:(NIVolumeData*)volume {
    NIBezierPath* path = [self.NIBezierPath bezierPathByApplyingTransform:volume.volumeTransform];
    NIMutableBezierPath* mpath = [[path mutableCopy] autorelease];
    
    const CGFloat xbf = [mpath bottomBoundingPlaneForNormal:NIVectorXBasis].point.x, xtf = [mpath topBoundingPlaneForNormal:NIVectorXBasis].point.x;
    const NSInteger xb = CGFloatFloor(xbf), xt = CGFloatCeil(xtf);
    const CGFloat ybf = [mpath bottomBoundingPlaneForNormal:NIVectorYBasis].point.y, ytf = [mpath topBoundingPlaneForNormal:NIVectorYBasis].point.y;
    const NSInteger yb = CGFloatFloor(ybf), yt = CGFloatCeil(ytf);
    const CGFloat zbf = [mpath bottomBoundingPlaneForNormal:NIVectorZBasis].point.z, ztf = [mpath topBoundingPlaneForNormal:NIVectorZBasis].point.z;
    const NSInteger zb = CGFloatFloor(zbf), zt = CGFloatCeil(ztf);
    [mpath applyAffineTransform:NIAffineTransformMakeTranslation(-xb, -yb, -zb)];

    const NSUInteger mwidth = xt-xb+1, mheight = yt-yb+1, mdepth = zt-zb+1, mcount = mwidth*mheight*mdepth;
    float* mfloats = calloc(mcount, sizeof(float));
    NSData* mdata = [NSData dataWithBytesNoCopy:mfloats length:sizeof(float)*mcount];
    
    [mpath subdivide:.1];
    for (NSInteger i = 0; i < mpath.elementCount; ++i) {
        NIVector ep;
        /*NSBezierPathElement e = */[mpath elementAtIndex:i control1:NULL control2:NULL endpoint:&ep];
//        NSLog(@"--- [%d,%d,%d]", (int)CGFloatRound(ep.x), (int)CGFloatRound(ep.y), (int)CGFloatRound(ep.z));
        NSInteger x = CGFloatRound(ep.x), y = CGFloatRound(ep.y), z = CGFloatRound(ep.z);
//        NSLog(@"MASK! [%ld,%ld,%ld] (%f,%f,%f)", (long)x, (long)y, (long)z, ep.x, ep.y, ep.z);
        if (x >= 0 && y >= 0 && z >= 0 && x < mwidth && y < mheight && z < mdepth)
            mfloats[x+y*mwidth+z*mheight*mwidth] = 1;
    }
    
    NIMask* mask = [[NIMask maskFromVolumeData:[[[NIVolumeData alloc] initWithData:mdata pixelsWide:mwidth pixelsHigh:mheight pixelsDeep:mdepth volumeTransform:NIAffineTransformConcat(volume.volumeTransform, NIAffineTransformMakeTranslation(-xb, -yb, -zb)) outOfBoundsValue:0] autorelease] volumeTransform:NULL] maskByTranslatingByX:xb Y:yb Z:zb];
    
    if (self.isPlanar && path.elementCount > 2) {
        NIPlane plane = [path leastSquaresPlane];
        if (NIPlaneIsValid(plane)) {
            NIAffineTransform pt = NIAffineTransformIdentity;//NIAffineTransformMakeTranslation(-xbf, -ybf, -zbf);//(-CGFloatFloor(xbf+(xtf-xbf)/2), -CGFloatFloor(ybf+(ytf-ybf)/2), -CGFloatFloor(zbf+(ztf-zbf)/2));
            // rotate so the normal matches the Z axis
            NIVector cp = NIVectorCrossProduct(plane.normal, NIVectorZBasis);
            if (!NIVectorIsZero(cp)) {
                CGFloat angle = NIVectorAngleBetweenVectorsAroundVector(NIVectorZBasis, plane.normal, cp);
                if (angle)
                    pt = NIAffineTransformConcat(pt, NIAffineTransformMakeRotationAroundVector(angle, cp));
            }
            
            NIBezierPath* ppath = [path bezierPathByApplyingTransform:pt];
            pt = NIAffineTransformConcat(pt, NIAffineTransformMakeTranslation(-CGFloatFloor([ppath bottomBoundingPlaneForNormal:NIVectorXBasis].point.x), -CGFloatFloor([ppath bottomBoundingPlaneForNormal:NIVectorYBasis].point.y), -CGFloatFloor([ppath bottomBoundingPlaneForNormal:NIVectorZBasis].point.z)));
            ppath = [path bezierPathByApplyingTransform:pt];
            
            // get the paths plane projection
            NSBezierPath* path = [ppath NSBezierPath];
            
            // draw the annotation path into a bitmap
            NSRect pbounds = path.bounds;
            const NSUInteger pwidth = CGFloatCeil(pbounds.size.width), pheight = CGFloatCeil(pbounds.size.height), pcount = pwidth*pheight;
            NSBitmapImageRep* pimgref = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:pwidth pixelsHigh:pheight bitsPerSample:sizeof(float)*8 samplesPerPixel:1 // TODO: can we use NSFloatImageRep instead?
                                                                                   hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bitmapFormat:NSFloatingPointSamplesBitmapFormat bytesPerRow:sizeof(float)*pwidth bitsPerPixel:sizeof(float)*8] autorelease];
            NSGraphicsContext* pctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:pimgref];
            [NSGraphicsContext saveGraphicsState];
            [NSGraphicsContext setCurrentContext:pctx];
            [[NSColor whiteColor] set];
            if (self.fill)
                [path fill];
            else [path stroke];
            [NSGraphicsContext restoreGraphicsState];
            
            // use the bitmap for a flat volume and resample it
            NIVolumeData* pvol = [[[NIVolumeData alloc] initWithData:[NSData dataWithBytesNoCopy:pimgref.bitmapData length:pcount*sizeof(float) freeWhenDone:NO] pixelsWide:pwidth pixelsHigh:pheight pixelsDeep:1 volumeTransform:pt outOfBoundsValue:0] autorelease];
            pvol = [pvol volumeDataResampledWithVolumeTransform:NIAffineTransformIdentity interpolationMode:NIInterpolationModeCubic];
            NIMask* pmask = [NIMask maskFromVolumeData:pvol volumeTransform:&pt];
            pmask = [pmask maskByTranslatingByX:-pt.m41 Y:-pt.m42 Z:-pt.m43];
            pmask = [pmask binaryMask];
            
            return pmask;
        }
    }
    
    return mask;
}

+ (NIBezierPath*)bezierPath:(NIBezierPath*)path minmax:(CGFloat)mm complete:(BOOL)complete {
    NIMutableBezierPath* mpath = [[path mutableCopy] autorelease];
    [mpath addEndpointsAtIntersectionsWithPlane:NIPlaneMake(NIVectorMake(0, 0, mm), NIVectorZBasis)];
    [mpath addEndpointsAtIntersectionsWithPlane:NIPlaneMake(NIVectorMake(0, 0, -mm), NIVectorZBasis)];

    NIMutableBezierPath* rpath = [NIMutableBezierPath bezierPath];
    
    NIVector ip, bp = NIVectorZero; BOOL ipset = NO, bpin = NO;
    NIVector c1, c2, ep;
    NSInteger elementCount = mpath.elementCount;
    NIBezierPathElement e;
    for (NSInteger i = 0; i < elementCount; ++i)
        switch (e = [mpath elementAtIndex:i control1:&c1 control2:&c2 endpoint:&ep]) {
            case NIMoveToBezierPathElement: {
                bp = ep; bpin = NO;
            } break;
            case NILineToBezierPathElement:
            case NICurveToBezierPathElement: {
                CGFloat mpz = (bp.z+ep.z)/2;
                if (mpz <= mm && mpz >= -mm) {
                    if (!bpin) {
                        if (!ipset) {
                            ip = bp; ipset = YES; }
                        if (!complete || !rpath.elementCount)
                            [rpath moveToVector:bp];
                        else [rpath lineToVector:bp]; }
                    if (e == NILineToBezierPathElement)
                        [rpath lineToVector:ep];
                    else [rpath curveToVector:ep controlVector1:c1 controlVector2:c2];
                    bpin = YES;
                } else
                    bpin = NO;
                bp = ep;
            } break;
            case NICloseBezierPathElement: {
                if (ipset) {
                    CGFloat mpz = (bp.z+ip.z)/2;
                    if (mpz <= mm && mpz >= -mm) {
                        if (!bpin) {
                            if (!complete || !rpath.elementCount)
                                [rpath moveToVector:bp];
                            else [rpath lineToVector:bp]; }
                        if (complete) {
                            [rpath lineToVector:ip];
                        } else
                            [rpath close];
                        bpin = YES;
                    } else
                        bpin = NO;
                    bp = ip;
                }
            } break;
        }
    
    return rpath;
}

- (NIBezierPath*)NIBezierPathForSlabView:(NIAnnotatedGeneratorRequestView*)view {
    return [self NIBezierPathForSlabView:view complete:NO];
}

- (NIBezierPath*)NIBezierPathForSlabView:(NIAnnotatedGeneratorRequestView*)view complete:(BOOL)complete {
    NIObliqueSliceGeneratorRequest* req = view.presentedGeneratorRequest;
    NIAffineTransform dicomToSliceTransform = NIAffineTransformInvert(req.sliceToDicomTransform);
    
    NIBezierPath* path = [self.NIBezierPath bezierPathByApplyingTransform:dicomToSliceTransform];
    
    return [self.class bezierPath:path minmax:CGFloatMax(req.slabWidth/2, [NIAnnotatedGeneratorRequestView maximumDistanceToPlaneForRequest:view.presentedGeneratorRequest]) complete:complete];
}

- (BOOL)isPlanar {
    return [self.NIBezierPath isPlanar];
}

- (BOOL)isSolid {
    return NO;
}

- (void)drawInView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache {
    [super drawInView:view cache:cache];
    
    NIObliqueSliceGeneratorRequest* req = view.presentedGeneratorRequest;
    NIAffineTransform dicomToSliceTransform = NIAffineTransformInvert(req.sliceToDicomTransform);
    
    NIBezierPath* slicePath = [self.NIBezierPath bezierPathByApplyingTransform:dicomToSliceTransform];
    
    NSColor* color = [self.class color:self];
    if ([view.highlightedAnnotations containsObject:self])
        color = [view.highlightColor colorWithAlphaComponent:color.alphaComponent];

    [[color colorWithAlphaComponent:color.alphaComponent*view.annotationsBaseAlpha] set];
    
    [slicePath.NSBezierPath stroke];
    
    // clip and draw the part in the current slab
    
    NIBezierPath *cpath = [self NIBezierPathForSlabView:view];
    
    [color set];
    [cpath.NSBezierPath stroke];
    // TODO: draw ext path with alpha, stop drawing full path
    
    // points
    
    const CGFloat radius = 0.5;
    for (NSValue* pv in [slicePath intersectionsWithPlane:NIPlaneZZero]) { // TODO: maybe only draw these where the corresponding bezier line segment has distance(bp,ep) < 1 to avoid drawing twice (especially for when we'll have opacity)
        NIVector p = pv.NIVectorValue;
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(p.x-radius, p.y-radius, radius*2, radius*2)] fill];
    }
    
//    return [slicePath NSBezierPath];
}

- (CGFloat)distanceToSlicePoint:(NSPoint)point cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view closestPoint:(NSPoint*)rpoint {
    NIBezierPath* slicePath = [[self.NIBezierPath bezierPathByApplyingTransform:NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform)] bezierPathByCollapsingZ];
    
    if (self.isSolid && [slicePath.NSBezierPath containsPoint:point]) {
        if (rpoint) *rpoint = point;
        return 0;
    }
    
    NIVector closestVector = NIVectorZero;
    [slicePath relativePositionClosestToLine:NILineMake(NIVectorMakeFromNSPoint(point), NIVectorZBasis) closestVector:&closestVector];
    
    if (rpoint) *rpoint = NSPointFromNIVector(closestVector);
    return NIVectorDistance(NIVectorMakeFromNSPoint(point), closestVector);
}

- (BOOL)intersectsSliceRect:(NSRect)rect cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view {
    NIBezierPath* slicePath = [self.NIBezierPath bezierPathByApplyingTransform:NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform)];
    return [slicePath.NSBezierPath intersectsRect:rect];
}

@end

static NSString* const NINSBezierPathAnnotationTransform = @"transform";

@implementation NINSBezierPathAnnotation

+ (void)load {
    [self.class retain:[NSBundle observeNotification:NSBundleDidLoadNotification block:^(NSNotification* n) {
        for (NSString* className in n.userInfo[NSLoadedClasses]) {
            Class class = [n.object classNamed:className];
            if (class_getClassMethod(class, @selector(isAbstract)) == class_getClassMethod(class_getSuperclass(class), @selector(isAbstract)) || !class.isAbstract)
                for (Class sc = class_getSuperclass(class); sc; sc = class_getSuperclass(sc))
                    if (sc == NINSBezierPathAnnotation.class) {
                        if (class_getMethodImplementation(object_getClass(class), @selector(keyPathsForValuesAffectingNSBezierPath)) == class_getMethodImplementation(object_getClass(NINSBezierPathAnnotation.class), @selector(keyPathsForValuesAffectingNSBezierPath)))
                            NSLog(@"Warning: missing method implementation +[%@ keyPathsForValuesAffectingNSBezierPath]", className);
                    }
        }
    }]];
}

@synthesize modelToDicomTransform = _modelToDicomTransform;

- (instancetype)init {
    if ((self = [super init])) {
        self.modelToDicomTransform = NIAffineTransformIdentity;
    }
    
    return self;
}

- (instancetype)initWithTransform:(NIAffineTransform)modelToDicomTransform {
    if ((self = [self init])) {
        self.modelToDicomTransform = modelToDicomTransform;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        self.modelToDicomTransform = [[[coder decodeObjectForKey:NINSBezierPathAnnotationTransform] requireValueWithObjCType:@encode(NIAffineTransform)] NIAffineTransformValue];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:[NSValue valueWithNIAffineTransform:self.modelToDicomTransform] forKey:NINSBezierPathAnnotationTransform];
}

+ (BOOL)isAbstract {
    return YES;
}

- (void)translate:(NIVector)translation {
    self.modelToDicomTransform = NIAffineTransformConcat(self.modelToDicomTransform, NIAffineTransformMakeTranslationWithVector(translation));
}

- (NIBezierPath*)NIBezierPath {
    if (!NIAffineTransformIsAffine(self.modelToDicomTransform))
        return nil;
    return [[NIBezierPath bezierPathWithNSBezierPath:self.NSBezierPath] bezierPathByApplyingTransform:self.modelToDicomTransform];
}

+ (NSSet*)keyPathsForValuesAffectingNIBezierPath {
    return [[super keyPathsForValuesAffectingNIBezierPath] setByAddingObjects: @"NSBezierPath", @"modelToDicomTransform", nil];
}

+ (NSSet*)keyPathsForValuesAffectingNSBezierPath {
    return [NSSet set];
}

- (NSBezierPath*)NSBezierPath {
    [NSException raise:NSInvalidArgumentException format:@"Method -[%@ NSBezierPath] must be implemented for all NINSBezierPathAnnotation subclasses", self.className];
    return nil;
}



@end