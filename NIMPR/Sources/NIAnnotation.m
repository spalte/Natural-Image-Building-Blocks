//
//  NIMPRAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/8/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotation.h"
#import "NIPointAnnotation.h"
#import "NISegmentAnnotation.h"
#import "NIEllipseAnnotation.h"

NSString* const NIAnnotationChangeNotification = @"NIAnnotationChange";
NSString* const NIAnnotationChangeNotificationChangesKey = @"changes";
NSString* const NIAnnotationDrawCache = @"NIAnnotationDrawCache";
CGFloat const NIAnnotationDistant = 4;

@interface NIAnnotation ()

@property(retain) NSMutableDictionary* changes;

@end

@implementation NIAnnotation

@synthesize color = _color;
@synthesize changes = _changes;

- (instancetype)init {
    if ((self = [super init])) {
        self.changes = [NSMutableDictionary dictionary];
        [self enableChangeObservers:YES];
        [self addObserver:self forKeyPath:@"annotation" options:0 context:NIAnnotation.class];
    }
    
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"annotation" context:NIAnnotation.class];
    [self enableChangeObservers:NO];
    self.changes = nil;
    [super dealloc];
}

- (void)enableChangeObservers:(BOOL)flag {
    NSMutableSet* kps = [[[self.class keyPathsForValuesAffectingAnnotation] mutableCopy] autorelease];
    while (kps.count) {
        NSString* kp = kps.anyObject;
        [kps removeObject:kp];
        [kps unionSet:[self.class keyPathsForValuesAffectingValueForKey:kp]];
        if (flag)
            [self addObserver:self forKeyPath:kp options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIAnnotation.class];
        else [self removeObserver:self forKeyPath:kp context:NIAnnotation.class];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != NIAnnotation.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if (![keyPath isEqualToString:@"annotation"]) {
        self.changes[keyPath] = change;
    } else {
        [self performSelector:@selector(notifyAnnotationChange) withObject:nil afterDelay:0];
    }
}

- (void)notifyAnnotationChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:NIAnnotationChangeNotification object:self userInfo:@{ NIAnnotationChangeNotificationChangesKey: [[self.changes copy] autorelease] }];
    [self.changes removeAllObjects];
}

- (BOOL)annotation {
    return NO;
}

+ (NSSet*)keyPathsForValuesAffectingAnnotation {
    return [NSSet set];
}

- (void)translate:(NIVector)translation {
    NSLog(@"Warning: -[%@ translate:] is missing", self.className);
}

- (NSBezierPath*)drawInView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache layer:(CALayer*)layer context:(CGContextRef)ctx {
    NSLog(@"Warning: -[%@ drawInView:cache:layer:context:] is missing", self.className);
    return nil;
}

- (void)highlightWithColor:(NSColor*)color inView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache layer:(CALayer*)layer context:(CGContextRef)ctx path:(NSBezierPath*)path {
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext* context = [NSGraphicsContext currentContext];
    
//    path = [[path copy] autorelease];
//    path.lineWidth = path.lineWidth+1;
    [color set];
    [context setCompositingOperation:NSCompositeSourceOver]; // NSCompositeHighlight
    [path stroke];
    
    [NSGraphicsContext restoreGraphicsState];
}

- (CGFloat)distanceToSlicePoint:(NSPoint)point cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view closestPoint:(NSPoint*)rpoint {
    NSLog(@"Warning: -[%@ distanceToSlicePoint:view:closestPoint:] is missing", self.className);
    return CGFLOAT_MAX;
}

- (BOOL)intersectsSliceRect:(NSRect)rect cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view {
    NSLog(@"Warning: -[%@ intersectsSliceRect:view:] is missing", self.className);
    return NO;
}

static NSColor* NIAnnotationDefaultColor = nil;

+ (NSColor*)defaultColor {
    if (NIAnnotationDefaultColor == nil)
        return [NSColor greenColor];
    return NIAnnotationDefaultColor;
}

+ (void)setDefaultColor:(NSColor*)color {
    if (color != NIAnnotationDefaultColor) {
        [NIAnnotationDefaultColor release];
        NIAnnotationDefaultColor = [color retain];
    }
}

- (NSColor*)color {
    if (_color)
        return _color;
    return [self.class defaultColor];
}

- (NSSet*)handlesInView:(NIAnnotatedGeneratorRequestView*)view {
    return [NSSet set];
}

+ (id)pointWithVector:(NIVector)vector {
    return [[[NIPointAnnotation alloc] initWithVector:vector] autorelease];
}

+ (id)segmentWithPoints:(NSPoint)p :(NSPoint)q transform:(NIAffineTransform)sliceToDicomTransform {
    return [[[NISegmentAnnotation alloc] initWithPoints:p:q transform:sliceToDicomTransform] autorelease];
}

+ (id)rectangleWithBounds:(NSRect)bounds transform:(NIAffineTransform)sliceToDicomTransform {
    return [[[NIRectangleAnnotation alloc] initWithBounds:bounds transform:sliceToDicomTransform] autorelease];
}

+ (id)ellipseWithBounds:(NSRect)bounds transform:(NIAffineTransform)sliceToDicomTransform {
    return [[[NIEllipseAnnotation alloc] initWithBounds:bounds transform:sliceToDicomTransform] autorelease];
}

@end


