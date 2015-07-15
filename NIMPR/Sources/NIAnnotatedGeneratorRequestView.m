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

@property (readwrite, retain) CALayer* annotationsLayer;

@end

@implementation NIAnnotatedGeneratorRequestView

@synthesize annotationsLayer = _annotationsLayer;

- (void)initialize:(Class)class {
    [super initialize:class];
    
    if (class != NIGeneratorRequestView.class)
        return;
    
    _annotations = [[NSMutableSet alloc] init];
    
    CALayer* layer = self.annotationsLayer = [[[CALayer alloc] init] autorelease];
    layer.delegate = self;
    layer.needsDisplayOnBoundsChange = YES;
    layer.zPosition = NIGeneratorRequestViewSpriteZPosition-1;
    layer.contentsScale = self.frameLayer.contentsScale;
    [layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
    [layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
    [layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
    [layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];
    [self.frameLayer addSublayer:layer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdatePresentedGeneratorRequestNotification:)
                                                 name:NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotification object:self];
    
    [self addObserver:self forKeyPath:@"annotations" options:NSKeyValueObservingOptionInitial+NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIAnnotatedGeneratorRequestView.class];
}

- (void)dealloc {
    [self observeValueForKeyPath:@"annotations" ofObject:self change:@{ NSKeyValueChangeOldKey: self.publicAnnotations } context:NIAnnotatedGeneratorRequestView.class];
    [self removeObserver:self forKeyPath:@"annotations" context:NIAnnotatedGeneratorRequestView.class];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NIGeneratorRequestViewDidUpdatePresentedGeneratorRequestNotification object:self];

    self.annotationsLayer = nil;
    [_annotations release];
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != NIAnnotatedGeneratorRequestView.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"annotations"]) {
        for (NIAnnotation* a in change[NSKeyValueChangeOldKey])
            [a removeObserver:self forKeyPath:@"annotation" context:context];
        for (NIAnnotation* a in change[NSKeyValueChangeNewKey])
            [a addObserver:self forKeyPath:@"annotation" options:NSKeyValueObservingOptionInitial context:context];
    }
    
    if ([keyPath isEqualToString:@"annotation"]) {
        [self.annotationsLayer setNeedsDisplay];
    }
}

- (void)didUpdatePresentedGeneratorRequestNotification:(NSNotification*)notification {
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

        for (NIAnnotation* annotation in self.publicAnnotations)
            [annotation drawInView:self];
        
        [NSGraphicsContext restoreGraphicsState];
    }
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

- (NIAnnotation*)annotationClosestToPoint:(NSPoint)location closestPoint:(NSPoint*)closestPoint distance:(CGFloat*)distance {
    NSMutableArray* annotations = [NSMutableArray array];
    
    
    return nil;
}



@end

