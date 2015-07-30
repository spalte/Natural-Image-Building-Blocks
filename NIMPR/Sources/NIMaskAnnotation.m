//
//  NIMaskAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/13/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMaskAnnotation.h"

@implementation NIMaskAnnotation

@synthesize mask = _mask;
@synthesize modelToDicomTransform = _modelToDicomTransform;

+ (NSSet*)keyPathsForValuesAffectingAnnotation {
    return [super.keyPathsForValuesAffectingAnnotation setByAddingObjects: @"mask", @"modelToDicomTransform", nil ];
}

- (id)initWithMask:(NIMask*)mask transform:(NIAffineTransform)modelToDicomTransform {
    if ((self = [super init])) {
        self.mask = mask;
        self.modelToDicomTransform = modelToDicomTransform;
    }
    
    return self;
}

- (void)dealloc {
    self.mask = nil;
    [super dealloc];
}

- (void)translate:(NIVector)translation {
    self.modelToDicomTransform = NIAffineTransformConcat(self.modelToDicomTransform, NIAffineTransformMakeTranslationWithVector(translation));
}

- (NSBezierPath*)drawInView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache layer:(CALayer*)layer context:(CGContextRef)ctx {
    // TODO: cache
    
    NIVolumeData* data = [self.mask volumeDataRepresentationWithVolumeTransform:self.modelToDicomTransform];
    
    NIVolumeData* sd = [NIGenerator synchronousRequestVolume:view.presentedGeneratorRequest volumeData:data];
    vImage_Buffer floatBuffer = [sd floatBufferForSliceAtIndex:0];
    
    unsigned char* bdp[1] = {floatBuffer.data};
    NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:bdp pixelsWide:floatBuffer.width pixelsHigh:floatBuffer.height bitsPerSample:sizeof(float)*8 samplesPerPixel:1
                                                                         hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bitmapFormat:NSFloatingPointSamplesBitmapFormat bytesPerRow:floatBuffer.rowBytes bitsPerPixel:sizeof(float)*8];
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext* context = [NSGraphicsContext currentContext];
    
    NSAffineTransform* t = [NSAffineTransform transform];
    [t translateXBy:0 yBy:bitmap.size.height];
    [t scaleXBy:1 yBy:-1];
    [t set];
    
    NSRect bounds = NSMakeRect(0, 0, bitmap.size.width, bitmap.size.height);
    CGContextClipToMask(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height), [bitmap CGImageForProposedRect:&bounds context:context hints:nil]);
    [self.color set];
    [context setCompositingOperation:NSCompositeSourceOver];
    CGContextFillRect(context.CGContext, CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height));

    //    [bitmap drawAtPoint:NSZeroPoint];
    
    [NSGraphicsContext restoreGraphicsState];
    
    return nil;
}

- (void)highlightWithColor:(NSColor*)color inView:(NIAnnotatedGeneratorRequestView*)view cache:(NSMutableDictionary*)cache layer:(CALayer*)layer context:(CGContextRef)ctx path:(NSBezierPath*)path {
    
}

- (CGFloat)distanceToSlicePoint:(NSPoint)point cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view closestPoint:(NSPoint*)rpoint {
   // NSLog(@"Warning: -[%@ distanceToSlicePoint:view:closestPoint:] is missing", self.className);
    return CGFLOAT_MAX;
}

- (BOOL)intersectsSliceRect:(NSRect)rect cache:(NSMutableDictionary*)cache view:(NIAnnotatedGeneratorRequestView*)view {
   // NSLog(@"Warning: -[%@ intersectsSliceRect:view:] is missing", self.className);
    return NO;
}

@end
