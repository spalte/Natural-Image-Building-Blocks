//
//  MPRView.m
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRView.h"
#import "CPRMPRController.h"
#import "CPRMPRQuaternion.hpp"
#import "CPRIntersection.h"
#import <OsiriXAPI/CPRGeneratorRequest.h>
#import <OsiriXAPI/NSImage+N2.h>

static const N3Vector None = {CGFLOAT_MIN, CGFLOAT_MIN, CGFLOAT_MIN};

@interface CPRMPRView ()

@property NSUInteger blockGeneratorRequestUpdates;
@property(retain) NSTrackingArea* track;
@property N3Vector mouseDownLocation;
@property NSUInteger mouseDownModifierFlags;
@property N3AffineTransform mouseDownGeneratorRequestSliceToDicomTransform;

@end

@implementation CPRMPRView

@synthesize point = _point, normal = _normal, xdir = _xdir, ydir = _ydir;
@synthesize pixelSpacing = _pixelSpacing;//, rotation = _rotation;
@synthesize color = _color;
@synthesize menu = _menu;
@synthesize mouseDownLocation = _mouseDownLocation, mouseDownModifierFlags = _mouseDownModifierFlags, mouseDownGeneratorRequestSliceToDicomTransform = _mouseDownGeneratorRequestSliceToDicomTransform;
@synthesize blockGeneratorRequestUpdates = _blockGeneratorRequestUpdates;
@synthesize track = _track;
@synthesize flags = _flags;

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
    [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"point" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"normal" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"xdir" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"ydir" options:0 context:CPRMPRView.class];
    [self addObserver:self forKeyPath:@"pixelSpacing" options:0 context:CPRMPRView.class];    
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"pixelSpacing" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"ydir" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"xdir" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"normal" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"point" context:CPRMPRView.class];
    [self removeObserver:self forKeyPath:@"frame" context:CPRMPRView.class];
    self.color = nil;
    self.menu = nil;
    self.normal = self.xdir = self.ydir = nil;
    self.track = nil;
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != CPRMPRView.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"point"] || [keyPath isEqualToString:@"normal"] || [keyPath isEqualToString:@"xdir"] || [keyPath isEqualToString:@"ydir"] || [keyPath isEqualToString:@"pixelSpacing"]) {
        [self updateGeneratorRequest];
    }
    
    if ([keyPath isEqualToString:@"frame"]) {
        NSRect o = [change[NSKeyValueChangeOldKey] rectValue], n = [change[NSKeyValueChangeNewKey] rectValue];

        if (self.track) [self removeTrackingArea:self.track];
        [self addTrackingArea:(self.track = [[[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseMoved+NSTrackingActiveInActiveApp+NSTrackingInVisibleRect owner:self userInfo:@{ @"CPRMPRViewTrackingArea": @YES }] autorelease])];

        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        self.pixelSpacing = self.pixelSpacing/fmin(NSWidth(n), NSHeight(n))*fmin(NSWidth(o), NSHeight(o));
        
        [CATransaction commit];
    }
}

- (void)setNormal:(CPRMPRQuaternion*)normal :(CPRMPRQuaternion*)xdir :(CPRMPRQuaternion*)ydir reference:(CPRMPRQuaternion*)reference {
    [self lockGeneratorRequestUpdates];
    self.xdir = xdir;
    self.ydir = ydir;
    self.normal = normal;
    self.reference = reference;
    [self unlockGeneratorRequestUpdates];
}

- (void)rotate:(CGFloat)rads axis:(N3Vector)axis {
    [self lockGeneratorRequestUpdates];
    for (CPRMPRQuaternion* quaternion in @[ self.normal, self.xdir, self.ydir ])
        [quaternion rotate:rads axis:axis];
    [self unlockGeneratorRequestUpdates];
}

- (void)rotateToInitial {
    [self rotate:N3VectorAngleBetweenVectorsAroundVector(self.xdir.vector, self.reference.vector, self.normal.vector) axis:self.normal.vector];
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

#pragma mark Events

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)mouseEntered:(NSEvent*)event {
    [self.window makeFirstResponder:self];
    [self.window makeKeyAndOrderFront:self];
}

- (void)flagsChanged:(NSEvent*)event {
    if (N3VectorEqualToVector(self.mouseDownLocation, None)) {
        [self hoverUpdate:event location:[self convertPoint:[self.window convertScreenToBase:[NSEvent mouseLocation]] fromView:nil]];
    }
}

- (void)mouseMoved:(NSEvent*)event {
    [self hoverUpdate:event location:[self convertPoint:event.locationInWindow fromView:nil]];
}

- (void)hoverUpdate:(NSEvent*)event location:(NSPoint)location {
    CGFloat distance;
    NSString* ikey = [self intersectionClosestToPoint:location closestPoint:NULL distance:&distance];
    
    BOOL flag = (ikey && distance < 4);
    self.mouseDownModifierFlags = event.modifierFlags;
    
    if (flag)
        [[self.class openHandCursor:event.modifierFlags] set];
    else [[NSCursor arrowCursor] set];
    
    [self enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
        intersection.maskAroundMouse = !flag;
    }];
}

- (void)mouseDown:(NSEvent*)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
    
    CGFloat distance;
    NSString* ikey = [self intersectionClosestToPoint:location closestPoint:NULL distance:&distance];
    if (ikey && distance < 4) {
        [[self.class closedHandCursor:event.modifierFlags] set];
        self.mouseDownLocation = N3VectorApplyTransform(N3VectorMake(location.x, location.y, 0), self.generatorRequest.sliceToDicomTransform);
        self.mouseDownModifierFlags = event.modifierFlags;
        self.mouseDownGeneratorRequestSliceToDicomTransform = self.generatorRequest.sliceToDicomTransform;
        [self enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
            intersection.maskAroundMouse = NO;
        }];
    }
}

- (void)mouseDragged:(NSEvent*)event {
    if (!N3VectorEqualToVector(self.mouseDownLocation, None)) {
        N3Vector mouseDraggedLocation = N3VectorApplyTransform(N3VectorMakeFromNSPoint([self convertPoint:event.locationInWindow fromView:nil]), self.mouseDownGeneratorRequestSliceToDicomTransform);
        N3Vector center = N3VectorApplyTransform(N3VectorMake(NSWidth(self.bounds)/2, NSHeight(self.bounds)/2, 0), self.mouseDownGeneratorRequestSliceToDicomTransform);
        
        N3Vector a = N3VectorSubtract(self.mouseDownLocation, center), b = N3VectorSubtract(mouseDraggedLocation, center);
        CGFloat rads = N3VectorAngleBetweenVectorsAroundVector(a, b, self.normal.vector);
        if (rads > M_PI)
            rads -= M_PI*2;
        
        if (rads) {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];

            switch (self.mouseDownModifierFlags&NSDeviceIndependentModifierFlagsMask) {
                case 0: {
                    [self.window.windowController rotate:rads axis:self.normal.vector excluding:self];
                } break;
                case NSCommandKeyMask: {
                    [self rotate:-rads axis:self.normal.vector];
                } break;
            }
            
            [CATransaction commit];
        }
        
        self.mouseDownLocation = mouseDraggedLocation;
    }
    
    [super mouseDragged:event];
}

- (void)mouseUp:(NSEvent*)event {
    if (!N3VectorEqualToVector(self.mouseDownLocation, None)) {
        [[self.class openHandCursor:event.modifierFlags] set];
        self.mouseDownLocation = None;
        [self enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
            intersection.maskAroundMouse = YES;
        }];
    }
}

- (void)rightMouseDown:(NSEvent*)event {
    [NSMenu popUpContextMenu:self.menu withEvent:event forView:self];
}

#pragma mark Cursors

+ (NSCursor*)openHandCursor:(NSUInteger)flags {
    static NSMutableDictionary* cache = [[NSMutableDictionary alloc] init];
    return [self.class cursor:NSCursor.openHandCursor flags:flags cache:cache];
}

+ (NSCursor*)closedHandCursor:(NSUInteger)flags {
    static NSMutableDictionary* cache = [[NSMutableDictionary alloc] init];
    return [self.class cursor:NSCursor.closedHandCursor flags:flags cache:cache];
}

+ (NSCursor*)cursor:(NSCursor*)cursor flags:(NSUInteger)flags cache:(NSMutableDictionary*)cache {
    NSValue* key = [NSNumber numberWithUnsignedInteger:flags];
    
    NSCursor* c = cache[key];
    if (c)
        return c;
    
    const CGFloat midPoint = 0.25;
    
    switch (flags&NSDeviceIndependentModifierFlagsMask) {
        case NSCommandKeyMask: {
            c = [self.class cursor:cursor
             colorizeByMappingGray:midPoint
                           toColor:[NSColor colorWithCalibratedWhite:midPoint alpha:1]
                      blackMapping:NSColor.blackColor
                      whiteMapping:[NSColor colorWithCalibratedRed:1 green:1 blue:0.75 alpha:1]]; // very light yellow
        } break;
    }
    
    if (c) {
        cache[key] = c;
        return c;
    }
    
    return cursor;
}

+ (NSCursor*)cursor:(NSCursor*)cursor colorizeByMappingGray:(CGFloat)midPoint toColor:(NSColor*)midPointColor blackMapping:(NSColor*)shadowColor whiteMapping:(NSColor*)lightColor {
    return [[NSCursor alloc] initWithImage:[self.class image:cursor.image
                                       colorizeByMappingGray:midPoint
                                                     toColor:midPointColor
                                                blackMapping:shadowColor
                                                whiteMapping:lightColor]
                                   hotSpot:cursor.hotSpot];
}

+ (NSImage*)image:(NSImage*)image colorizeByMappingGray:(CGFloat)midPoint toColor:(NSColor*)midPointColor blackMapping:(NSColor*)shadowColor whiteMapping:(NSColor*)lightColor {
    NSImage* rimage = [[[NSImage alloc] initWithSize:image.size] autorelease];

    NSArray* reps = [image.representations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSImageRep* rep, NSDictionary* bindings) {
        return [rep isKindOfClass:NSBitmapImageRep.class];
    }]];
    
    for (NSBitmapImageRep* bitmap in reps) {
        NSBitmapImageRep* rbitmap = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:bitmap.pixelsWide pixelsHigh:bitmap.pixelsHigh bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:bitmap.pixelsWide*8*4 bitsPerPixel:32] autorelease];
        
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:rbitmap]];

        [image drawInRect:NSMakeRect(0, 0, rbitmap.pixelsWide, rbitmap.pixelsHigh) fromRect:NSMakeRect(0, 0, image.size.width, image.size.height) operation:NSCompositeCopy fraction:1];
        
        [NSGraphicsContext restoreGraphicsState];
        
        [rbitmap colorizeByMappingGray:midPoint toColor:midPointColor blackMapping:shadowColor whiteMapping:lightColor];
        
        [rimage addRepresentation:rbitmap];
    }
    
    return rimage;
}

@end
