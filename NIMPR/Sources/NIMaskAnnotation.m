//
//  NIMaskAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/13/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMaskAnnotation.h"
#import "NIAnnotationHandle.h"

@implementation NIMaskAnnotation

@synthesize mask = _mask;
@synthesize modelToDicomTransform = _modelToDicomTransform;

+ (NSSet*)keyPathsForValuesAffectingAnnotation {
    return [super.keyPathsForValuesAffectingAnnotation setByAddingObjects: @"mask", @"modelToDicomTransform", nil ];
}

- (id)initWithMask:(NIMask*)mask transform:(NIAffineTransform)modelToDicomTransform {
    if ((self = [super init])) {
        self.mask = mask;
        self.modelToDicomTransform = modelToDicomTransform;
    }
    
    return self;
}

- (void)dealloc {
    self.mask = nil;
    [super dealloc];
}

- (void)translate:(NIVector)translation {
    self.modelToDicomTransform = NIAffineTransformConcat(self.modelToDicomTransform, NIAffineTransformMakeTranslationWithVector(translation));
}

static NSString* const NIMaskAnnotationProjectedRender = @"NIMaskAnnotationProjectedRender";
static NSString* const NIMaskAnnotationProjectedMask = @"NIMaskAnnotationProjectedMask";

- (NSBezierPath*)drawInView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache layer:(CALayer*)layer context:(CGContextRef)ctx {
    NSMutableDictionary* cached = cache[NIAnnotationDrawCache];
    if (!cached) cached = cache[NIAnnotationDrawCache] = [NSMutableDictionary dictionary];
    
    NSImage* cimage = cached[NIMaskAnnotationProjectedRender];
    NSImage* cmask = cached[NIMaskAnnotationProjectedMask];
    if (!cimage) {
        cimage = cached[NIMaskAnnotationProjectedRender] = [[[NSImage alloc] initWithSize:view.bounds.size] autorelease];
        cmask = cached[NIMaskAnnotationProjectedMask] = [[[NSImage alloc] initWithSize:view.bounds.size] autorelease];
        
        NIVolumeData* data = [self.mask volumeDataRepresentationWithVolumeTransform:NIAffineTransformInvert(self.modelToDicomTransform)];
        vImage_Buffer sib, wib;
        NSBitmapImageRep *si, *wi;

        NIObliqueSliceGeneratorRequest* req = [[view.presentedGeneratorRequest copy] autorelease];
        req.interpolationMode = NIInterpolationModeNearestNeighbor;
        
        {
            NIVolumeData* vd = [NIGenerator synchronousRequestVolume:req volumeData:data];
            sib = [vd floatBufferForSliceAtIndex:0];
            unsigned char* bdp[1] = {sib.data};
            si = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:bdp pixelsWide:sib.width pixelsHigh:sib.height bitsPerSample:sizeof(float)*8 samplesPerPixel:1
                                                            hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bitmapFormat:NSFloatingPointSamplesBitmapFormat bytesPerRow:sib.rowBytes bitsPerPixel:sizeof(float)*8] autorelease];
        }
        
        {
            NIVector dc = NIVectorApplyTransform([data convertVolumeVectorToDICOMVector:NIVectorMake(data.pixelsWide/2, data.pixelsHigh/2, data.pixelsDeep/2)], NIAffineTransformInvert(req.sliceToDicomTransform));
            req.sliceToDicomTransform = NIAffineTransformConcat(NIAffineTransformMakeTranslation(0, 0, dc.z), req.sliceToDicomTransform);
            req.slabWidth = data.maximumDiagonal+1;
            req.projectionMode = NIProjectionModeMIP;
            NIVolumeData* vd = [NIGenerator synchronousRequestVolume:req volumeData:data];
            wib = [vd floatBufferForSliceAtIndex:0];
            unsigned char* bdp[1] = {wib.data};
            wi = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:bdp pixelsWide:wib.width pixelsHigh:wib.height bitsPerSample:sizeof(float)*8 samplesPerPixel:1
                                                            hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bitmapFormat:NSFloatingPointSamplesBitmapFormat bytesPerRow:wib.rowBytes bitsPerPixel:sizeof(float)*8] autorelease];
        }

        [cimage lockFocus];
        @try {
            NSGraphicsContext* context = [NSGraphicsContext currentContext];
            [context setCompositingOperation:NSCompositeSourceOver];
            NSRect bounds = NSMakeRect(0, 0, cimage.size.width, cimage.size.height);
            NSBezierPath* bp = [NSBezierPath bezierPathWithRect:bounds];
            // flip
            NSAffineTransform* t = [NSAffineTransform transform];
            [t translateXBy:0 yBy:bounds.size.height];
            [t scaleXBy:1 yBy:-1];
            [t set];
            
            CGContextClipToMask(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height), [si CGImageForProposedRect:&bounds context:context hints:nil]);
            [self.color set];
            [bp fill];

            if (view.annotationsBaseAlpha) {
                float *fsib = (float*)sib.data, *fwib = (float*)wib.data;
                for (vImagePixelCount p = 0; p < sib.height*sib.width; ++p)
                    fsib[p] = fmax(fwib[p]-fsib[p], 0);
                        
                [bp setClip];
                CGContextClipToMask(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height), [si CGImageForProposedRect:&bounds context:context hints:nil]);
                [[self.color colorWithAlphaComponent:self.color.alphaComponent*view.annotationsBaseAlpha] set];
                [bp fill];
            }
            
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
                    NSRect bounds = NSMakeRect(0, 0, cimage.size.width, cimage.size.height);
                    // flip
                    NSAffineTransform* t = [NSAffineTransform transform];
                    [t translateXBy:0 yBy:bounds.size.height];
                    [t scaleXBy:1 yBy:-1];
                    [t set];
                    
                    CGContextClipToMask(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height), [wi CGImageForProposedRect:&bounds context:context hints:nil]);
                    [context setCompositingOperation:NSCompositeSourceOver];
                    [[self.color colorWithAlphaComponent:self.color.alphaComponent*view.annotationsBaseAlpha] set];
                    [[NSBezierPath bezierPathWithRect:bounds] fill];
                    
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
    
    [cimage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
    
    return nil;
}

- (void)highlightWithColor:(NSColor*)color inView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache layer:(CALayer*)layer context:(CGContextRef)ctx path:(NSBezierPath*)path {
    NSMutableDictionary* cached = cache[NIAnnotationDrawCache];
    NSImage* cmask = cached[NIMaskAnnotationProjectedRender];
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext* context = [NSGraphicsContext currentContext];
    
    NSRect bounds;
    @synchronized (cmask) {
        bounds = NSMakeRect(0, 0, cmask.size.width, cmask.size.height);
        CGContextClipToMask(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height), [cmask CGImageForProposedRect:&bounds context:context hints:nil]);
    }
    
    [color set];
    [context setCompositingOperation:NSCompositeSourceOver]; // NSCompositeHighlight
    CGContextFillRect(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height));
    
    [NSGraphicsContext restoreGraphicsState];
}

- (CGFloat)distanceToSlicePoint:(NSPoint)slicePoint cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view closestPoint:(NSPoint*)rpoint {
    CGFloat distance = NIAnnotationDistant+1;
    
    @autoreleasepool {
        NSMutableDictionary* cached = cache[NIAnnotationDrawCache];
        NSImage* image = cached[NIMaskAnnotationProjectedMask];
        
        NSImage* hti = [[NSImage alloc] initWithSize:NSMakeSize(NIAnnotationDistant*2+1, NIAnnotationDistant*2+1)];
        
        for (size_t r = 0; r <= (size_t)NIAnnotationDistant; ++r) {
            [hti lockFocus];
            
            [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(NIAnnotationDistant-r, NIAnnotationDistant-r, r*2+1, r*2+1)] setClip];
            [image drawAtPoint:NSMakePoint(NIAnnotationDistant-r, NIAnnotationDistant-r) fromRect:NSMakeRect(slicePoint.x-r, slicePoint.y-r, r*2+1, r*2+1) operation:NSCompositeCopy fraction:1];
            
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
    NSMutableDictionary* cached = cache[NIAnnotationDrawCache];
    NSImage* image = cached[NIMaskAnnotationProjectedMask];
    
    return [image hitTestRect:hitRect withImageDestinationRect:NSMakeRect(0, 0, image.size.width, image.size.height) context:nil hints:nil flipped:NO];
}

- (NSSet*)handlesInView:(NIAnnotatedGeneratorRequestView *)view {
    NIVolumeData* data = [self.mask volumeDataRepresentationWithVolumeTransform:NIAffineTransformInvert(self.modelToDicomTransform)];
    
    NIVector edges[] = {{0,0,0},{1,1,1},{1,0,0},{0,1,1},{0,1,0},{1,0,1},{1,1,0},{0,0,1}};
    NIVectorApplyTransformToVectors(NIAffineTransformMakeScale(data.pixelsWide*data.pixelSpacingX, data.pixelsHigh*data.pixelSpacingY, data.pixelsDeep*data.pixelSpacingZ), edges, 8);
    NIVectorApplyTransformToVectors(NIAffineTransformConcat(self.modelToDicomTransform, NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform)), edges, 8);
    
    NSMutableSet* set = [NSMutableSet set];
    
    for (size_t i = 0; i < 8; ++i)
        [set addObject:[NIAnnotationBlockHandle handleAtSliceVector:edges[i] block:nil]];
    
    return set;
}


@end
