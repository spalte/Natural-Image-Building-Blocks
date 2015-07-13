//
//  NIMPRAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/8/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotation.h"

NSString* const NIAnnotationChangeNotification = @"NIAnnotationChange";
NSString* const NIAnnotationChangeNotificationChangesKey = @"changes";

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

- (void)drawInView:(NIAnnotatedGeneratorRequestView*)view {
    // this abstract class won't render
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

@end

