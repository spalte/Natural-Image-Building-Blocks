//
//  NIMPRAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/8/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotation.h"
#import <objc/runtime.h>
#import "NIJSON.h"
#import "NSMenu+NIMPR.h"

#import "NIMaskAnnotation.h"

// NIAnnotationRequestCache dictionary keys
NSString* const NIAnnotationRequest = @"NIAnnotationRequest"; // NIGeneratorRequest
NSString* const NIAnnotationProjection = @"NIAnnotationProjection"; // NSImage
NSString* const NIAnnotationProjectionMask = @"NIAnnotationProjectionMask"; // NSImage

NSString* const NIAnnotationChangeNotification = @"NIAnnotationChange";
NSString* const NIAnnotationChangeNotificationChangesKey = @"changes";

CGFloat const NIAnnotationDistant = 4;

NSString* const NIAnnotationTransformKey = @"transform";

@interface NIAnnotation ()

@property(retain) NSMutableDictionary* changes;

@end

@implementation NIAnnotation

+ (void)load {
    [self.class retain:[NSBundle observeNotification:NSBundleDidLoadNotification block:^(NSNotification* n) {
        for (NSString* className in n.userInfo[NSLoadedClasses]) {
            Class class = [n.object classNamed:className];
            if (class_getClassMethod(class, @selector(isAbstract)) == class_getClassMethod(class_getSuperclass(class), @selector(isAbstract)) || !class.isAbstract)
                for (Class sc = class_getSuperclass(class); sc; sc = class_getSuperclass(sc))
                    if (sc == NIAnnotation.class) {
                        if ([[NIJSON recordForClass:class] valueForKey:@"type"] != class)
                            NSLog(@"Warning: annotation class %@ isn't registered to NIJSON", className);

                        if (class_getMethodImplementation(class, @selector(initWithCoder:)) == class_getMethodImplementation(class_getSuperclass(class), @selector(initWithCoder:)))
                            NSLog(@"Warning: missing method implementation -[%@ initWithCoder:]", className);
                        else if (class_getMethodImplementation(class, @selector(init)) == class_getMethodImplementation(class_getSuperclass(class), @selector(init)))
                            NSLog(@"Warning: missing method implementation -[%@ init] while [%@ initWithCoder:] is provided", className, className);
                        if (class_getMethodImplementation(class, @selector(encodeWithCoder:)) == class_getMethodImplementation(class_getSuperclass(class), @selector(encodeWithCoder:)))
                            NSLog(@"Warning: missing method implementation -[%@ encodeWithCoder:]", className);
                        
                        if (class_getMethodImplementation(class, @selector(translate:)) == class_getMethodImplementation(NIAnnotation.class, @selector(translate:)))
                            NSLog(@"Warning: missing method implementation -[%@ translate:]", className);
                        if (class_getMethodImplementation(class, @selector(maskForVolume:)) == class_getMethodImplementation(NIAnnotation.class, @selector(maskForVolume:)))
                            NSLog(@"Warning: missing method implementation -[%@ maskForVolume:]", className);
                        if (class_getMethodImplementation(class, @selector(drawInView:cache:)) == class_getMethodImplementation(NIAnnotation.class, @selector(drawInView:cache:)))
                            NSLog(@"Warning: missing method implementation -[%@ drawInView:cache:]", className);
                        if (class_getMethodImplementation(class, @selector(distanceToSlicePoint:cache:view:closestPoint:)) == class_getMethodImplementation(NIAnnotation.class, @selector(distanceToSlicePoint:cache:view:closestPoint:)))
                            NSLog(@"Warning: missing method implementation -[%@ distanceToSlicePoint:cache:view:closestPoint:]", className);
                        if (class_getMethodImplementation(class, @selector(intersectsSliceRect:cache:view:)) == class_getMethodImplementation(NIAnnotation.class, @selector(intersectsSliceRect:cache:view:)))
                            NSLog(@"Warning: missing method implementation -[%@ intersectsSliceRect:cache:view:]", className);
                    }
        }
    }]];
}

//+ (void)finalize {
//    [NSBundleDidLoadNotificationObserver autorelease];
//}

@synthesize name = _name;
@synthesize color = _color;
@synthesize locked = _locked;
@synthesize changes = _changes;

- (instancetype)init {
    if ((self = [super init])) {
        self.changes = [NSMutableDictionary dictionary];
        self.locked = [self.class defaultLocked];
        [self enableChangeObservers:YES];
    }
    
    return self;
}

static NSString* const NIAnnotationName = @"name";
static NSString* const NIAnnotationColor = @"color";
static NSString* const NIAnnotationLocked = @"locked";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

- (instancetype)initWithCoder:(NSCoder*)coder {
    if ((self = [self init])) {
        if ([coder containsValueForKey:NIAnnotationName])
            self.name = [coder decodeObjectForKey:NIAnnotationName];
        if ([coder containsValueForKey:NIAnnotationColor])
            self.color = [coder decodeObjectForKey:NIAnnotationColor];
        if ([coder containsValueForKey:NIAnnotationLocked])
            self.locked = [coder decodeBoolForKey:NIAnnotationLocked];
    }
    
    return self;
}

#pragma clang diagnostic pop

//- (id)awakeAfterUsingCoder:(NSCoder*)decoder {
//    
//}

- (void)encodeWithCoder:(NSCoder*)coder {
    if (!coder.allowsKeyedCoding)
        [NSException raise:NSGenericException format:@"Annotation storage requires keyed coding support"];
    if (self.name.length)
        [coder encodeObject:self.name forKey:NIAnnotationName];
    if (self.color)
        [coder encodeObject:self.color forKey:NIAnnotationColor];
    if (self.locked != [self.class defaultLocked])
        [coder encodeBool:self.locked forKey:NIAnnotationLocked];
}

- (void)dealloc {
    [self.class cancelPreviousPerformRequestsWithTarget:self];
    [self enableChangeObservers:NO];
    self.changes = nil;
    [_color release];
    [_name release];
    [super dealloc];
}

+ (BOOL)isAbstract {
    return YES;
}

+ (BOOL)defaultLocked {
    return NO;
}

- (void)enableChangeObservers:(BOOL)flag {
    NSMutableSet* kps = [NSMutableSet setWithObject:@"annotation"];
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
        [self performSelector:@selector(_notifyAnnotationChanges:) withObject:[[self.changes copy] autorelease] afterDelay:0];
        [self.changes removeAllObjects];
    }
}

- (void)_notifyAnnotationChanges:(NSDictionary*)changes {
    [[NSNotificationCenter defaultCenter] postNotificationName:NIAnnotationChangeNotification object:self userInfo:@{ NIAnnotationChangeNotificationChangesKey: changes }];
}

- (BOOL)annotation {
    return NO;
}

+ (NSSet*)keyPathsForValuesAffectingAnnotation {
    return [NSSet set];
}

static NSColor* NIAnnotationDefaultColor = nil;
static NSString* const NIANnotationDefaultColorKey = @"NIAnnotationDefaultColor";

+ (NSColor*)defaultColor {
    if (NIAnnotationDefaultColor == nil)
        return [NSColor greenColor];
    return NIAnnotationDefaultColor;
}

+ (void)setDefaultColor:(NSColor*)color {
    if (color != NIAnnotationDefaultColor) {
        NIAnnotationDefaultColor = [self.class retain:color forKey:NIANnotationDefaultColorKey];
    }
}

+ (NSColor*)color:(NIAnnotation*)annotation {
    NSColor* color = annotation.color;
    if (color)
        return color;
    return [annotation.class defaultColor];
}

+ (NSString*)name:(NIAnnotation*)annotation {
    NSString* name = annotation.name;
    if (name)
        return name;
    
    name = annotation.className;
    if ([name hasPrefix:@"NI"])
        name = [name substringFromIndex:2];
    if ([name hasSuffix:@"Annotation"])
        name = [name substringToIndex:name.length-10];
    
    return name;
}

- (void)translate:(NIVector)translation {
    NSLog(@"Warning: -[%@ translate:] is missing", self.className);
}

- (NIMask*)maskForVolume:(NIVolumeData*)volume {
    NSLog(@"Warning: -[%@ maskForVolume:] is missing", self.className);
    return nil;
}

- (void)populateContextualMenu:(NSMenu*)menu forView:(NIAnnotatedGeneratorRequestView*)view {
    if (menu.itemArray.count)
        [menu addItem:[NSMenuItem separatorItem]];
    
    [menu addItemWithTitle:NSLocalizedString(@"Delete", nil) block:^{
        [view.mutableAnnotations removeObject:self];
    }];

}

- (void)drawInView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache {
    NIVolumeData* v = [view volumeDataAtIndex:0];
    
    NIMask* mask = [self maskForVolume:v];
    if (mask) {
        NIMaskAnnotation* ma = [[NIMaskAnnotation alloc] initWithMask:mask transform:NIAffineTransformInvert(v.volumeTransform)];
        ma.color = [NSColor redColor];
        [ma drawInView:view cache:[NSMutableDictionary dictionary]];
    }
    
    //NSLog(@"Warning: -[%@ drawInView:cache:] is missing", self.className);
}

//- (void)highlightWithColor:(NSColor*)color inView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache {
////    if (!path.elementCount)
//        return NSLog(@"Warning: -[%@ highlightWithColor:inView:cache:] is missing", self.className);
//    
////    [NSGraphicsContext saveGraphicsState];
////    NSGraphicsContext* context = [NSGraphicsContext currentContext];
////    
//////    path = [[path copy] autorelease];
//////    path.lineWidth = path.lineWidth+1;
////    [color set];
////    [context setCompositingOperation:NSCompositeSourceOver]; // NSCompositeHighlight
////    [path stroke];
////    
////    [NSGraphicsContext restoreGraphicsState];
//}

- (CGFloat)distanceToSlicePoint:(NSPoint)point cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view closestPoint:(NSPoint*)rpoint {
    NSLog(@"Warning: -[%@ distanceToSlicePoint:cache:view:closestPoint:] is missing", self.className);
    return CGFLOAT_MAX;
}

- (BOOL)intersectsSliceRect:(NSRect)rect cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view {
    NSLog(@"Warning: -[%@ intersectsSliceRect:cache:view:] is missing", self.className);
    return NO;
}

- (NSSet*)handlesInView:(NIAnnotatedGeneratorRequestView*)view {
    return [NSSet set];
}

@end
