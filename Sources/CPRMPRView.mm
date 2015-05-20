//
//  MPRView.m
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRView.h"
#import "CPRMPRIntersection.h"
#import "CPRMPRController.h"
#import "CPRMPRQuaternion.hpp"
#import <OsiriXAPI/CPRGeneratorRequest.h>

@interface CPRMPRView (CPRMPR)

- (CPRMPRIntersection*)intersectionForKey:(NSString*)key;

@end

static const NSPoint None = {CGFLOAT_MIN, CGFLOAT_MIN};

@interface CPRMPRView ()

@property NSUInteger blockGeneratorRequestUpdates;
@property NSPoint mouseDownLocation;
//@property(retain) NSArray* storedVectors;

@end

@implementation CPRMPRView

@synthesize point = _point, normal = _normal, xdir = _xdir, ydir = _ydir;
@synthesize pixelSpacing = _pixelSpacing;//, rotation = _rotation;
@synthesize color = _color;

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        [self initialize];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self initialize];
    }
    
    return self;
}

- (void)initialize {
    self.mouseDownLocation = None;
    [self addObserver:self forKeyPath:@"point" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"normal" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"xdir" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"ydir" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"rotation" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"pixelSpacing" options:0 context:CPRMPRView.class];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"pixelSpacing" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"rotation" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"ydir" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"xdir" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"normal" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"point" context:CPRMPRView.class];
    self.color = nil;
//    self.storedVectors = nil;
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != CPRMPRView.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"point"] || [keyPath isEqualToString:@"normal"] || [keyPath isEqualToString:@"xdir"] || [keyPath isEqualToString:@"ydir"] || [keyPath isEqualToString:@"rotation"] || [keyPath isEqualToString:@"pixelSpacing"]) {
        [self updateGeneratorRequest];
    }
}

- (void)setNormal:(N3Vector)normal :(N3Vector)xdir :(N3Vector)ydir {
    if (NSEqualPoints(self.mouseDownLocation, None)) {
    [self generatorRequestUpdatesLock];
    self.xdir = xdir;//[[CPRMPRQuaternion quaternion:xdir] rotated:-self.rotation axis:self.qnormal];
    self.ydir = ydir;//[[CPRMPRQuaternion quaternion:ydir] rotated:-self.rotation axis:self.qnormal];
    self.normal = normal;//[[CPRMPRQuaternion quaternion:normal] rotated:-self.rotation axis:self.qnormal];
    [self generatorRequestUpdatesUnlock:YES];
//        self.storedVectors = nil;
    } //else
        //self.storedVectors = @[ [NSValue valueWithN3Vector:normal], [NSValue valueWithN3Vector:xdir], [NSValue valueWithN3Vector:ydir] ];
}

- (void)updateGeneratorRequest {
    if (self.blockGeneratorRequestUpdates)
        return;
    
    if (!self.pixelSpacing)
        return;
    
    CPRGeneratorRequest* req = [[[CPRObliqueSliceGeneratorRequest alloc] initWithCenter:self.point pixelsWide:NSWidth(self.frame) pixelsHigh:NSHeight(self.frame) xBasis:N3VectorScalarMultiply(self.xdir, self.pixelSpacing) yBasis:N3VectorScalarMultiply(self.ydir, self.pixelSpacing)] autorelease];
    if (![req isEqual:self.generatorRequest])
        self.generatorRequest = req;
}

- (void)generatorRequestUpdatesLock {
    ++self.blockGeneratorRequestUpdates;
}

- (void)generatorRequestUpdatesUnlock {
    [self generatorRequestUpdatesUnlock:YES];
}

- (void)generatorRequestUpdatesUnlock:(BOOL)update {
    if (--self.blockGeneratorRequestUpdates == 0)
        if (update)
            [self updateGeneratorRequest];
}

- (void)mouseDown:(NSEvent*)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
    
    CGFloat distance;
    NSPoint point;
    
    NSString* ikey = [self intersectionClosestToPoint:location closestPoint:&point distance:&distance];
    if (ikey && distance < 4) {
//        [self generatorRequestUpdatesLock];
        self.mouseDownLocation = point;
    }
}

- (void)mouseDragged:(NSEvent*)event {
    if (!NSEqualPoints(self.mouseDownLocation, None)) {
        NSPoint mouseDraggedLocation = [self convertPoint:event.locationInWindow fromView:nil];
        NSPoint pivot = NSMakePoint(NSWidth(self.bounds)/2, NSHeight(self.bounds)/2);
        
        N3Vector a = N3VectorMake(mouseDraggedLocation.x-pivot.x, mouseDraggedLocation.y-pivot.y, 0), b = N3VectorMake(self.mouseDownLocation.x-pivot.x, self.mouseDownLocation.y-pivot.y, 0);
        CGFloat rads = atan2(a.y, a.x) - atan2(b.y, b.x);
        
        if (rads == 0)
            NSLog(@"jdidfjd");
        
        if (rads) {
//            [self generatorRequestUpdatesLock];
//            self.rotation += rads;
//            NSLog(@"the rotation now is %f", self.rotation);
            [self.window.windowController rotate:rads axis:self.normal];
//            [self generatorRequestUpdatesUnlock];
        }

        self.mouseDownLocation = mouseDraggedLocation;
    }
}

- (void)mouseUp:(NSEvent*)event {
    if (!NSEqualPoints(self.mouseDownLocation, None)) {
        self.mouseDownLocation = None;
//        [self generatorRequestUpdatesUnlock];
//        NSLog(@"Updating dirs: (%f,%f,%f) (%f,%f,%f) (%f,%f,%f)",
//              [self.storedVectors[0] N3VectorValue].x, [self.storedVectors[0] N3VectorValue].y, [self.storedVectors[0] N3VectorValue].z,
//              [self.storedVectors[1] N3VectorValue].x, [self.storedVectors[1] N3VectorValue].y, [self.storedVectors[1] N3VectorValue].z,
//              [self.storedVectors[2] N3VectorValue].x, [self.storedVectors[2] N3VectorValue].y, [self.storedVectors[2] N3VectorValue].z);
//        [self setNormal:[self.storedVectors[0] N3VectorValue] :[self.storedVectors[1] N3VectorValue] :[self.storedVectors[2] N3VectorValue]];
    }
}

@end
