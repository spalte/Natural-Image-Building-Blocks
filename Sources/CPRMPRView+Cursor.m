//
//  CPRMPRView+Cursor.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRView+Cursor.h"

@implementation CPRMPRView (Cursor)

+ (NSCursor*)openHandCursor:(NSUInteger)flags {
    static NSMutableDictionary* cache = nil;
    if (!cache) cache = [[NSMutableDictionary alloc] init];
    return [self.class cursor:NSCursor.openHandCursor flags:flags cache:cache];
}

+ (NSCursor*)closedHandCursor:(NSUInteger)flags {
    static NSMutableDictionary* cache = nil;
    if (!cache) cache = [[NSMutableDictionary alloc] init];
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
