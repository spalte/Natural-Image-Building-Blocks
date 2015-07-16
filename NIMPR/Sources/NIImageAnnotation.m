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
    NIObliqueSliceGeneratorRequest* req = view.presentedGeneratorRequest;
    NIAffineTransform dicomToSliceTransform = NIAffineTransformInvert(req.sliceToDicomTransform);
    
    NIBezierPath *ipath = [self NIBezierPathForSlabView:view complete:YES];
    NIAffineTransform dicomToPlaneTransform = NIAffineTransformInvert(self.planeToDicomTransform);
    NIBezierPath* pipath = [[ipath bezierPathByApplyingTransform:req.sliceToDicomTransform] bezierPathByApplyingTransform:dicomToPlaneTransform];
    
//    [self.color set];
//    [path.NSBezierPath stroke];
    
    [NSGraphicsContext saveGraphicsState];
    
    CGAffineTransform cgat = CATransform3DGetAffineTransform(NIAffineTransformConcat(self.planeToDicomTransform, dicomToSliceTransform));
    NSAffineTransformStruct nsatts = {cgat.a, cgat.b, cgat.c, cgat.d, cgat.tx, cgat.ty};
    NSAffineTransform* nsat = [NSAffineTransform transform];
    nsat.transformStruct = nsatts;
    [nsat set];
    
    if (pipath.elementCount) {
        [pipath.NSBezierPath setClip];
        [self.image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeCopy fraction:1];
    }

    if (pipath.elementCount) {
        NSBezierPath* clip = [NSBezierPath bezierPath];
        clip.windingRule = NSEvenOddWindingRule;
        [clip appendBezierPath:self.NSBezierPath];
        [clip appendBezierPath:pipath.NSBezierPath];
        [clip setClip]; }
    [self.image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeCopy fraction:0.2];
    
    [NSGraphicsContext restoreGraphicsState];
    
    return [[self.NIBezierPath bezierPathByApplyingTransform:dicomToSliceTransform] NSBezierPath];
}

- (CGFloat)distanceToPoint:(NSPoint)point view:(NIAnnotatedGeneratorRequestView*)view closestPoint:(NSPoint*)closestPoint {
    CGFloat distance = [super distanceToPoint:point view:view closestPoint:closestPoint];
    
    if (distance > NIAnnotationDistant)
        return distance;
    
    distance = NIAnnotationDistant+1;
    
    NIAffineTransform sliceToPlaneTransform = NIAffineTransformConcat(view.presentedGeneratorRequest.sliceToDicomTransform, NIAffineTransformInvert(self.planeToDicomTransform));
    
    NIVector vector = NIVectorApplyTransform(NIVectorMakeFromNSPoint(point), sliceToPlaneTransform), v2 = NIVectorApplyTransform(NIVectorMake(point.x+NIAnnotationDistant, point.y, 0), sliceToPlaneTransform);
    
    [NSGraphicsContext saveGraphicsState];
    NSPrintOperation* op = [NSPrintOperation printOperationWithView:view];
    NSGraphicsContext* context = [op createContext];
    [NSGraphicsContext setCurrentContext:context];
    
    CGFloat rmax = NIVectorDistance(NIVectorZeroZ(vector), NIVectorZeroZ(v2));
    for (size_t r = 0; r <= (size_t)rmax; ++r)
        if ([self.image hitTestRect:NSMakeRect(vector.x-r, vector.y-r, r*2+1, r*2+1) withImageDestinationRect:self.bounds context:nil hints:nil flipped:NO]) {
            distance = 1.*r/rmax*NIAnnotationDistant;
            break;
        }
    
    [NSGraphicsContext restoreGraphicsState];
    
    return distance;
}




@end
