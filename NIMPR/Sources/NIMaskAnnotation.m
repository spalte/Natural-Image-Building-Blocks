//
//  NIMaskAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/13/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMaskAnnotation.h"
#import "NIAnnotationHandle.h"

static NSString* const NIMaskAnnotationMask = @"mask";

@interface NIMaskAnnotation ()

//@property(retain) NSRecursiveLock* volumeLock;

@end

@implementation NIMaskAnnotation

@synthesize mask = _mask;
@synthesize modelToDicomTransform = _modelToDicomTransform;
@synthesize volume = _volume;
//@synthesize volumeLock = _volumeLock;

+ (NSSet*)keyPathsForValuesAffectingAnnotation {
    return [[super keyPathsForValuesAffectingAnnotation] setByAddingObjects: @"mask", @"modelToDicomTransform", @"volume", nil ];
}

- (void)initNIAnnotation {
    [super initNIAnnotation];
//    self.volumeLock = [[[NSRecursiveLock alloc] init] autorelease];
    [self addObserver:self forKeyPath:@"mask" options:NSKeyValueObservingOptionNew context:NIMaskAnnotation.class];
//    [self addObserver:self forKeyPath:@"modelToDicomTransform" options:NSKeyValueObservingOptionNew context:NIMaskAnnotation.class];
    [self addObserver:self forKeyPath:@"volume" options:NSKeyValueObservingOptionNew context:NIMaskAnnotation.class];
}

- (instancetype)init {
    if ((self = [super init])) {
    }
    
    return self;
}

- (instancetype)initWithMask:(NIMask*)mask transform:(NIAffineTransform)modelToDicomTransform {
    if ((self = [self init])) {
        self.mask = mask;
        self.modelToDicomTransform = modelToDicomTransform;
    }
    
    return self;
}

- (instancetype)initWithVolume:(NIVolumeData *)volume {
    if ((self = [self init])) {
        self.volume = volume;
        self.modelToDicomTransform = NIAffineTransformIdentity;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    if ((self = [super initWithCoder:coder])) {
        self.modelToDicomTransform = [[[coder decodeObjectForKey:NIAnnotationTransformKey] requireValueWithObjCType:@encode(NIAffineTransform)] NIAffineTransformValue];
        self.mask = [[coder decodeObjectForKey:NIMaskAnnotationMask] requireKindOfClass:NIMask.class];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [super encodeWithCoder:coder];
    NIAffineTransform transform;
    NIMask* mask = [self mask:&transform];
    [coder encodeObject:[NSValue valueWithNIAffineTransform:transform] forKey:NIAnnotationTransformKey];
    [coder encodeObject:mask forKey:NIMaskAnnotationMask];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"volume" context:NIMaskAnnotation.class];
//    [self removeObserver:self forKeyPath:@"modelToDicomTransform" context:NIMaskAnnotation.class];
    [self removeObserver:self forKeyPath:@"mask" context:NIMaskAnnotation.class];
    self.mask = nil;
    self.volume = nil;
//    self.volumeLock = nil;
    [super dealloc];
}

- (void)setModelToDicomTransform:(NIAffineTransform)modelToDicomTransform {
    @synchronized(self) {
//    [self.volumeLock lock];
    _modelToDicomTransform = modelToDicomTransform;
//    [self.volumeLock unlock];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != NIMaskAnnotation.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"mask"]) {
        [_volume release];
        _volume = nil;
    }
    
    if ([keyPath isEqualToString:@"volume"]) {
        [_mask release];
        _mask = nil;
        self.modelToDicomTransform = NIAffineTransformIdentity;
    }
}

+ (BOOL)lockedDefault {
    return YES;
}

- (void)setVolume:(NIVolumeData *)volume {
    @synchronized(self) {
        if (volume == _volume)
            return;
        [_volume release];
        _volume = [volume retain];
    }
}

- (NIVolumeData*)volume {
    @synchronized(self) {
//    [self.volumeLock lock];
//    @try {
        if (!_volume)
            _volume = [[self.mask volumeDataRepresentationWithVolumeTransform:NIAffineTransformIdentity] retain];
        if (NIAffineTransformIsIdentity(self.modelToDicomTransform))
            return _volume;
        else return [_volume volumeDataByApplyingTransform:NIAffineTransformInvert(self.modelToDicomTransform)];
//    } @catch (...) {
//        @throw;
//    } @finally {
//        [self.volumeLock unlock];
//    }
    }
}

- (void)setMask:(NIMask*)mask {
    @synchronized(self) {
        if (mask == _mask)
            return;
        [_mask release];
        _mask = [mask retain];
    }
}

- (NIMask*)mask:(NIAffineTransform*)rtransform {
    @synchronized(self) {
        if (self.mask) {
            if (rtransform)
                *rtransform = self.modelToDicomTransform;
            return self.mask;
        }
        
        return [NIMask maskFromVolumeData:self.volume volumeTransform:rtransform];
    }
}


- (void)translate:(NIVector)translation {
    self.modelToDicomTransform = NIAffineTransformConcat(self.modelToDicomTransform, NIAffineTransformMakeTranslationWithVector(translation));
}

- (void)drawInView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache {
    NSMutableDictionary* rcache = cache[NIAnnotationRenderCache];
    NSImage* cimage = rcache[NIAnnotationProjection];
    NSImage* csel = rcache[@"sel"];
    NSImage* cmask = rcache[NIAnnotationProjectionMask];

    NSRect bounds = view.bounds;

    if (!cimage) {
        cimage = rcache[NIAnnotationProjection] = [[[NSImage alloc] initWithSize:bounds.size] autorelease];
        csel = rcache[@"sel"] = [[[NSImage alloc] initWithSize:bounds.size] autorelease];
        cmask = rcache[NIAnnotationProjectionMask] = [[[NSImage alloc] initWithSize:bounds.size] autorelease];
        
        NSAffineTransform* flip = [NSAffineTransform transform];
        [flip translateXBy:0 yBy:bounds.size.height];
        [flip scaleXBy:1 yBy:-1];
        
        NIVolumeData* data = [self volume];
        
        vImage_Buffer sib, sibd;//, wib;
        NSBitmapImageRep *si, *sid;//, *wi;

        NIObliqueSliceGeneratorRequest* req = [[view.presentedGeneratorRequest copy] autorelease];
        req.interpolationMode = NIInterpolationModeNearestNeighbor;
        
//        [self.volumeLock lock];
        @synchronized (self) {
        @try {
            NIVolumeData* vd = [NIGenerator synchronousRequestVolume:req volumeData:data];
            sib = [vd floatBufferForSliceAtIndex:0];
            unsigned char* bdp[1] = {sib.data};
            si = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:bdp pixelsWide:sib.width pixelsHigh:sib.height bitsPerSample:sizeof(float)*8 samplesPerPixel:1
                                                            hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bitmapFormat:NSFloatingPointSamplesBitmapFormat bytesPerRow:sib.rowBytes bitsPerPixel:sizeof(float)*8] autorelease];
            
            // render border
            
            sibd = sib; sibd.data = [[NSMutableData dataWithLength:sib.rowBytes*sib.height] mutableBytes];
            float kernel[] = {1,1,1,1,1,1,1,1,1};
            vImageDilate_PlanarF(&sib, &sibd, 0, 0, kernel, 3, 3, kvImageNoFlags);
            
            bdp[0] = sibd.data;
            sid = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:bdp pixelsWide:sib.width pixelsHigh:sib.height bitsPerSample:sizeof(float)*8 samplesPerPixel:1
                                                             hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bitmapFormat:NSFloatingPointSamplesBitmapFormat bytesPerRow:sib.rowBytes bitsPerPixel:sizeof(float)*8] autorelease];
            
            [csel lockFocus];
            NSGraphicsContext* context = [NSGraphicsContext currentContext];
            [flip set];
            CGContextClipToMask(context.CGContext, NSRectToCGRect(bounds), [sid CGImageForProposedRect:NULL context:context hints:nil]);
            [context setCompositingOperation:NSCompositeSourceOver];
            NSRectFill(bounds);
            [csel unlockFocus];
        } @catch (...) {
            @throw;
        } @finally {
//            [self.volumeLock unlock];
        }
        }
        
        // TODO: render thick slab in background and update the view, but wait for the NIGenerator async block API
        
//        {
//            NIVector dc = NIVectorApplyTransform([data convertVolumeVectorToDICOMVector:NIVectorMake(data.pixelsWide/2, data.pixelsHigh/2, data.pixelsDeep/2)], NIAffineTransformInvert(req.sliceToDicomTransform));
//            req.sliceToDicomTransform = NIAffineTransformConcat(NIAffineTransformMakeTranslation(0, 0, dc.z), req.sliceToDicomTransform);
//            req.slabWidth = data.maximumDiagonal+1;
//            req.projectionMode = NIProjectionModeMIP;
//                NIVolumeData* vd = [NIGenerator synchronousRequestVolume:req volumeData:data];
//                wib = [vd floatBufferForSliceAtIndex:0];
//                unsigned char* bdp[1] = {wib.data};
//                
//                wi = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:bdp pixelsWide:wib.width pixelsHigh:wib.height bitsPerSample:sizeof(float)*8 samplesPerPixel:1
//                                                                                  hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bitmapFormat:NSFloatingPointSamplesBitmapFormat bytesPerRow:wib.rowBytes bitsPerPixel:sizeof(float)*8] autorelease];
//        }
        
        [cimage lockFocus];
        @try {
            NSGraphicsContext* context = [NSGraphicsContext currentContext];
            [flip set];
            
            CGContextClipToMask(context.CGContext, NSRectToCGRect(bounds), [si CGImageForProposedRect:NULL context:context hints:nil]);
            [context setCompositingOperation:NSCompositeCopy];
            NSRectFill(bounds);
            
//            if (view.annotationsBaseAlpha) {
//                float *fsib = (float*)sib.data, *fwib = (float*)wib.data;
//                for (vImagePixelCount p = 0; p < sib.height*sib.width; ++p)
//                    fsib[p] = fmax(fwib[p]-fsib[p], 0);
//                        
//                [bp setClip];
//                CGContextClipToMask(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height), [si CGImageForProposedRect:&bounds context:context hints:nil]);
//                [[color colorWithAlphaComponent:color.alphaComponent*view.annotationsBaseAlpha] set];
//                [bp fill];
//            }
            
        } @catch (NSException* e) {
            [e log];
        } @finally {
            [cimage unlockFocus];
        }
        
        dispatch_semaphore_t s = dispatch_semaphore_create(0);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @synchronized (cmask) {
                dispatch_semaphore_signal(s);
                
                [cmask lockFocus];
                @try {
                    NSGraphicsContext* context = [NSGraphicsContext currentContext];
                    [flip set];
                    
                    CGContextClipToMask(context.CGContext, NSRectToCGRect(bounds), [/*wi*/si CGImageForProposedRect:NULL context:context hints:nil]);
                    [context setCompositingOperation:NSCompositeSourceOver];
                    [[self.class color:self] set];
                    NSRectFill(bounds);
                    
                } @catch (NSException* e) {
                    [e log];
                } @finally {
                    [cmask unlockFocus];
                }
            }
        });
        
        dispatch_semaphore_wait(s, DISPATCH_TIME_FOREVER);
        dispatch_release(s);
    }
    
    NSGraphicsContext* context = [NSGraphicsContext currentContext];
    
    if ([view.selectedAnnotations containsObject:self]) {
        [NSGraphicsContext saveGraphicsState];
        CGContextClipToMask(context.CGContext, NSRectToCGRect(bounds), [csel CGImageForProposedRect:NULL context:context hints:nil]);
        [context setCompositingOperation:NSCompositeSourceOver];
        [[view.selectColor colorWithAlphaComponent:.75] setFill];
        NSRectFill(bounds);
        [NSGraphicsContext restoreGraphicsState];
    }
    
    [NSGraphicsContext saveGraphicsState];

    NSColor* color = self.color;
    if ([view.highlightedAnnotations containsObject:self])
        color = [view.highlightColor colorWithAlphaComponent:color.alphaComponent];
    [color set];
    
    CGContextClipToMask(context.CGContext, NSRectToCGRect(bounds), [cimage CGImageForProposedRect:NULL context:context hints:nil]);
    [context setCompositingOperation:NSCompositeSourceOver];
    NSRectFill(bounds);
    
    [NSGraphicsContext restoreGraphicsState];
}

//- (void)highlightWithColor:(NSColor*)color inView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache layer:(CALayer*)layer context:(CGContextRef)ctx path:(NSBezierPath*)path {
//    NSImage* cmask = cache[NIAnnotationRenderCache][NIAnnotationProjection];
//    
//    [NSGraphicsContext saveGraphicsState];
//    NSGraphicsContext* context = [NSGraphicsContext currentContext];
//    
//    NSRect bounds;
//    @synchronized (cmask) {
//        bounds = NSMakeRect(0, 0, cmask.size.width, cmask.size.height);
//        CGContextClipToMask(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height), [cmask CGImageForProposedRect:&bounds context:context hints:nil]);
//    }
//    
//    [color set];
//    [context setCompositingOperation:NSCompositeSourceOver]; // NSCompositeHighlight
//    CGContextFillRect(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height));
//    
//    [NSGraphicsContext restoreGraphicsState];
//}

- (CGFloat)distanceToSlicePoint:(NSPoint)slicePoint cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view closestPoint:(NSPoint*)rpoint {
    CGFloat distance = NIAnnotationDistant+1;
    
    @autoreleasepool {
        NSImage* cmask = cache[NIAnnotationRenderCache][NIAnnotationProjectionMask];
        
        NSImage* hti = [[[NSImage alloc] initWithSize:NSMakeSize(NIAnnotationDistant*2+1, NIAnnotationDistant*2+1)] autorelease];
        
        for (size_t r = 0; r <= (size_t)NIAnnotationDistant; ++r) {
            [hti lockFocus];
            
            [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(NIAnnotationDistant-r, NIAnnotationDistant-r, r*2+1, r*2+1)] setClip];
            [cmask drawAtPoint:NSMakePoint(NIAnnotationDistant-r, NIAnnotationDistant-r) fromRect:NSMakeRect(slicePoint.x-r, slicePoint.y-r, r*2+1, r*2+1) operation:NSCompositeCopy fraction:1];
            
            [hti unlockFocus];
            
            if ([hti hitTestRect:NSMakeRect(NIAnnotationDistant-r, NIAnnotationDistant-r, r*2+1, r*2+1) withImageDestinationRect:NSMakeRect(0, 0, hti.size.width, hti.size.height) context:nil hints:nil flipped:NO]) {
                distance = r;
                break;
            }
        }
    }
    
    return distance;
}

- (BOOL)intersectsSliceRect:(NSRect)hitRect cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view {
    NSImage* cmask = cache[NIAnnotationRenderCache][NIAnnotationProjectionMask];
    
    return [cmask hitTestRect:hitRect withImageDestinationRect:NSMakeRect(0, 0, cmask.size.width, cmask.size.height) context:nil hints:nil flipped:NO];
}

- (NSSet*)handlesInView:(NIAnnotatedGeneratorRequestView *)view {
    return [NSSet set];
}


@end
