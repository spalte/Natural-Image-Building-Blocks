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
#import <OsiriXAPI/NSImage+N2.h>

@interface CPRMPRView (CPRMPR)

- (CPRMPRIntersection*)intersectionForKey:(NSString*)key;

@end

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
@synthesize mouseDownLocation = _mouseDownLocation, mouseDownModifierFlags = _mouseDownModifierFlags, mouseDownGeneratorRequestSliceToDicomTransform = _mouseDownGeneratorRequestSliceToDicomTransform;
@synthesize blockGeneratorRequestUpdates = _blockGeneratorRequestUpdates;
@synthesize track = _track;

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
        if (self.track) [self removeTrackingArea:self.track];
        [self addTrackingArea:(self.track = [[[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseMoved+NSTrackingActiveInActiveApp+NSTrackingInVisibleRect owner:self userInfo:@{ @"CPRMPRViewTrackingArea": @YES }] autorelease])];
//        NSRect o = [change[NSKeyValueChangeOldKey] rectValue], n = [change[NSKeyValueChangeNewKey] rectValue];
//        CGFloat os = fmin(NSWidth(o), NSHeight(o)), ns = fmin(NSWidth(n), NSHeight(n));
//        NSLog(@"mprview resize: %@ -> %@", NSStringFromRect(o), NSStringFromRect(n));
//        self.pixelSpacing = self.pixelSpacing/ns*os;
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
    
    BOOL flag = (ikey && distance < 4);//, cmd = ((event.modifierFlags&NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask);
    
    if (flag) {
//        if (!cmd)
            [[NSCursor openHandCursor] set];
//        else [[self.class blueOpenHandCursor] set];
    }
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
        [[NSCursor closedHandCursor] set];
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
        [[NSCursor openHandCursor] set];
        self.mouseDownLocation = None;
        [self enumerateIntersectionsWithBlock:^(NSString* key, CPRIntersection* intersection, BOOL* stop) {
            intersection.maskAroundMouse = YES;
        }];
    }
}

/*+ (NSCursor*)blueOpenHandCursor {
    static NSCursor* cursor = nil;
    if (!cursor) {
        NSCursor* ohc = [NSCursor openHandCursor];
        cursor = [[NSCursor alloc] initWithImage:[self.class image:ohc.image colorify:[NSColor blueColor]] hotSpot:ohc.hotSpot];
    }
    
    return cursor;
}

+ (NSImage*)image:(NSImage*)image colorify:(NSColor*)color {
    NSBitmapImageRep* bitmap = [[image.representations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSImageRep* rep, NSDictionary* bindings) {
        return [rep isKindOfClass:NSBitmapImageRep.class];
    }]] lastObject];
    
    size_t pixelsWide = bitmap.pixelsWide, pixelsHigh = bitmap.pixelsHigh;
    CGRect rect = CGRectMake(0, 0, pixelsWide, pixelsHigh);
    
    NSBitmapImageRep* nbitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:<#(unsigned char **)#> pixelsWide:<#(NSInteger)#> pixelsHigh:<#(NSInteger)#> bitsPerSample:<#(NSInteger)#> samplesPerPixel:<#(NSInteger)#> hasAlpha:<#(BOOL)#> isPlanar:<#(BOOL)#> colorSpaceName:<#(NSString *)#> bitmapFormat:<#(NSBitmapFormat)#> bytesPerRow:<#(NSInteger)#> bitsPerPixel:<#(NSInteger)#>];
    

    size_t bitmapBytesPerRow = (pixelsWide * 4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextRef c = CGBitmapContextCreate(NULL, pixelsWide, pixelsHigh,
                                           8, bitmapBytesPerRow,
                                           colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    [image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    CGContextSetFillColorWithColor(c, [color CGColor]);
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    CGContextFillRect(c, rect);
    CGImageRef ciImage =  CGBitmapContextCreateImage(c);
    CGContextDrawImage(c, rect, ciImage);
    NSImage* newImage = [[[NSImage alloc] initWithCGImage:ciImage size:image.size] autorelease];
    CGContextRelease(c);
    CGImageRelease(ciImage);
    
    return newImage;
}*/

@end
