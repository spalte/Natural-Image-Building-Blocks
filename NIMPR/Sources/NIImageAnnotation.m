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

- (void)drawInView:(NIAnnotatedGeneratorRequestView*)view {
    NIObliqueSliceGeneratorRequest* req = (id)view.presentedGeneratorRequest;
    NIAffineTransform dicomToSliceTransform = NIAffineTransformInvert(req.sliceToDicomTransform);
    
    NIBezierPath *epath, *ipath = [self NIBezierPathForSlabView:view external:&epath complete:YES];
    NIAffineTransform dicomToPlaneTransform = NIAffineTransformInvert(self.planeToDicomTransform);
    NIBezierPath* pipath = [[ipath bezierPathByApplyingTransform:req.sliceToDicomTransform] bezierPathByApplyingTransform:dicomToPlaneTransform];
//    NIBezierPath* pepath = [[epath bezierPathByApplyingTransform:req.sliceToDicomTransform] bezierPathByApplyingTransform:dicomToPlaneTransform];
    
//    [self.color set];
//    [path.NSBezierPath stroke];
    
    [NSGraphicsContext saveGraphicsState];
    
    CGAffineTransform cgat = CATransform3DGetAffineTransform(NIAffineTransformConcat(self.planeToDicomTransform, dicomToSliceTransform));
    NSAffineTransformStruct nsatts = {cgat.a, cgat.b, cgat.c, cgat.d, cgat.tx, cgat.ty};
    NSAffineTransform* nsat = [NSAffineTransform transform];
    nsat.transformStruct = nsatts;
    [nsat concat];
    
    [pipath.NSBezierPath setClip];
    [self.image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeCopy fraction:1];
    
    NSBezierPath* clip = [NSBezierPath bezierPath];
    clip.windingRule = NSEvenOddWindingRule;
    [clip appendBezierPath:self.NSBezierPath];
    [clip appendBezierPath:pipath.NSBezierPath];
    
    [clip setClip];
    [self.image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeCopy fraction:0.2];
    
    [NSGraphicsContext restoreGraphicsState];
    
//    [self.color set];
//    [ipath.NSBezierPath stroke];
//    [[self.color colorWithAlphaComponent:self.color.alphaComponent*.2] set];
//    [ipath.NSBezierPath fill];
}



@end
