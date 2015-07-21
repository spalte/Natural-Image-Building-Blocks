//
//  NIMPRAnnotatedGeneratorRequestView.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/8/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotatedGeneratorRequestView.h"
#import "NIAnnotation.h"
#import "NIAnnotationHandle.h"

@interface NIAnnotatedGeneratorRequestView ()

@property(readwrite, retain) CALayer* annotationsLayer;
@property(retain) NSMutableDictionary* annotationsCaches;

@end

@implementation NIAnnotatedGeneratorRequestView

@synthesize annotationsLayer = _annotationsLayer;
@synthesize annotationsBaseAlpha = _annotationsBaseAlpha;
@synthesize annotationsCaches = _annotationsCaches;

@synthesize annotations = _annotations;
@synthesize highlightedAnnotations = _highlightedAnnotations;
@synthesize selectedAnnotations = _selectedAnnotations;

- (void)initialize:(Class)class {
    [super initialize:class];
    
    if (class != NIGeneratorRequestView.class)
        return;
    
    _annotations = [[NSMutableSet alloc] init];
    _highlightedAnnotations = [[NSMutableSet alloc] init];
    _selectedAnnotations = [[NSMutableSet alloc] init];
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
    [self addObserver:self forKeyPath:@"highlightedAnnotations" options:NSKeyValueObservingOptionInitial+NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIAnnotatedGeneratorRequestView.class];
    [self addObserver:self forKeyPath:@"selectedAnnotations" options:NSKeyValueObservingOptionInitial+NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIAnnotatedGeneratorRequestView.class];
}

- (void)dealloc {
    [self observeValueForKeyPath:@"selectedAnnotations" ofObject:self change:@{ NSKeyValueChangeOldKey: self.mutableSelectedAnnotations } context:NIAnnotatedGeneratorRequestView.class];
    [self removeObserver:self forKeyPath:@"selectedAnnotations" context:NIAnnotatedGeneratorRequestView.class];
    [self observeValueForKeyPath:@"highlightedAnnotations" ofObject:self change:@{ NSKeyValueChangeOldKey: self.mutableHighlightedAnnotations } context:NIAnnotatedGeneratorRequestView.class];
    [self removeObserver:self forKeyPath:@"highlightedAnnotations" context:NIAnnotatedGeneratorRequestView.class];
    [self observeValueForKeyPath:@"annotations" ofObject:self change:@{ NSKeyValueChangeOldKey: self.mutableAnnotations } context:NIAnnotatedGeneratorRequestView.class];
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
        [self.mutableSelectedAnnotations minusSet:change[NSKeyValueChangeOldKey]];
        [self.mutableHighlightedAnnotations minusSet:change[NSKeyValueChangeOldKey]];
        for (NIAnnotation* a in change[NSKeyValueChangeOldKey]) {
            [a removeObserver:self forKeyPath:@"annotation" context:context];
            [self.annotationsCaches removeObjectForKey:[NSValue valueWithPointer:a]];
        }
        for (NIAnnotation* a in change[NSKeyValueChangeNewKey]) {
            [a addObserver:self forKeyPath:@"annotation" options:NSKeyValueObservingOptionInitial context:context];
            self.annotationsCaches[[NSValue valueWithPointer:a]] = [NSMutableDictionary dictionary];
        }
    }
    
    if ([keyPath isEqualToString:@"highlightedAnnotations"] || [keyPath isEqualToString:@"selectedAnnotations"]) {
        [self.annotationsLayer setNeedsDisplay];
    }
    
    if ([keyPath isEqualToString:@"annotation"]) {
        [self.annotationsCaches[[NSValue valueWithPointer:object]] removeObjectForKey:NIAnnotationDrawCache];
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

+ (NSBezierPath*)NSBezierPathForHandle:(NIAnnotationHandle*)handle {
    NSPoint p = handle.slicePoint;
    return [NSBezierPath bezierPathWithRect:NSMakeRect(p.x-NIAnnotationHandleSize/2, p.y-NIAnnotationHandleSize/2, NIAnnotationHandleSize, NIAnnotationHandleSize)];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if (layer == self.annotationsLayer) {
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO]];
        
        NSMutableArray* selected_acbs = [NSMutableArray array]; // @[ annotation, cache, border ]
        NSMutableArray* glowing_acbs = [NSMutableArray array]; // @[ annotation, cache, border ]
        
        for (NIAnnotation* a in self.mutableAnnotations) {
            NSMutableDictionary* cache = self.annotationsCaches[[NSValue valueWithPointer:a]];
            NSBezierPath* border = [a drawInView:self cache:cache layer:layer context:ctx];
            if ([self.selectedAnnotations containsObject:a])
                [selected_acbs addObject:@[ a, cache, [NSNull either:border] ]];
            if ([self.mutableHighlightedAnnotations containsObject:a])
                [glowing_acbs addObject:@[ a, cache, [NSNull either:border] ]];
        }
        
        [NSColor.selectedTextBackgroundColor set];
        for (NSArray* acb in selected_acbs)
            [acb[0] highlightWithColor:NSColor.selectedTextBackgroundColor inView:self cache:acb[1] layer:layer context:ctx path:[acb[2] if:NSBezierPath.class]];
        for (NSArray* acb in selected_acbs)
            for (NIAnnotationHandle* handle in [acb[0] handlesInView:self])
                [[self.class NSBezierPathForHandle:handle] fill];
        
        NSColor* color = [NSColor highlightColor];
        for (NSArray* acb in glowing_acbs)
            [acb[0] highlightWithColor:color inView:self cache:acb[1] layer:layer context:ctx path:[acb[2] if:NSBezierPath.class]];
        
        [NSGraphicsContext restoreGraphicsState];
    }
    
    [super drawLayer:layer inContext:ctx];
}

- (NSMutableSet*)mutableAnnotations {
    return [self mutableSetValueForKey:@"annotations"];
}

- (void)addAnnotationsObject:(id)object {
    [_annotations addObject:object];
}

- (void)removeAnnotationsObject:(id)object {
    [_annotations removeObject:object];
}

- (NSMutableSet*)mutableHighlightedAnnotations {
    return [self mutableSetValueForKey:@"highlightedAnnotations"];
}

- (void)addHighlightedAnnotationsObject:(id)object {
    [_highlightedAnnotations addObject:object];
}

- (void)removeHighlightedAnnotationsObject:(id)object {
    [_highlightedAnnotations removeObject:object];
}

- (NSMutableSet*)mutableSelectedAnnotations {
    return [self mutableSetValueForKey:@"selectedAnnotations"];
}

- (void)addSelectedAnnotationsObject:(id)object {
    [_selectedAnnotations addObject:object];
}

- (void)removeSelectedAnnotationsObject:(id)object {
    [_selectedAnnotations removeObject:object];
}

- (NIAnnotation*)annotationClosestToSlicePoint:(NSPoint)location closestPoint:(NSPoint*)closestPoint distance:(CGFloat*)distance {
    return [self annotationClosestToSlicePoint:location closestPoint:closestPoint distance:distance filter:nil];
}

- (NIAnnotation*)annotationClosestToSlicePoint:(NSPoint)location closestPoint:(NSPoint*)closestPoint distance:(CGFloat*)distance filter:(BOOL (^)(NIAnnotation*))filter {
    NSMutableArray* adps = [NSMutableArray array]; // @[ annotation, distance ]
    
    for (NIAnnotation* a in self.mutableAnnotations)
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
    
    for (NIAnnotation* a in self.mutableAnnotations)
        if ([a intersectsSliceRect:sliceRect cache:self.annotationsCaches[[NSValue valueWithPointer:a]] view:self])
            [rset addObject:a];
    
    return rset;
}

- (NIAnnotationHandle*)handleForSlicePoint:(NSPoint)location {
    for (NIAnnotation* a in self.selectedAnnotations)
        for (NIAnnotationHandle* h in [a handlesInView:self])
            if ([[self.class NSBezierPathForHandle:h] containsPoint:location])
                return h;
    return nil;
}

@end

