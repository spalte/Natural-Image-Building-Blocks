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

+ (NSSet*)keyPathsForValuesAffectingAnnotation {
    return [[super keyPathsForValuesAffectingAnnotation] setByAddingObject:@"image"];
}

- (instancetype)initWithImage:(NSImage*)image transform:(NIAffineTransform)sliceToDicomTransform {
    if ((self = [super initWithTransform:sliceToDicomTransform])) {
        self.image = image;
    }
    
    return self;
}

- (void)dealloc {
    self.image = nil;
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

- (NSBezierPath*)drawInView:(NIAnnotatedGeneratorRequestView*)view {
    NIAffineTransform sliceToDicomTransform = view.presentedGeneratorRequest.sliceToDicomTransform, dicomToSliceTransform = NIAffineTransformInvert(sliceToDicomTransform);
    
    NIBezierPath* ipath = [self NIBezierPathForSlabView:view complete:YES];
    NIBezierPath* pipath = [[ipath bezierPathByApplyingTransform:sliceToDicomTransform] bezierPathByApplyingTransform:NIAffineTransformInvert(self.planeToDicomTransform)];
    
    [NSGraphicsContext saveGraphicsState];
    
    CGAffineTransform cgat = CATransform3DGetAffineTransform(NIAffineTransformConcat(self.planeToDicomTransform, dicomToSliceTransform));
    NSAffineTransformStruct nsatts = {cgat.a, cgat.b, cgat.c, cgat.d, cgat.tx, cgat.ty};
    NSAffineTransform* nsat = [NSAffineTransform transform];
    nsat.transformStruct = nsatts;
    [nsat set];
    
    if (pipath.elementCount) {
        [pipath.NSBezierPath setClip];
        [self.image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
    }

    if (pipath.elementCount) {
        NSBezierPath* clip = [NSBezierPath bezierPath];
        clip.windingRule = NSEvenOddWindingRule;
        [clip appendBezierPath:self.NSBezierPath];
        [clip appendBezierPath:pipath.NSBezierPath];
        [clip setClip]; }
    [self.image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.2];
    
    [NSGraphicsContext restoreGraphicsState];
    
    return [[self.NIBezierPath bezierPathByApplyingTransform:dicomToSliceTransform] NSBezierPath];
}

- (void)glowInView:(NIAnnotatedGeneratorRequestView*)view path:(NSBezierPath*)path {
    NIAffineTransform dicomToSliceTransform = NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform);

    CGAffineTransform cgat = CATransform3DGetAffineTransform(NIAffineTransformConcat(self.planeToDicomTransform, dicomToSliceTransform));
    NSAffineTransformStruct nsatts = {cgat.a, cgat.b, cgat.c, cgat.d, cgat.tx, cgat.ty};
    NSAffineTransform* nsat = [NSAffineTransform transform];
    nsat.transformStruct = nsatts;

    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext* context = [NSGraphicsContext currentContext];
    
    [nsat set];
    
    NSRect bounds = self.bounds; CGImageRef image = [self.image CGImageForProposedRect:&bounds context:context hints:nil];
    CGContextClipToMask(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height), image);
    
    [[self.color colorWithAlphaComponent:self.color.alphaComponent/3] set];
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

- (CGFloat)distanceToSlicePoint:(NSPoint)slicePoint view:(NIAnnotatedGeneratorRequestView*)view closestPoint:(NSPoint*)closestPoint {
    CGFloat distance = [super distanceToSlicePoint:slicePoint view:view closestPoint:closestPoint];
    
    if (distance > NIAnnotationDistant)
        return distance;
    
    distance = NIAnnotationDistant+1;
    
    @autoreleasepool {
        NIAffineTransform planeToSliceTransform = NIAffineTransformConcat(self.planeToDicomTransform, NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform));
        NSAffineTransform* planeToSlice = [self.class NSAffineTransform:planeToSliceTransform];
        NSAffineTransform* identity = [NSAffineTransform transform];
        
        NSImage* image = [[[NSImage alloc] initWithSize:view.bounds.size] autorelease];
        NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);

        for (size_t r = 0; r <= (size_t)NIAnnotationDistant; ++r) {
            NSRect hitRect = NSMakeRect(slicePoint.x-r, slicePoint.y-r, r*2+1, r*2+1);
            
            [image lockFocus];
            
            [identity set];
            
            // clip to oval centered at point, with the current identity transform
            [[NSBezierPath bezierPathWithOvalInRect:hitRect] setClip];
            
            // draw the image, using the planeToSlice transform
            [planeToSlice set];
            [self.image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeCopy fraction:1];
            
            [image unlockFocus];
            
            if ([image hitTestRect:hitRect withImageDestinationRect:imageRect context:nil hints:nil flipped:NO]) {
                distance = r;
                break;
            }
        }
    }
    
    return distance;
}

- (BOOL)intersectsSliceRect:(NSRect)hitRect view:(NIAnnotatedGeneratorRequestView*)view {
    if (![super intersectsSliceRect:hitRect view:view])
        return NO;
    
    @autoreleasepool {
        NIAffineTransform planeToSliceTransform = NIAffineTransformConcat(self.planeToDicomTransform, NIAffineTransformInvert(view.presentedGeneratorRequest.sliceToDicomTransform));
        NSAffineTransform* planeToSlice = [self.class NSAffineTransform:planeToSliceTransform];
        
        NSImage* image = [[[NSImage alloc] initWithSize:view.bounds.size] autorelease];
        NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);
        
        [image lockFocus];
        
        [[NSBezierPath bezierPathWithRect:hitRect] setClip];
        
        [planeToSlice set];
        [self.image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
        
        [image unlockFocus];
        
        return [image hitTestRect:hitRect withImageDestinationRect:imageRect context:nil hints:nil flipped:NO];
    }

    return NO;
}

@end
