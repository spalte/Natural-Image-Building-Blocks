//
//  NIImageAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/13/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIImageAnnotation.h"
#import <Quartz/Quartz.h>

typedef struct {
    CGFloat x, y, z, u, v;
} NIImageVertex;

@implementation NIImageAnnotation

@synthesize data = _data;
@synthesize image = _image;
@synthesize colorify = _colorify;

+ (NSSet*)keyPathsForValuesAffectingAnnotation {
    return [[super keyPathsForValuesAffectingAnnotation] setByAddingObjects: @"image", @"colorify", nil];
}

//- (instancetype)initWithImage:(NSImage*)image transform:(NIAffineTransform)sliceToDicomTransform __deprecated {
//    if ((self = [super initWithTransform:sliceToDicomTransform])) {
//        self.image = image;
//        self.bounds = NSMakeRect(0, 0, image.size.width, image.size.height);
//    }
//    
//    return self;
//}

- (instancetype)init {
    if ((self = [super init])) {
        [self addObserver:self forKeyPath:@"data" options:NSKeyValueObservingOptionNew context:NIImageAnnotation.class];
    }
    
    return self;
}

- (instancetype)initWithData:(NSData*)data {
    return [self initWithData:data transform:NIAffineTransformIdentity];
}

- (instancetype)initWithData:(NSData*)data transform:(NIAffineTransform)modelToDicomTransform {
    if ((self = [self init])) {
        self.data = data;
        self.modelToDicomTransform = modelToDicomTransform;
        self.bounds = NSMakeRect(0, 0, self.image.size.width, self.image.size.height);
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    if ((self = [super initWithCoder:coder])) {
        self.data = [coder decodeObjectForKey:@"data"];
        self.colorify = [coder decodeBoolForKey:@"colorify"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.data forKey:@"data"];
    [coder encodeBool:self.colorify forKey:@"colorify"];
}

- (void)dealloc {
    self.data = nil;
    [self removeObserver:self forKeyPath:@"data" context:NIImageAnnotation.class];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != NIImageAnnotation.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"data"]) {
        if ([change[NSKeyValueChangeNewKey] isKindOfClass:NSData.class])
            self.image = [[[NSImage alloc] initWithData:change[NSKeyValueChangeNewKey]] autorelease];
        else self.image = nil;
    }
}

+ (NSSet*)keyPathsForValuesAffectingImage {
    return [NSSet setWithObject:@"data"];
}

- (BOOL)isSolid {
    return YES;
}

- (void)drawInView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache {
    NSMutableDictionary* rcache = cache[NIAnnotationRenderCache];
    NSImage* cimage = rcache[NIAnnotationProjection];
    NSImage* cmask = rcache[NIAnnotationProjectionMask];

    if (!cimage) {
        cimage = rcache[NIAnnotationProjection] = [[[NSImage alloc] initWithSize:view.bounds.size] autorelease];
        cmask = rcache[NIAnnotationProjectionMask] = [[[NSImage alloc] initWithSize:view.bounds.size] autorelease];

        NIAffineTransform sliceToDicomTransform = view.presentedGeneratorRequest.sliceToDicomTransform, dicomToSliceTransform = NIAffineTransformInvert(sliceToDicomTransform);
        
        NIBezierPath* ipath = [self NIBezierPathForSlabView:view complete:YES];
        NIBezierPath* pipath = [[ipath bezierPathByApplyingTransform:sliceToDicomTransform] bezierPathByApplyingTransform:NIAffineTransformInvert(self.modelToDicomTransform)];
        
        NSAffineTransform* nsat = [NSAffineTransform transformWithNIAffineTransform:NIAffineTransformConcat(self.modelToDicomTransform, dicomToSliceTransform)];
        
        NSImageRep* irep = [[self.image.representations.lastObject copy] autorelease];

        [cimage lockFocus];
        @try {
            [nsat set];
            
            if (pipath.elementCount) {
                [pipath.NSBezierPath setClip];
                
                [irep drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeCopy fraction:1 respectFlipped:YES hints:nil];
                
                // invert clip
                NSBezierPath* clip = [NSBezierPath bezierPath];
                clip.windingRule = NSEvenOddWindingRule;
                [clip appendBezierPath:self.NSBezierPath];
                [clip appendBezierPath:pipath.NSBezierPath];
                [clip setClip];
            }
            
            if (view.annotationsBaseAlpha)
                [irep drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeCopy fraction:view.annotationsBaseAlpha respectFlipped:YES hints:nil];
            
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
                    [nsat set];
                    
                    [irep drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeCopy fraction:1 respectFlipped:YES hints:nil];
                    
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
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext* context = [NSGraphicsContext currentContext];
    [[NSAffineTransform transform] set];
    
    BOOL highlight = [view.highlightedAnnotations containsObject:self];
    NSColor* color = [self.class color:self];
    if (!self.colorify && !highlight)
        [cimage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:color.alphaComponent];
    else {
        if (highlight)
            color = [view.highlightColor colorWithAlphaComponent:color.alphaComponent];
        [color set];

        NSRect bounds = NSMakeRect(0, 0, cimage.size.width, cimage.size.height);
        CGContextClipToMask(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height), [cimage CGImageForProposedRect:&bounds context:context hints:nil]);
        [context setCompositingOperation:NSCompositeSourceOver];
        CGContextFillRect(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height));
    }

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

- (CGFloat)distanceToSlicePoint:(NSPoint)slicePoint cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view closestPoint:(NSPoint*)closestPoint {
    CGFloat distance = [super distanceToSlicePoint:slicePoint cache:cache view:view closestPoint:closestPoint];
    
    if (distance > NIAnnotationDistant)
        return distance;
    
    distance = NIAnnotationDistant+1;
    
    @autoreleasepool {
        NSImage* cimage = cache[NIAnnotationRenderCache][NIAnnotationProjectionMask];

        NSImage* hti = [[[NSImage alloc] initWithSize:NSMakeSize(NIAnnotationDistant*2+1, NIAnnotationDistant*2+1)] autorelease];

        for (size_t r = 0; r <= (size_t)NIAnnotationDistant; ++r) {
            [hti lockFocus];

            [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(NIAnnotationDistant-r, NIAnnotationDistant-r, r*2+1, r*2+1)] setClip];
            [cimage drawAtPoint:NSMakePoint(NIAnnotationDistant-r, NIAnnotationDistant-r) fromRect:NSMakeRect(slicePoint.x-r, slicePoint.y-r, r*2+1, r*2+1) operation:NSCompositeCopy fraction:1];
            
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
//    if (![super intersectsSliceRect:hitRect cache:cache view:view])
//        return NO;
    
    NSImage* cimage = cache[NIAnnotationRenderCache][NIAnnotationProjectionMask];
    
    return [cimage hitTestRect:hitRect withImageDestinationRect:NSMakeRect(0, 0, cimage.size.width, cimage.size.height) context:nil hints:nil flipped:NO];
}

@end
