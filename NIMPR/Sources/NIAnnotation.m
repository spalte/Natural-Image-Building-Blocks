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
    /*id NSBundleDidLoadNotificationObserver =*/ [[NSBundle observeNotification:NSBundleDidLoadNotification block:^(NSNotification* n) {
        BOOL hasWarnings = NO;

        for (NSString* className in n.userInfo[NSLoadedClasses]) {
            Class class = [n.object classNamed:className];
            BOOL flag = NO;
            for (Class sc = class_getSuperclass(class); sc; sc = class_getSuperclass(sc))
                if (sc == NIAnnotation.class) {
                    flag = YES;
                    break;
                }
            if (flag) {
                Class iamc = class;
                for (Class sc = class_getSuperclass(iamc); class_getClassMethod(sc, @selector(isAbstract)) == class_getClassMethod(iamc, @selector(isAbstract)); sc = class_getSuperclass(sc))
                    iamc = sc;
                if (iamc == class && class.isAbstract)
                    flag = NO;
            }
            if (flag) {
                if ([[NIJSON recordForClass:class] valueForKey:@"type"] != class) {
                    hasWarnings = YES;
                    NSLog(@"Warning: annotation class %@ isn't registered to NIJSON", className);
                } else {
                    if (class_getMethodImplementation(class, @selector(initWithCoder:)) == class_getMethodImplementation(class_getSuperclass(class), @selector(initWithCoder:))) {
                        hasWarnings = YES;
                        NSLog(@"Warning: missing method implementation -[%@ initWithCoder:]", className);
                    }
                    if (class_getMethodImplementation(class, @selector(encodeWithCoder:)) == class_getMethodImplementation(class_getSuperclass(class), @selector(encodeWithCoder:))) {
                        hasWarnings = YES;
                        NSLog(@"Warning: missing method implementation -[%@ encodeWithCoder:]", className);
                    }
                }
            }
        }
        
        if (hasWarnings && n.object == [NSBundle bundleForClass:self.class]) {
            NSLog(@"Exiting because of the warnings related to %@ (in %@, line %d)", [[n.object bundleURL] lastPathComponent], [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__);
            exit(0);
        }
    }] retain];
}

//+ (void)finalize {
//    [NSBundleDidLoadNotificationObserver autorelease];
//}

@synthesize name = _name;
@synthesize color = _color;
@synthesize locked = _locked;
@synthesize changes = _changes;

- (void)initNIAnnotation {
    self.locked = [self.class lockedDefault];
    self.changes = [NSMutableDictionary dictionary];
    [self enableChangeObservers:YES];
    [self addObserver:self forKeyPath:@"annotation" options:0 context:NIAnnotation.class];
}

- (instancetype)init {
    if ((self = [super init])) {
        [self initNIAnnotation];
    }
    
    return self;
}

static NSString* const NIAnnotationNameKey = @"name";
static NSString* const NIAnnotationColorKey = @"color";
static NSString* const NIAnnotationLockedKey = @"locked";

- (instancetype)initWithCoder:(NSCoder*)coder {
    if ((self = [super init])) {
        [self initNIAnnotation];
        self.name = [coder decodeObjectForKey:NIAnnotationNameKey];
        self.color = [coder decodeObjectForKey:NIAnnotationColorKey];
        self.locked = ([coder containsValueForKey:NIAnnotationLockedKey]? [coder decodeBoolForKey:NIAnnotationLockedKey] : [self.class lockedDefault]);
    }
    
    return self;
}

//- (id)awakeAfterUsingCoder:(NSCoder*)decoder {
//    
//}

- (void)encodeWithCoder:(NSCoder*)coder {
    if (!coder.allowsKeyedCoding)
        [NSException raise:NSGenericException format:@"Annotation storage requires keyed coding support"];

    if (self.name.length) [coder encodeObject:self.name forKey:NIAnnotationNameKey];
    if (self.color) [coder encodeObject:self.color forKey:NIAnnotationColorKey];
    if (self.locked != [self.class lockedDefault]) [coder encodeBool:self.locked forKey:NIAnnotationLockedKey];
}

+ (BOOL)lockedDefault {
    return NO;
}

- (void)dealloc {
    [self.class cancelPreviousPerformRequestsWithTarget:self];
    [self removeObserver:self forKeyPath:@"annotation" context:NIAnnotation.class];
    [self enableChangeObservers:NO];
    self.changes = nil;
    [_color release];
    [_name release];
    [super dealloc];
}

+ (BOOL)isAbstract {
    return YES;
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

- (void)drawInView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache {
    NSLog(@"Warning: -[%@ drawInView:cache:] is missing", self.className);
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

- (NSSet*)handlesInView:(NIAnnotatedGeneratorRequestView*)view {
    return [NSSet set];
}

@end
