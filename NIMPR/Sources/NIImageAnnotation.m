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

- (instancetype)initWithBounds:(NSRect)bounds image:(NSImage*)image transform:(NIAffineTransform)sliceToDicomTransform {
    if ((self = [super initWithBounds:bounds transform:sliceToDicomTransform])) {
        self.image = image;
    }
    
    return self;
}

- (void)dealloc {
    self.image = nil;
    [super dealloc];
}

- (void)drawInView:(NIAnnotatedGeneratorRequestView*)view {
    NIObliqueSliceGeneratorRequest* req = (id)view.presentedGeneratorRequest;
    NIAffineTransform dicomToSliceTransform = NIAffineTransformInvert(req.sliceToDicomTransform);
    
    NIBezierPath* path = [self.NIBezierPath bezierPathByApplyingTransform:dicomToSliceTransform];
    
    NSInteger elementCount = path.elementCount;
    NIVector c1, c2, ep, ip, bp; BOOL ipset = NO, bpin = NO;
    NIVector ps[elementCount];
    size_t psi = 0;
    for (NSInteger i = 0; i < elementCount; ++i)
        switch ([path elementAtIndex:i control1:&c1 control2:&c2 endpoint:&ep]) {
            case NSMoveToBezierPathElement: {
                ip = bp = ep; bpin = NO; ipset = YES;
            } break;
            case NSLineToBezierPathElement: {
                if (!bpin)
                    ps[psi++] = bp;
                bp = ps[psi++] = ep;
                bpin = YES;
            } break;
            case NSCurveToBezierPathElement: {
                assert(NO); // curves in rectangles??
            } break;
            case NSClosePathBezierPathElement: {
                assert(ipset);
                if (!bpin)
                    ps[psi++] = bp;
                bp = ps[psi++] = ip;
                bpin = YES;
            } break;
        }
    if (psi > 1 && NIVectorEqualToVector(ps[0], ps[psi-1]))
        --psi;
    
    [[self.color colorWithAlphaComponent:0.2] set];
    
    assert(psi == 4);
    [self.class map:self.image points:ps];
}

+ (void)map:(NSImage*)image points:(NIVector*)ps {
    NIImageVertex ips[4] = {
        {ps[0].x, ps[0].y, ps[0].z, 0, 0},
        {ps[1].x, ps[1].y, ps[1].z, image.size.width, 0},
        {ps[2].x, ps[2].y, ps[2].z, image.size.width, image.size.height},
        {ps[3].x, ps[3].y, ps[3].z, 0, image.size.height}
    };
    
    const size_t fc = 2, vc = 3;
    size_t facet[fc][vc] = {{0,1,2},{0,2,3}};
    
    for (size_t f = 0; f < fc; ++f) {
        NIImageVertex fps[vc];
        for (size_t v = 0; v < vc; ++v)
            fps[v] = ips[facet[f][v]];
        [self map:image vertices:fps];
    }
}

static NIImageVertex NIImageVectorInterpolate(NIImageVertex a, NIImageVertex b, CGFloat p) {
    NIImageVertex r = {a.x*(1.-p)+b.x*p, a.y*(1.-p)+b.y*p, a.u*(1.-p)+b.u*p, a.v*(1.-p)+b.v*p};
    return r;
}

+ (void)map:(NSImage*)image vertices:(NIImageVertex*)fps {
//    NSBezierPath* p = [NSBezierPath bezierPath]; [p moveToPoint:to[0]]; [p lineToPoint:to[1]];
//    [p stroke];
//    p = [NSBezierPath bezierPath]; [p moveToPoint:to[0]]; [p lineToPoint:to[2]];
//    [p stroke];
//    p = [NSBezierPath bezierPath]; [p moveToPoint:to[1]]; [p lineToPoint:to[2]];
//    [p stroke];
    
    // sort points vertically
    for (size_t i = 0; i < 2; ++i)
        for (size_t j = i+1; j < 3; ++j)
            if (fps[j].y < fps[i].y) {
                NIImageVertex swap = fps[j]; fps[j] = fps[i]; fps[i] = swap;
            }
    
    CGFloat dy = fps[2].y - fps[0].y;
    
    if (dy == 0) { // segment
        // sort points horizontally
        for (size_t i = 0; i < 2; ++i)
            for (size_t j = i+1; j < 3; ++j)
                if (fps[j].x < fps[i].x) {
                    NIImageVertex swap = fps[j]; fps[j] = fps[i]; fps[i] = swap;
                }
        [self mapH:image vertices:fps[0]:fps[2]]; // fps[1] is between fps[0] and fps[2]
    } if (fps[0].y == fps[1].y) { // type A
        [self mapA:image vertices:fps[0]:fps[1]:fps[2] y:(NSInteger)fps[0].y:(NSInteger)fps[2].y];
    } else if (fps[1].y == fps[2].y) { // type B
        [self mapB:image vertices:fps[0]:fps[1]:fps[2] y:(NSInteger)fps[0].y:(NSInteger)fps[2].y];
    } else { // type C
        // split into 2 triangles, one type A and one type B
        NIImageVertex fps3 = NIImageVectorInterpolate(fps[0], fps[2], (fps[1].y-fps[0].y)/(fps[2].y-fps[0].y));
        fps3.y = fps[1].y;
        [self mapB:image vertices:fps[0]:fps[1]:fps3 y:(NSInteger)fps[0].y:(NSInteger)fps[1].y];
        [self mapA:image vertices:fps[1]:fps3:fps[2] y:(NSInteger)fps[1].y+1:(NSInteger)fps[2].y];
    }
}

+ (void)mapA:(NSImage*)image vertices:(NIImageVertex)a :(NIImageVertex)b :(NIImageVertex)c y:(NSInteger)ymin :(NSInteger)ymax {
    for (NSInteger y = ymin; y <= ymax; ++y) {
        CGFloat p = (y-a.y)/(c.y-a.y);
        NIImageVertex pa = NIImageVectorInterpolate(a, c, p), pb = NIImageVectorInterpolate(b, c, p);
        pa.y = pb.y = y;
        pa.x = (NSInteger)pa.x;
        pb.x = (NSInteger)pb.x;
        [self mapH:image vertices:pa:pb];
    }
}

+ (void)mapB:(NSImage*)image vertices:(NIImageVertex)a :(NIImageVertex)b :(NIImageVertex)c y:(NSInteger)ymin :(NSInteger)ymax {
    for (NSInteger y = ymin; y <= ymax; ++y) {
        CGFloat p = (y-a.y)/(c.y-a.y);
        NIImageVertex pa = NIImageVectorInterpolate(a, b, p), pb = NIImageVectorInterpolate(a, c, p);
        pa.y = pb.y = y;
        pa.x = (NSInteger)pa.x;
        pb.x = (NSInteger)pb.x;
        [self mapH:image vertices:pa:pb];
    }
}

+ (void)mapH:(NSImage*)image vertices:(NIImageVertex)a :(NIImageVertex)b {
    if (a.x == b.x) { // point
        if (a.z < b.z)
            [self map:image vertex:a];
        else [self map:image vertex:b];
    } else {
        // sort horizontally
        if (b.x < a.x) {
            NIImageVertex swap = a; a = b; b = swap;
        }
        
        for (NSInteger x = (NSInteger)a.x; x <= (NSInteger)b.x; ++x) {
            NIImageVertex pa = NIImageVectorInterpolate(a, b, ((CGFloat)x-a.x)/(b.x-a.x));
            pa.x = x; pa.y = a.y;
            [self map:image vertex:pa];
        }
    }
}

+ (void)map:(NSImage*)image vertex:(NIImageVertex)p {
//    [image.representations.lastObject ];
    [NSBezierPath fillRect:NSMakeRect(p.x, p.y, 1, 1)];
}

@end
