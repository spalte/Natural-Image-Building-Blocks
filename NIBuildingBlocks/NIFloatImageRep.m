//  Created by Joël Spaltenstein on 2/27/15.
//  Copyright (c) 2017 Spaltenstein Natural Image
//  Copyright (c) 2017 Michael Hilker and Andreas Holzamer
//  Copyright (c) 2017 volz io
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#include <Accelerate/Accelerate.h>

#import "NIFloatImageRep.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIFloatImageRep ()

- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (void)_buildCachedData;

@end

@implementation NIFloatImageRep

@synthesize windowWidth = _windowWidth;
@synthesize windowLevel = _windowLevel;
@synthesize invert = _invert;
@synthesize CLUT = _CLUT;

@synthesize sliceThickness = _sliceThickness;
@synthesize imageToModelTransform = _imageToModelTransform;

@synthesize curved = _curved;
@synthesize convertPointFromModelVectorBlock = _convertPointFromModelVectorBlock;
@synthesize convertPointToModelVectorBlock = _convertPointToModelVectorBlock;

@synthesize rimColor = _rimColor;
@synthesize rimThickness = _rimThickness;
@synthesize displayOrientationLabels = _displayOrientationLabels;
@synthesize displayScaleBar = _displayScaleBar;


- (instancetype)initWithData:(nullable NSData *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh
{
    if ( (self = [super init]) ) {
        [self setColorSpaceName:NSCustomColorSpace];

        if (data == NULL) {
            _floatData = [NSMutableData dataWithLength:pixelsWide * pixelsHigh * sizeof(float)];
            memset([_floatData mutableBytes], 0, pixelsWide * pixelsHigh * sizeof(float));
        } else {
            if ([data length] < sizeof(float)*pixelsWide*pixelsHigh) {
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"*** %s: The data parameter does not contain enough floats for the given width and height", __PRETTY_FUNCTION__] userInfo:nil];
            }
            _floatData = (NSMutableData *)[data retain];
        }

        [self setPixelsWide:pixelsWide];
        [self setPixelsHigh:pixelsHigh];
        [self setSize:NSMakeSize(pixelsWide, pixelsHigh)];
        _imageToModelTransform = NIAffineTransformIdentity;

        self.convertPointFromModelVectorBlock = ^NSPoint(NIVector vector){return NSPointFromNIVector(NIVectorApplyTransform(vector, NIAffineTransformInvert(NIAffineTransformIdentity)));};
        self.convertPointToModelVectorBlock = ^NIVector(NSPoint point){return NIVectorApplyTransform(NIVectorMakeFromNSPoint(point), NIAffineTransformIdentity);};
    }

    return self;
}

- (instancetype)initWithBytes:(nullable float *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh;
{
    NSMutableData *mutableData = nil;
    if (data == NULL) {
        mutableData = [NSMutableData dataWithLength:pixelsWide * pixelsHigh * sizeof(float)];
        memset([_floatData mutableBytes], 0, pixelsWide * pixelsHigh * sizeof(float));
    } else {
        mutableData = [NSMutableData dataWithBytes:data length:pixelsWide * pixelsHigh * sizeof(float)];
    }

    return [self initWithData:mutableData pixelsWide:pixelsWide pixelsHigh:pixelsHigh];
}

- (instancetype)initWithBytesNoCopy:(float *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh freeWhenDone:(BOOL)freeWhenDone;
{
    NSMutableData *mutableData = [NSMutableData dataWithBytesNoCopy:data length:pixelsWide * pixelsHigh * sizeof(float) freeWhenDone:freeWhenDone];

    return [self initWithData:mutableData pixelsWide:pixelsWide pixelsHigh:pixelsHigh];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    if ([coder allowsKeyedCoding]) {
        if ( (self = [super initWithCoder:coder]) ) {
            _floatData = [[coder decodeObjectOfClass:[NSData class] forKey:@"floatData"] retain];

            _windowLevel = [coder decodeDoubleForKey:@"windowLevel"];
            _windowWidth = [coder decodeDoubleForKey:@"windowWidth"];

            _invert = [coder decodeBoolForKey:@"invert"];
            _CLUT = [coder decodeObjectOfClasses:[NSSet setWithObjects:[NSColor class], [NSGradient class], nil] forKey:@"CLUT"];

            _sliceThickness = [coder decodeDoubleForKey:@"sliceThickness"];

            _curved = NO; // we can't encode curved planes
            _convertPointFromModelVectorBlock = NULL;
            _convertPointToModelVectorBlock = NULL;

            if ([coder containsValueForKey:@"imageToModelTransform"]) {
                _imageToModelTransform = [coder decodeNIAffineTransformForKey:@"imageToModelTransform"];
            } else {
                [NSException raise:NSInvalidUnarchiveOperationException format:@"*** %s: missing imageToModelTransform", __PRETTY_FUNCTION__];
            }

            if ([coder containsValueForKey:@"displayOrientationLabels"]) {
                _displayOrientationLabels = [coder decodeBoolForKey:@"displayOrientationLabels"];
            }
            if ([coder containsValueForKey:@"displayScaleBar"]) {
                _displayScaleBar = [coder decodeBoolForKey:@"displayScaleBar"];
            }            if ([coder containsValueForKey:@"rimColor"]) {
                _rimColor = [[coder decodeObjectForKey:@"rimColor"] retain];
                _rimThickness = [coder decodeDoubleForKey:@"rimThickness"];
            }
        }
    } else {
        [NSException raise:NSInvalidUnarchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder allowsKeyedCoding]) {
        if (_curved) {
            [NSException raise:NSInvalidArchiveOperationException format:@"*** %s: can't archive curved images", __PRETTY_FUNCTION__];
        }

        [aCoder encodeObject:_floatData forKey:@"floatData"];

        [aCoder encodeDouble:_windowLevel forKey:@"windowLevel"];
        [aCoder encodeDouble:_windowWidth forKey:@"windowWidth"];

        [aCoder encodeBool:_invert forKey:@"invert"];
        [aCoder encodeObject:_CLUT forKey:@"CLUT"];

        [aCoder encodeDouble:_sliceThickness forKey:@"sliceThickness"];

        [aCoder encodeNIAffineTransform:_imageToModelTransform forKey:@"imageToModelTransform"];

        if (self.displayOrientationLabels) {
            [aCoder encodeBool:self.displayOrientationLabels forKey:@"displayOrientationLabels"];
        }
        if (self.displayScaleBar) {
            [aCoder encodeBool:self.displayScaleBar forKey:@"displayScaleBar"];
        }
        if (self.rimColor && self.rimThickness > 0) {
            [aCoder encodeObject:self.rimColor forKey:@"rimColor"];
            [aCoder encodeDouble:self.rimThickness forKey:@"rimThickness"];
        }
    } else {
        [NSException raise:NSInvalidArchiveOperationException format:@"*** %s: only supports keyed coders", __PRETTY_FUNCTION__];
    }
}

- (void)dealloc
{
    [_floatData release];
    _floatData = nil;
    [_cachedWindowedData release];
    _cachedWindowedData = nil;
    [_cachedCLUTData release];
    _cachedCLUTData = nil;
    [_CLUT release];
    _CLUT = nil;

    [_convertPointFromModelVectorBlock release];
    _convertPointFromModelVectorBlock = nil;
    [_convertPointToModelVectorBlock release];
    _convertPointToModelVectorBlock = nil;

    [_rimColor release];
    _rimColor = nil;

    [super dealloc];
}

+ (NSString *)stringForOrientationVector:(NIVector)orientationVector
{
    NSString *orientationX = orientationVector.x < 0 ? NSLocalizedString( @"R", @"R: Right") : NSLocalizedString( @"L", @"L: Left");
    NSString *orientationY = orientationVector.y < 0 ? NSLocalizedString( @"A", @"A: Anterior") : NSLocalizedString( @"P", @"P: Posterior");
    NSString *orientationZ = orientationVector.z < 0 ? NSLocalizedString( @"I", @"I: Inferior") : NSLocalizedString( @"S", @"S: Superior");

#if CGFLOAT_IS_DOUBLE
    CGFloat absX = fabs(orientationVector.x);
    CGFloat absY = fabs(orientationVector.y);
    CGFloat absZ = fabs(orientationVector.z);
#else
    CGFloat absX = fabsf(orientationVector.x);
    CGFloat absY = fabsf(orientationVector.y);
    CGFloat absZ = fabsf(orientationVector.z);
#endif

    NSMutableString *orientationString = [NSMutableString string];

    NSInteger i;
    for (i = 0; i < 3; ++i)
    {
        if (absX>.2 && absX>=absY && absX>=absZ) {
            [orientationString appendString: orientationX]; absX=0;
        } else if (absY>.2 && absY>=absX && absY>=absZ) {
            [orientationString appendString: orientationY]; absY=0;
        } else if (absZ>.2 && absZ>=absX && absZ>=absY) {
            [orientationString appendString: orientationZ]; absZ=0;
        } else break;
    }

    return orientationString;
}

- (void)drawOrnamentsInRect:(NSRect)rect
{
    NIAffineTransform imageToModelTransform = self.imageToModelTransform;
    CGFloat bottomPadding = 0; // padding will increase as new objects such as the orientation labels, and other labes are drawn
    CGFloat leftPadding = 0;
    if (self.displayOrientationLabels && _curved == NO) {
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        shadow.shadowOffset = NSMakeSize(1, -1);
        shadow.shadowBlurRadius = 1;
        shadow.shadowColor = [NSColor blackColor];
        NSDictionary *drawingAttributes = @{NSShadowAttributeName          : shadow,
                                            NSForegroundColorAttributeName : [NSColor whiteColor],
                                            NSFontAttributeName            : [NSFont fontWithName:@"Helvetica" size:14]};

        NIVector rightVector = NIVectorNormalize(NIVectorMake(imageToModelTransform.m11, imageToModelTransform.m12, imageToModelTransform.m13));
        NSString *rightVectorString = [NIFloatImageRep stringForOrientationVector:rightVector];
        NSSize rightSize = [rightVectorString sizeWithAttributes:drawingAttributes];
        NSRect rightRect = NSMakeRect(NSMaxX(rect) - (rightSize.width + 7), NSMidY(rect) - rightSize.height/2.0, rightSize.width, rightSize.height);
        [rightVectorString drawInRect:rightRect withAttributes:drawingAttributes];

        NIVector topVector = NIVectorNormalize(NIVectorMake(imageToModelTransform.m21, imageToModelTransform.m22, imageToModelTransform.m23));
        NSString *topVectorString = [NIFloatImageRep stringForOrientationVector:topVector];
        NSSize topSize = [topVectorString sizeWithAttributes:drawingAttributes];
        NSRect topRect = NSMakeRect(NSMidX(rect) - topSize.width/2.0, NSMaxY(rect) - (topSize.height + 5), topSize.width, topSize.height);
        [topVectorString drawInRect:topRect withAttributes:drawingAttributes];

        NIVector leftVector = NIVectorInvert(rightVector);
        NSString *leftVectorString = [NIFloatImageRep stringForOrientationVector:leftVector];
        NSSize leftSize = [leftVectorString sizeWithAttributes:drawingAttributes];
        NSRect leftRect = NSMakeRect(NSMinX(rect) + 7, NSMidY(rect) - leftSize.height/2.0, leftSize.width, leftSize.height);
        [leftVectorString drawInRect:leftRect withAttributes:drawingAttributes];
        leftPadding += leftSize.width + 7;

        NIVector bottomVector = NIVectorInvert(topVector);
        NSString *bottomVectorString = [NIFloatImageRep stringForOrientationVector:bottomVector];
        NSSize bottomSize = [bottomVectorString sizeWithAttributes:drawingAttributes];
        NSRect bottomRect = NSMakeRect(NSMidX(rect) - bottomSize.width/2.0, NSMinY(rect) + 5, bottomSize.width, bottomSize.height);
        [bottomVectorString drawInRect:bottomRect withAttributes:drawingAttributes];
        bottomPadding += bottomSize.height + 5;
    }
    if (self.rimColor && self.rimThickness > 0) {
        [_rimColor set];
        CGFloat rimThickness = self.rimThickness;

        CGFloat squareSize = 12.0;
        NSBezierPath *bezierPath = [NSBezierPath bezierPath];
        [bezierPath moveToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
        [bezierPath lineToPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect))];
        [bezierPath lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
        [bezierPath lineToPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect))];
        [bezierPath closePath];

        [bezierPath moveToPoint:NSMakePoint(NSMinX(rect) + rimThickness, NSMinY(rect) + rimThickness)];
        [bezierPath lineToPoint:NSMakePoint(NSMinX(rect) + rimThickness, NSMaxY(rect) - rimThickness)];
        [bezierPath lineToPoint:NSMakePoint(NSMaxX(rect) - squareSize, NSMaxY(rect) - rimThickness)];
        [bezierPath lineToPoint:NSMakePoint(NSMaxX(rect) - squareSize, NSMaxY(rect) - squareSize)];
        [bezierPath lineToPoint:NSMakePoint(NSMaxX(rect) - rimThickness, NSMaxY(rect) - squareSize)];
        [bezierPath lineToPoint:NSMakePoint(NSMaxX(rect) - rimThickness, NSMinY(rect) + rimThickness)];

        [bezierPath fill];
    }
    if (self.displayScaleBar) {
        NSBezierPath *path = [NSBezierPath bezierPath];
        NSInteger i;

        CGFloat mmWide = NIVectorLength(NIVectorMake(imageToModelTransform.m11, imageToModelTransform.m12, imageToModelTransform.m13)) * self.pixelsWide;
        CGFloat pointsPerMM = rect.size.width / mmWide;

        [path moveToPoint:NSMakePoint(NSMidX(rect) - 25*pointsPerMM, bottomPadding + 3)];
        [path lineToPoint:NSMakePoint(NSMidX(rect) + 25*pointsPerMM, bottomPadding + 3)];
        for (i = 0; i <= 5; i++) {
            [path moveToPoint:NSMakePoint(NSMidX(rect) + ((CGFloat)i*10 - 25)*pointsPerMM, bottomPadding + 3)];
            [path lineToPoint:NSMakePoint(NSMidX(rect) + ((CGFloat)i*10 - 25)*pointsPerMM, bottomPadding + 3 + (i%5?5:8))];
        }

        CGFloat mmHight = NIVectorLength(NIVectorMake(imageToModelTransform.m21, imageToModelTransform.m22, imageToModelTransform.m23)) * self.pixelsHigh;
        pointsPerMM = rect.size.height / mmHight;

        [path moveToPoint:NSMakePoint(leftPadding + 3, NSMidY(rect) - 25*pointsPerMM)];
        [path lineToPoint:NSMakePoint(leftPadding + 3, NSMidY(rect) + 25*pointsPerMM)];
        for (i = 0; i <= 5; i++) {
            [path moveToPoint:NSMakePoint(leftPadding + 3, NSMidY(rect) + ((CGFloat)i*10 - 25)*pointsPerMM)];
            [path lineToPoint:NSMakePoint(leftPadding + 3 + (i%5?5:8), NSMidY(rect) + ((CGFloat)i*10 - 25)*pointsPerMM)];
        }

        [[NSColor greenColor] set];
        [path stroke];
    }
}

- (BOOL)drawInRect:(NSRect)rect
{
    [NSGraphicsContext saveGraphicsState];
    if (self.rimColor && self.rimThickness > 0) {
        [NSBezierPath clipRect:NSInsetRect(rect, 0.5, 0.5)]; // clipping with a tiny inset give a nicer rendering because it guarantees that rimPath is outside of the rendering of the image
    }
    [[self bitmapImageRep] drawInRect:rect];
    [NSGraphicsContext restoreGraphicsState];
    [self drawOrnamentsInRect:rect];
    return YES;
}

-(BOOL)draw
{
    [[self bitmapImageRep] draw];
    [self drawOrnamentsInRect:NSMakeRect(0, 0, self.size.width, self.size.height)];
    return YES;
}

- (void)setImageToModelTransform:(NIAffineTransform)imageToModelTransform
{
    _imageToModelTransform = imageToModelTransform;

    self.convertPointFromModelVectorBlock = ^NSPoint(NIVector vector){return NSPointFromNIVector(NIVectorApplyTransform(vector, NIAffineTransformInvert(imageToModelTransform)));};
    self.convertPointToModelVectorBlock = ^NIVector(NSPoint point){return NIVectorApplyTransform(NIVectorMakeFromNSPoint(point), imageToModelTransform);};
}

- (void)setWindowLevel:(CGFloat)windowLevel
{
    if (windowLevel != _windowLevel) {
        _windowLevel = windowLevel;

        [_cachedWindowedData release];
        _cachedWindowedData = nil;
        [_cachedCLUTData release];
        _cachedCLUTData = nil;
    }
}

- (void)setWindowWidth:(CGFloat)windowWidth
{
    if (windowWidth != _windowWidth) {
        _windowWidth = windowWidth;

        [_cachedWindowedData release];
        _cachedWindowedData = nil;
        [_cachedCLUTData release];
        _cachedCLUTData = nil;
    }
}

- (void)setInvert:(BOOL)invert
{
    if (_invert != invert) {
        _invert = invert;

        [_cachedWindowedData release];
        _cachedWindowedData = nil;
        [_cachedCLUTData release];
        _cachedCLUTData = nil;
    }
}

- (void)setCLUT:(nullable id)CLUT
{
    if (CLUT != nil && [CLUT isKindOfClass:[NSColor class]] == NO &&  [CLUT isKindOfClass:[NSGradient class]] == NO) {
        NSAssert(NO, @"CLUT is not an NSColor or NSGradient");
        return;
    }

    if ([_CLUT isEqual:CLUT] == NO) {
        [_CLUT release];
        _CLUT = [CLUT retain];

        [_cachedWindowedData release];
        _cachedWindowedData = nil;
        [_cachedCLUTData release];
        _cachedCLUTData = nil;
    }
}

- (nullable float *)floatBytes;
{
    [_cachedWindowedData release];  // if we grab the bytes, expect that we did it to modify the bytes
    _cachedWindowedData = nil;
    [_cachedCLUTData release];
    _cachedCLUTData = nil;

    return (float *)[_floatData bytes];
}

- (nullable const unsigned char *)windowedBytes
{
    [self _buildCachedData];

    return [_cachedWindowedData bytes];
}

- (nullable const unsigned char *)CLUTBytes;
{
    [self _buildCachedData];

    return [_cachedCLUTData bytes];
}


- (nullable NSData *)floatData
{
    return _floatData;
}

- (nullable NSData *)windowedData
{
    [self _buildCachedData];

    return _cachedWindowedData;
}

- (nullable NSData *)CLUTData
{
    [self _buildCachedData];

    return _cachedCLUTData;
}

- (nullable NSBitmapImageRep *)bitmapImageRep // NSBitmapImageRep of the data after windowing, inverting, and applying the CLUT.
{
    [self _buildCachedData];
    NSInteger i;

    if (_CLUT == nil) { // no CLUT to apply make a grayscale image
        NSBitmapImageRep *windowedBitmapImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:[self pixelsWide] pixelsHigh:[self pixelsHigh]
                                                                                        bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:YES colorSpaceName:NSDeviceWhiteColorSpace
                                                                                          bytesPerRow:[self pixelsWide] bitsPerPixel:8];
        for (i = 0; i < [self pixelsHigh]; i++) {
            memcpy([windowedBitmapImageRep bitmapData] + (i * [windowedBitmapImageRep bytesPerRow]), [_cachedWindowedData bytes] + (([self pixelsHigh] - (i + 1)) * [windowedBitmapImageRep bytesPerRow]), [windowedBitmapImageRep bytesPerRow]);
        }
        return [windowedBitmapImageRep autorelease];
    } else {
        NSBitmapImageRep *clutBitmapImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:[self pixelsWide] pixelsHigh:[self pixelsHigh]
                                                                                    bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace
                                                                                     bitmapFormat:NSAlphaNonpremultipliedBitmapFormat bytesPerRow:[self pixelsWide] * 4 bitsPerPixel:32];
        for (i = 0; i < [self pixelsHigh]; i++) {
            memcpy([clutBitmapImageRep bitmapData] + (i * [clutBitmapImageRep bytesPerRow]), [_cachedCLUTData bytes] + (([self pixelsHigh] - (i + 1)) * [clutBitmapImageRep bytesPerRow]), [clutBitmapImageRep bytesPerRow]);
        }
        return [clutBitmapImageRep autorelease];
    }
}

- (void)_buildCachedData
{
    float *workingFloats = nil;

    if (_cachedWindowedData == nil) {
        NSUInteger pixelCount = [self pixelsHigh] * [self pixelsWide];
        _cachedWindowedData = [[NSMutableData alloc] initWithLength:pixelCount];

        float *floatBytes = (float *)[_floatData bytes];
        unsigned char *grayBytes = [_cachedWindowedData mutableBytes];
        workingFloats = malloc(pixelCount * sizeof(float));

        float twoFiftyFive = 255.0;
        float negOne = -1.0;

        // adjust the window level and width according to the DICOM docs (Part 3 C.11.2.1.2)
        if (_windowWidth > 1) { // regular case
            float float1 = 255.0/(_windowWidth - 1.0);
            float float2 = 127.5 - (((255.0 * _windowLevel) - 127.5) / (_windowWidth - 1.0));

            vDSP_vsmsa(floatBytes, 1, &float1, &float2, workingFloats, 1, pixelCount);

            float lowClip = 0;
            float highClip = 255;
            vDSP_vclip(workingFloats, 1, &lowClip, &highClip, workingFloats, 1, pixelCount);

            if (_invert) {
                vDSP_vsmsa(workingFloats, 1, &negOne, &twoFiftyFive, workingFloats, 1, pixelCount);
            }

            vDSP_vfixru8(workingFloats, 1, grayBytes, 1, pixelCount);

            if (_CLUT) {
                float oneOverTwoFiftyFive = 1.0/255.0;
                vDSP_vsmul(workingFloats, 1, &oneOverTwoFiftyFive, workingFloats, 1, pixelCount);
            }
        } else { // just do a binary threshold
            float thres = 0.5 - _windowLevel;
            float c = -127.5;
            float add = 127.5;
            vDSP_vsmul(floatBytes, 1, &negOne, workingFloats, 1, pixelCount);
            vDSP_vthrsc(workingFloats, 1, &thres, &c, workingFloats, 1, pixelCount);
            vDSP_vsadd(workingFloats, 1, &add, workingFloats, 1, pixelCount);

            if (_invert) {
                vDSP_vsmsa(workingFloats, 1, &negOne, &twoFiftyFive, workingFloats, 1, pixelCount);
            }

            vDSP_vfixu8(workingFloats, 1, grayBytes, 1, pixelCount);

            if (_CLUT) {
                float oneOverTwoFiftyFive = 1.0/255.0;
                vDSP_vsmul(workingFloats, 1, &oneOverTwoFiftyFive, workingFloats, 1, pixelCount);
            }
        }
    }

    if (_CLUT && _cachedCLUTData == nil) {
        NSUInteger pixelCount = [self pixelsHigh] * [self pixelsWide];
        _cachedCLUTData = [[NSMutableData alloc] initWithLength:pixelCount * 4];

        if ([_CLUT isKindOfClass:[NSColor class]]) {
            NSColor *clutColor = [(NSColor *)_CLUT colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            float redComponent = [clutColor redComponent] * [clutColor alphaComponent] * 255.0;
            float greenComponent = [clutColor greenComponent] * [clutColor alphaComponent] * 255.0;
            float blueComponent = [clutColor blueComponent] * [clutColor alphaComponent] * 255.0;
            float alphaComponent = [clutColor alphaComponent] * 255.0;
            float *scaledFloat = malloc(pixelCount * sizeof(float));

            vDSP_vsmul(workingFloats, 1, &redComponent, scaledFloat, 1, pixelCount);
            vDSP_vfixu8(scaledFloat, 1, [_cachedCLUTData mutableBytes] + 0, 4, pixelCount);

            vDSP_vsmul(workingFloats, 1, &greenComponent, scaledFloat, 1, pixelCount);
            vDSP_vfixu8(scaledFloat, 1, [_cachedCLUTData mutableBytes] + 1, 4, pixelCount);

            vDSP_vsmul(workingFloats, 1, &blueComponent, scaledFloat, 1, pixelCount);
            vDSP_vfixu8(scaledFloat, 1, [_cachedCLUTData mutableBytes] + 2, 4, pixelCount);

            vDSP_vsmul(workingFloats, 1, &alphaComponent, scaledFloat, 1, pixelCount);
            vDSP_vfixu8(scaledFloat, 1, [_cachedCLUTData mutableBytes] + 3, 4, pixelCount);
            
            free(scaledFloat);
        } else if ([_CLUT isKindOfClass:[NSGradient class]]) {
            NSGradient *gradient = (NSGradient *)_CLUT;

            NSBitmapImageRep *lookupTableBitmapImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:4096 pixelsHigh:1
                                                                                                bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace
                                                                                                  bytesPerRow:4096 * 4 bitsPerPixel:32];
            NSGraphicsContext *lookupTableGraphicsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:lookupTableBitmapImageRep];

            [NSGraphicsContext saveGraphicsState];
            [NSGraphicsContext setCurrentContext:lookupTableGraphicsContext];
            [lookupTableGraphicsContext setCompositingOperation:NSCompositeCopy];
            [gradient drawInRect:NSMakeRect(0, 0, 4096, 1) angle:0];
            [lookupTableGraphicsContext flushGraphics];
            [NSGraphicsContext restoreGraphicsState];

            vImage_Buffer lookup;
            lookup.data = [lookupTableBitmapImageRep bitmapData];
            lookup.height = 1;
            lookup.width = 4096;
            lookup.rowBytes = 4096 * 4;
            vImage_Buffer lookup_red;
            lookup_red.data = malloc(4096);
            lookup_red.height = 1;
            lookup_red.width = 4096;
            lookup_red.rowBytes = 4096;
            vImage_Buffer lookup_green;
            lookup_green.data = malloc(4096);
            lookup_green.height = 1;
            lookup_green.width = 4096;
            lookup_green.rowBytes = 4096;
            vImage_Buffer lookup_blue;
            lookup_blue.data = malloc(4096);
            lookup_blue.height = 1;
            lookup_blue.width = 4096;
            lookup_blue.rowBytes = 4096;
            vImage_Buffer lookup_alpha;
            lookup_alpha.data = malloc(4096);
            lookup_alpha.height = 1;
            lookup_alpha.width = 4096;
            lookup_alpha.rowBytes = 4096;

            // extract the planes of the lookup table
            vImage_Error error = kvImageNoError;

            error = vImageConvert_ARGB8888toPlanar8(&lookup, &lookup_red, &lookup_green, &lookup_blue, &lookup_alpha, 0);
            if (error != kvImageNoError) {
                NSLog(@"vImageConvert_ARGB8888toPlanar8 error %d", (int)error);
            }

            vImage_Buffer windowed;
            windowed.data = workingFloats;
            windowed.height = [self pixelsHigh];
            windowed.width = [self pixelsWide];
            windowed.rowBytes = [self pixelsWide] * 4;
            vImage_Buffer clut;
            clut.data = [_cachedCLUTData mutableBytes];
            clut.height = [self pixelsHigh];
            clut.width = [self pixelsWide];
            clut.rowBytes = [self pixelsWide] * 4;
            vImage_Buffer clut_red;
            clut_red.data = malloc(pixelCount);
            clut_red.height = [self pixelsHigh];
            clut_red.width = [self pixelsWide];
            clut_red.rowBytes = [self pixelsWide];
            vImage_Buffer clut_green;
            clut_green.data = malloc(pixelCount);
            clut_green.height = [self pixelsHigh];
            clut_green.width = [self pixelsWide];
            clut_green.rowBytes = [self pixelsWide];
            vImage_Buffer clut_blue;
            clut_blue.data = malloc(pixelCount);
            clut_blue.height = [self pixelsHigh];
            clut_blue.width = [self pixelsWide];
            clut_blue.rowBytes = [self pixelsWide];
            vImage_Buffer clut_alpha;
            clut_alpha.data = malloc(pixelCount);
            clut_alpha.height = [self pixelsHigh];
            clut_alpha.width = [self pixelsWide];
            clut_alpha.rowBytes = [self pixelsWide];

            error = vImageLookupTable_PlanarFtoPlanar8(&windowed, &clut_red, lookup_red.data, 0);
            if (error != kvImageNoError) {
                NSLog(@"vImageLookupTable_PlanarFtoPlanar8 error %d", (int)error);
            }
            error = vImageLookupTable_PlanarFtoPlanar8(&windowed, &clut_green, lookup_green.data, 0);
            if (error != kvImageNoError) {
                NSLog(@"vImageLookupTable_PlanarFtoPlanar8 error %d", (int)error);
            }
            error = vImageLookupTable_PlanarFtoPlanar8(&windowed, &clut_blue, lookup_blue.data, 0);
            if (error != kvImageNoError) {
                NSLog(@"vImageLookupTable_PlanarFtoPlanar8 error %d", (int)error);
            }
            error = vImageLookupTable_PlanarFtoPlanar8(&windowed, &clut_alpha, lookup_alpha.data, 0);
            if (error != kvImageNoError) {
                NSLog(@"vImageLookupTable_PlanarFtoPlanar8 error %d", (int)error);
            }
            
            error = vImageConvert_Planar8toARGB8888(&clut_red, &clut_green, &clut_blue, &clut_alpha, &clut, 0);
            if (error != kvImageNoError) {
                NSLog(@"vImageConvert_Planar8toARGB8888 error %d", (int)error);
            }

            [lookupTableBitmapImageRep release];

            free(lookup_red.data);
            free(lookup_green.data);
            free(lookup_blue.data);
            free(lookup_alpha.data);
            free(clut_red.data);
            free(clut_green.data);
            free(clut_blue.data);
            free(clut_alpha.data);
        }
    }

    free(workingFloats);
}

- (NSPoint)convertPointFromModelVector:(NIVector)vector
{
    return self.convertPointFromModelVectorBlock(vector);
}

- (NIVector)convertPointToModelVector:(NSPoint)point
{
    return self.convertPointToModelVectorBlock(point);
}


@end


@implementation NIVolumeData(NIFloatImageRepAdditions)
- (NIFloatImageRep *)floatImageRepForSliceAtIndex:(NSUInteger)z
{
    NIFloatImageRep *sliceImageRep;
    NSData *sliceData;

    if (z >= _pixelsDeep) {
        [NSException raise:@"NIVolumeData Out Of Bounds" format:@"z is out of bounds"];
    }

    NIVolumeDataInlineBuffer inlineBuffer;

    [self acquireInlineBuffer:&inlineBuffer];
    const float *floatPtr = NIVolumeDataFloatBytes(&inlineBuffer);

    if (z == 0 && _pixelsDeep == 1) {
        sliceData = [self floatData];
    } else {
        sliceData = [NSData dataWithBytes:floatPtr + (self.pixelsWide*self.pixelsHigh*z) length:self.pixelsWide * self.pixelsHigh * sizeof(float)];
    }
    sliceImageRep = [[NIFloatImageRep alloc] initWithData:sliceData pixelsWide:self.pixelsWide pixelsHigh:self.pixelsHigh];
    sliceImageRep.sliceThickness = self.pixelSpacingZ;
    sliceImageRep.imageToModelTransform = NIAffineTransformConcat(NIAffineTransformMakeTranslation(0.0, 0.0, (CGFloat)z), NIAffineTransformInvert(_modelToVoxelTransform));

    if (self.curved) {
        NIVector (^convertVolumeVectorFromModelVectorBlock)(NIVector) = self.convertVolumeVectorFromModelVectorBlock;
        NIVector (^convertVolumeVectorToModelVectorBlock)(NIVector) = self.convertVolumeVectorToModelVectorBlock;

        sliceImageRep.convertPointFromModelVectorBlock = ^NSPoint(NIVector vector) {return NSPointFromNIVector(convertVolumeVectorFromModelVectorBlock(vector));};
        sliceImageRep.convertPointToModelVectorBlock = ^NIVector(NSPoint point) {return convertVolumeVectorToModelVectorBlock(NIVectorMake(point.x, point.y, z));};
        sliceImageRep.curved = YES;
    }

    return [sliceImageRep autorelease];
}

@end

NS_ASSUME_NONNULL_END


