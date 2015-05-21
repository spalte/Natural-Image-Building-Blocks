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

static const N3Vector None = {CGFLOAT_MIN, CGFLOAT_MIN, CGFLOAT_MIN};

@interface CPRMPRView ()

@property NSUInteger blockGeneratorRequestUpdates;
@property NSPoint mouseDownLocation;
@property N3Vector mouseDownLocationT;
//@property(retain) NSArray* storedVectors;

@end

@implementation CPRMPRView

@synthesize point = _point, normal = _normal, xdir = _xdir, ydir = _ydir;
@synthesize pixelSpacing = _pixelSpacing;//, rotation = _rotation;
@synthesize color = _color;
@synthesize mouseDownLocation = _mouseDownLocation;
@synthesize mouseDownLocationT = _mouseDownLocationT;
@synthesize blockGeneratorRequestUpdates = _blockGeneratorRequestUpdates;

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
    self.mouseDownLocationT = None;
    [self addObserver:self forKeyPath:@"point" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"normal" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"xdir" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"ydir" options:0 context:CPRMPRView.class];
//    [self addObserver:self forKeyPath:@"rotation" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"pixelSpacing" options:0 context:CPRMPRView.class];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"pixelSpacing" context:CPRMPRView.class];
//    [self removeObserver:self forKeyPath:@"rotation" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"ydir" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"xdir" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"normal" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"point" context:CPRMPRView.class];
    self.color = nil;
//    self.storedVectors = nil;
    self.normal = self.xdir = self.ydir = nil;
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != CPRMPRView.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"point"] || [keyPath isEqualToString:@"normal"] || [keyPath isEqualToString:@"xdir"] || [keyPath isEqualToString:@"ydir"] || /*[keyPath isEqualToString:@"rotation"] ||*/ [keyPath isEqualToString:@"pixelSpacing"]) {
        [self updateGeneratorRequest];
    }
}

- (void)setNormal:(CPRMPRQuaternion*)normal :(CPRMPRQuaternion*)xdir :(CPRMPRQuaternion*)ydir {
//    if (N3VectorEqualToVector(self.mouseDownLocation, None)) {
        [self lockGeneratorRequestUpdates];
        self.xdir = xdir;
        self.ydir = ydir;
        self.normal = normal;
        [self unlockGeneratorRequestUpdates];
//    }
}

- (void)rotate:(CGFloat)rads axis:(N3Vector)axis {
    [self lockGeneratorRequestUpdates];
    [self.normal rotate:rads axis:axis];
    [self.xdir rotate:rads axis:axis];
    [self.ydir rotate:rads axis:axis];
    [self unlockGeneratorRequestUpdates];
}

- (void)updateGeneratorRequest {
    if (self.blockGeneratorRequestUpdates)
        return;
    
    if (!self.pixelSpacing)
        return;
    
    CPRObliqueSliceGeneratorRequest* req = [[[CPRObliqueSliceGeneratorRequest alloc] initWithCenter:self.point pixelsWide:NSWidth(self.frame) pixelsHigh:NSHeight(self.frame) xBasis:N3VectorScalarMultiply(self.xdir.vector, self.pixelSpacing) yBasis:N3VectorScalarMultiply(self.ydir.vector, self.pixelSpacing)] autorelease];
    if (![req isEqual:self.generatorRequest])
        self.generatorRequest = req;
}

- (void)lockGeneratorRequestUpdates {
    ++self.blockGeneratorRequestUpdates;
}

- (void)unlockGeneratorRequestUpdates {
    [self generatorRequestUpdatesUnlock:YES];
}

- (void)generatorRequestUpdatesUnlock:(BOOL)update {
    if (--self.blockGeneratorRequestUpdates == 0)
        if (update)
            [self updateGeneratorRequest];
}

//- (void)mouseMoved:(NSEvent*)event {
//    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
//    
//    CGFloat distance;
//    NSString* ikey = [self intersectionClosestToPoint:location closestPoint:NULL distance:&distance];
//    [self performSelector:@selector(intersectionsMaskAroundMouse:) withObject:@(ikey && distance < 4) afterDelay:0];
//}

- (void)intersectionsMaskAroundMouse:(BOOL)flag {
    [self enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
        intersection.maskAroundMouse = flag;
    }];
}

- (void)mouseDown:(NSEvent*)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
    
    CGFloat distance;
    NSString* ikey = [self intersectionClosestToPoint:location closestPoint:NULL distance:&distance];
    if (ikey && distance < 4) {
//        [self generatorRequestUpdatesLock];
        self.mouseDownLocation = location;
        self.mouseDownLocationT = N3VectorApplyTransform(N3VectorMake(location.x, location.y, 0), self.generatorRequest.sliceToDicomTransform);
        [self enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
            intersection.maskAroundMouse = NO;
        }];
    }
}

- (void)mouseDragged:(NSEvent*)event {
    if (!N3VectorEqualToVector(self.mouseDownLocationT, None)) {
        NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
        N3Vector mouseDraggedLocationT = N3VectorApplyTransform(N3VectorMake(location.x, location.y, 0), self.generatorRequest.sliceToDicomTransform);
        NSPoint plocation = NSMakePoint(NSWidth(self.bounds)/2, NSHeight(self.bounds)/2);
        N3Vector pivotT = N3VectorApplyTransform(N3VectorMake(plocation.x, plocation.y, 0), self.generatorRequest.sliceToDicomTransform);
        
        N3Vector a = N3VectorSubtract(self.mouseDownLocationT, pivotT), b = N3VectorSubtract(mouseDraggedLocationT, pivotT);
        CGFloat rads = N3VectorAngleBetweenVectorsAroundVector(a, b, self.normal.vector);

        N3Vector ma = N3VectorMake(location.x-plocation.x, location.y-plocation.y, 0), mb = N3VectorMake(self.mouseDownLocation.x-plocation.x, self.mouseDownLocation.y-plocation.y, 0);
        CGFloat mrads = atan2(ma.y, ma.x) - atan2(mb.y, mb.x);
        
        if (mrads) {
//            [self lockGeneratorRequestUpdates];
//            self.rotation -= rads;
//            NSLog(@"the rotation now is %f", self.rotation);
            [self.window.windowController rotate:mrads axis:self.normal.vector excluding:self];
//            [self unlockGeneratorRequestUpdates];
        }
        
        self.mouseDownLocation = location;
        self.mouseDownLocationT = mouseDraggedLocationT;
    }
    
    [super mouseDragged:event];
}

- (void)mouseUp:(NSEvent*)event {
    if (!N3VectorEqualToVector(self.mouseDownLocationT, None)) {
        self.mouseDownLocationT = None;
        [self enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
            intersection.maskAroundMouse = YES;
        }];

//        [self generatorRequestUpdatesUnlock];
//        NSLog(@"Updating dirs: (%f,%f,%f) (%f,%f,%f) (%f,%f,%f)",
//              [self.storedVectors[0] N3VectorValue].x, [self.storedVectors[0] N3VectorValue].y, [self.storedVectors[0] N3VectorValue].z,
//              [self.storedVectors[1] N3VectorValue].x, [self.storedVectors[1] N3VectorValue].y, [self.storedVectors[1] N3VectorValue].z,
//              [self.storedVectors[2] N3VectorValue].x, [self.storedVectors[2] N3VectorValue].y, [self.storedVectors[2] N3VectorValue].z);
//        [self setNormal:[self.storedVectors[0] N3VectorValue] :[self.storedVectors[1] N3VectorValue] :[self.storedVectors[2] N3VectorValue]];
    }
}

@end
