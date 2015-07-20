//
//  NIMPRAnnotatedGeneratorRequestView.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/8/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotatedGeneratorRequestView.h"
#import "NIAnnotation.h"

@interface NIAnnotatedGeneratorRequestView ()

@property(readwrite, retain) CALayer* annotationsLayer;
@property(retain) NSMutableDictionary* annotationsCaches;

@end

@implementation NIAnnotatedGeneratorRequestView

@synthesize annotationsLayer = _annotationsLayer;
@synthesize annotationsBaseAlpha = _annotationsBaseAlpha;
@synthesize annotationsCaches = _annotationsCaches;

- (void)initialize:(Class)class {
    [super initialize:class];
    
    if (class != NIGeneratorRequestView.class)
        return;
    
    _annotations = [[NSMutableSet alloc] init];
    _glowingAnnotations = [[NSMutableSet alloc] init];
    _annotationsCaches = [[NSMutableDictionary alloc] init];
    
    _annotationsBaseAlpha = .2;
    
    CALayer* layer = self.annotationsLayer = [[[CALayer alloc] init] autorelease];
    layer.delegate = self;
    layer.needsDisplayOnBoundsChange = YES;
    layer.zPosition = NIGeneratorRequestViewRequestLayerZPosition+1;
    layer.contentsScale = self.frameLayer.contentsScale;
    [layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
    [layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
    [layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
    [layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];
    [self.frameLayer addSublayer:layer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdatePresentedGeneratorRequestNotification:)
                                                 name:NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotification object:self];
    
    [self addObserver:self forKeyPath:@"annotations" options:NSKeyValueObservingOptionInitial+NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIAnnotatedGeneratorRequestView.class];
    [self addObserver:self forKeyPath:@"glowingAnnotations" options:NSKeyValueObservingOptionInitial+NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIAnnotatedGeneratorRequestView.class];
}

- (void)dealloc {
    [self observeValueForKeyPath:@"glowingAnnotations" ofObject:self change:@{ NSKeyValueChangeOldKey: self.publicGlowingAnnotations } context:NIAnnotatedGeneratorRequestView.class];
    [self removeObserver:self forKeyPath:@"glowingAnnotations" context:NIAnnotatedGeneratorRequestView.class];
    [self observeValueForKeyPath:@"annotations" ofObject:self change:@{ NSKeyValueChangeOldKey: self.publicAnnotations } context:NIAnnotatedGeneratorRequestView.class];
    [self removeObserver:self forKeyPath:@"annotations" context:NIAnnotatedGeneratorRequestView.class];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotification object:self];

    self.annotationsCaches = nil;
    self.annotationsLayer = nil;
    [_annotations release];
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != NIAnnotatedGeneratorRequestView.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"annotations"]) {
        for (NIAnnotation* a in change[NSKeyValueChangeOldKey]) {
            [a removeObserver:self forKeyPath:@"annotation" context:context];
            [self.annotationsCaches removeObjectForKey:[NSValue valueWithPointer:a]];
        }
        for (NIAnnotation* a in change[NSKeyValueChangeNewKey]) {
            [a addObserver:self forKeyPath:@"annotation" options:NSKeyValueObservingOptionInitial context:context];
            self.annotationsCaches[[NSValue valueWithPointer:a]] = [NSMutableDictionary dictionary];
        }
    }
    
    if ([keyPath isEqualToString:@"annotation"]) {
        [self.annotationsCaches[[NSValue valueWithPointer:object]] removeObjectForKey:NIAnnotationDrawCache];
        [self.annotationsLayer setNeedsDisplay];
    }
    
    if ([keyPath isEqualToString:@"glowingAnnotations"]) {
        [self.annotationsLayer setNeedsDisplay];
    }
}

- (void)didUpdatePresentedGeneratorRequestNotification:(NSNotification*)notification {
    [self.annotationsCaches enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSMutableDictionary* cache, BOOL* stop) {
        [cache removeObjectForKey:NIAnnotationDrawCache];
    }];
    [self.annotationsLayer setNeedsDisplay];
}

- (CGFloat)maximumDistanceToPlane {
    NIObliqueSliceGeneratorRequest* req = (id)self.presentedGeneratorRequest;
    return CGFloatMax((req.pixelSpacingX+req.pixelSpacingY+req.pixelSpacingZ)/3, CGFLOAT_EPSILON);
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if (layer == self.annotationsLayer) {
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO]];
        
        NSMutableArray* abs = [NSMutableArray array]; // @[ annotation, border ]
        
        for (NIAnnotation* a in self.publicAnnotations) {
            NSMutableDictionary* cache = self.annotationsCaches[[NSValue valueWithPointer:a]];
            NSBezierPath* border = [a drawInView:self cache:cache layer:layer context:ctx];
            if ([self.publicGlowingAnnotations containsObject:a])
                [abs addObject:@[ a, cache, [NSNull either:border] ]];
        }
        
        for (NSArray* ab in abs)
            [ab[0] glowInView:self cache:ab[1] layer:layer context:ctx path:[ab[2] if:NSBezierPath.class]];
        
        [NSGraphicsContext restoreGraphicsState];
    }
    
    [super drawLayer:layer inContext:ctx];
}

- (NSMutableSet*)publicAnnotations {
    return [self mutableSetValueForKey:@"annotations"];
}

- (void)addAnnotationsObject:(id)object {
    [_annotations addObject:object];
}

- (void)removeAnnotationsObject:(id)object {
    [_annotations removeObject:object];
}

- (NSMutableSet*)publicGlowingAnnotations {
    return [self mutableSetValueForKey:@"glowingAnnotations"];
}

- (void)addGlowingAnnotationsObject:(id)object {
    [_glowingAnnotations addObject:object];
}

- (void)removeGlowingAnnotationsObject:(id)object {
    [_glowingAnnotations removeObject:object];
}

- (NIAnnotation*)annotationClosestToSlicePoint:(NSPoint)location closestPoint:(NSPoint*)closestPoint distance:(CGFloat*)distance {
    return [self annotationClosestToSlicePoint:location closestPoint:closestPoint distance:distance filter:nil];
}

- (NIAnnotation*)annotationClosestToSlicePoint:(NSPoint)location closestPoint:(NSPoint*)closestPoint distance:(CGFloat*)distance filter:(BOOL (^)(NIAnnotation*))filter {
    NSMutableArray* adps = [NSMutableArray array]; // @[ annotation, distance ]
    
    for (NIAnnotation* a in self.publicAnnotations)
        if (!filter || filter(a)) {
            NSPoint closestPoint;
            CGFloat distance = [a distanceToSlicePoint:location cache:self.annotationsCaches[[NSValue valueWithPointer:a]] view:self closestPoint:&closestPoint];
            [adps addObject:@[ a, [NSNumber valueWithCGFloat:distance], [NSValue valueWithPoint:closestPoint] ]];
        }
    
    [adps sortUsingComparator:^NSComparisonResult(NSArray* ad1, NSArray* ad2) {
        if ([ad1[1] floatValue] > [ad2[1] floatValue])
            return NSOrderedDescending;
        if ([ad1[1] floatValue] < [ad2[1] floatValue])
            return NSOrderedAscending;
        return NSOrderedSame;
    }];
    
    if (adps.count) {
        NSArray* adp = adps[0];
        if (closestPoint) *closestPoint = [adp[2] pointValue];
        if (distance) *distance = [adp[1] CGFloatValue];
        return adp[0];
    }
    
    return nil;
}

- (NSSet*)annotationsIntersectingWithSliceRect:(NSRect)sliceRect {
    NSMutableSet* rset = [NSMutableSet set];
    
    for (NIAnnotation* a in self.publicAnnotations)
        if ([a intersectsSliceRect:sliceRect cache:self.annotationsCaches[[NSValue valueWithPointer:a]] view:self])
            [rset addObject:a];
    
    return rset;
}

@end

