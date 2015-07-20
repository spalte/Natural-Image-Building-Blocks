//
//  NIImageAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/13/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIImageAnnotation.h"

typedef struct {
    CGFloat x, y, z, u, v;
} NIImageVertex;

@implementation NIImageAnnotation

@synthesize image = _image;
@synthesize colorify = _colorify;

+ (NSSet*)keyPathsForValuesAffectingAnnotation {
    return [[super keyPathsForValuesAffectingAnnotation] setByAddingObjectsFromArray:@[ @"image", @"colorify" ]];
}

- (instancetype)initWithImage:(NSImage*)image transform:(NIAffineTransform)sliceToDicomTransform {
    if ((self = [super initWithTransform:sliceToDicomTransform])) {
        self.image = image;
    }
    
    return self;
}

- (void)dealloc {
    [_image release]; _image = nil;
    [super dealloc];
}

- (NSRect)bounds {
    return NSMakeRect(0, 0, self.image.size.width, self.image.size.height);
}

- (void)setBounds:(NSRect)bounds {
    assert(NO); // TODO: implement me
}

- (BOOL)isSolid {
    return YES;
}

static NSString* const NIImageAnnotationImage = @"NIImageAnnotationImage";

- (NSBezierPath*)drawInView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache layer:(CALayer*)layer context:(CGContextRef)ctx {
    NSMutableDictionary* cached = cache[NIAnnotationDrawCache];
    if (!cached) cached = cache[NIAnnotationDrawCache] = [NSMutableDictionary dictionary];
    
    NSImage* image = cached[NIImageAnnotationImage];
    if (!image) {
        image = cached[NIImageAnnotationImage] = [[[NSImage alloc] initWithSize:view.bounds.size] autorelease];

        [image lockFocus];
        @try {
            NSGraphicsContext* context = [NSGraphicsContext currentContext];
            CGContextRef ctx = [context CGContext];
            
            NIAffineTransform sliceToDicomTransform = view.presentedGeneratorRequest.sliceToDicomTransform, dicomToSliceTransform = NIAffineTransformInvert(sliceToDicomTransform);
            
            NIBezierPath* ipath = [self NIBezierPathForSlabView:view complete:YES];
            NIBezierPath* pipath = [[ipath bezierPathByApplyingTransform:sliceToDicomTransform] bezierPathByApplyingTransform:NIAffineTransformInvert(self.planeToDicomTransform)];

            CGAffineTransform cgat = CATransform3DGetAffineTransform(NIAffineTransformConcat(self.planeToDicomTransform, dicomToSliceTransform));
            NSAffineTransformStruct nsatts = {cgat.a, cgat.b, cgat.c, cgat.d, cgat.tx, cgat.ty};
            NSAffineTransform* nsat = [NSAffineTransform transform];
            nsat.transformStruct = nsatts;
            [nsat set];
            
            if (pipath.elementCount) {
                [pipath.NSBezierPath setClip];
                
                if (!self.colorify)
                    [self.image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:self.color.alphaComponent];
                else {
                    NSRect bounds = self.bounds; CGImageRef image = [self.image CGImageForProposedRect:&bounds context:context hints:nil];
                    CGContextClipToMask(ctx, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height), image);
                    [self.color set];
                    CGContextFillRect(ctx, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height));
                }
                
                NSBezierPath* clip = [NSBezierPath bezierPath];
                clip.windingRule = NSEvenOddWindingRule;
                [clip appendBezierPath:self.NSBezierPath];
                [clip appendBezierPath:pipath.NSBezierPath];
                [clip setClip];
            }
            
            if (!self.colorify)
                [self.image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:self.color.alphaComponent*view.annotationsBaseAlpha];
            else {
                [[self.color colorWithAlphaComponent:self.color.alphaComponent*view.annotationsBaseAlpha] set];
                NSRect bounds = self.bounds; CGImageRef image = [self.image CGImageForProposedRect:&bounds context:context hints:nil];
                CGContextClipToMask(ctx, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height), image);
                CGContextFillRect(ctx, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height));
            }
        } @catch (NSException* e) {
            [e log];
        } @finally {
            [image unlockFocus];
        }
    }
    
    [NSGraphicsContext saveGraphicsState];
    [[NSAffineTransform transform] set];
    
    [image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];

    [NSGraphicsContext restoreGraphicsState];

    return nil;
}

- (void)glowInView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache layer:(CALayer*)layer context:(CGContextRef)ctx path:(NSBezierPath*)path {
    NSMutableDictionary* cached = cache[NIAnnotationDrawCache];
    NSImage* image = cached[NIImageAnnotationImage];

    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext* context = [NSGraphicsContext currentContext];
    
    NSRect bounds = NSMakeRect(0, 0, image.size.width, image.size.height);
    CGContextClipToMask(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height), [image CGImageForProposedRect:&bounds context:context hints:nil]);
    
    [[self.color colorWithAlphaComponent:self.color.alphaComponent*.75] set];
    CGContextFillRect(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height));

    [NSGraphicsContext restoreGraphicsState];
}

+ (NSAffineTransform*)NSAffineTransform:(NIAffineTransform)ni {
    CGAffineTransform cg = CATransform3DGetAffineTransform(ni);
    NSAffineTransformStruct transformStruct = {cg.a, cg.b, cg.c, cg.d, cg.tx, cg.ty};
    NSAffineTransform* transform = [NSAffineTransform transform];
    transform.transformStruct = transformStruct;
    return transform;
}

- (CGFloat)distanceToSlicePoint:(NSPoint)slicePoint cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view closestPoint:(NSPoint*)closestPoint {
    CGFloat distance = [super distanceToSlicePoint:slicePoint cache:cache view:view closestPoint:closestPoint];
    
    if (distance > NIAnnotationDistant)
        return distance;
    
    distance = NIAnnotationDistant+1;
    
    @autoreleasepool {
        NSMutableDictionary* cached = cache[NIAnnotationDrawCache];
        NSImage* image = cached[NIImageAnnotationImage];

        NSImage* hti = [[NSImage alloc] initWithSize:NSMakeSize(NIAnnotationDistant*2+1, NIAnnotationDistant*2+1)];

        for (size_t r = 0; r <= (size_t)NIAnnotationDistant; ++r) {
            [hti lockFocus];

            [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(NIAnnotationDistant-r, NIAnnotationDistant-r, r*2+1, r*2+1)] setClip];
            [image drawAtPoint:NSMakePoint(NIAnnotationDistant-r, NIAnnotationDistant-r) fromRect:NSMakeRect(slicePoint.x-r, slicePoint.y-r, r*2+1, r*2+1) operation:NSCompositeCopy fraction:1];
            
            [hti unlockFocus];
            
            [hti.TIFFRepresentation writeToFile:@"/Users/ale/Desktop/TEST.tif" atomically:YES];
            
            if ([hti hitTestRect:NSMakeRect(NIAnnotationDistant-r, NIAnnotationDistant-r, r*2+1, r*2+1) withImageDestinationRect:NSMakeRect(0, 0, hti.size.width, hti.size.height) context:nil hints:nil flipped:NO]) {
                distance = r;
                break;
            }
        }
    }
    
    return distance;
}

- (BOOL)intersectsSliceRect:(NSRect)hitRect cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view {
    if (![super intersectsSliceRect:hitRect cache:cache view:view])
        return NO;
    
    NSMutableDictionary* cached = cache[NIAnnotationDrawCache];
    NSImage* image = cached[NIImageAnnotationImage];
    
    return [image hitTestRect:hitRect withImageDestinationRect:NSMakeRect(0, 0, image.size.width, image.size.height) context:nil hints:nil flipped:NO];
}

@end
