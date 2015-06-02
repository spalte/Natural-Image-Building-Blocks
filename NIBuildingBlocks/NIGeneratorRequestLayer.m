//  Created by Joël Spaltenstein on 4/3/15.
//  Copyright (c) 2015 Spaltenstein Natural Image
//  Copyright (c) 2015 Michael Hilker and Andreas Holzamer
//  Copyright (c) 2015 volz io
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


#import "NIGeneratorRequestLayer.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLContext.h>

#import "NIFloatImageRep.h"
#import "NIIntersection.h"
#import "NIIntersectionPrivate.h"

#import "NIVolumeData.h"
#import "NIGeneratorRequest.h"
#import "NIGenerator.h"

@interface NIGeneratorRequestLayer ()

@property (nonatomic, readwrite, retain) NIGeneratorRequest *presentedGeneratorRequest;
@property (nonatomic, readwrite, retain) NIFloatImageRep *presentedFloatImageRep;

@property (nonatomic, readwrite, retain) NIGeneratorRequest *cubicGeneratorRequest;
@property (nonatomic, readwrite, retain) NIFloatImageRep *cubicFloatImageRep;

@property (nonatomic, readwrite, retain) NIGeneratorRequest *fromGeneratorRequest;
@property (nonatomic, readwrite, retain) NIGeneratorRequest *toGeneratorRequest;
@property (nonatomic, readwrite, assign) CGFloat generatorRequestInterpolator;


- (void)_updateCubicTimer;
- (void)_updateCubic;


@end

@implementation NIGeneratorRequestLayer

@dynamic windowLevel;
@dynamic windowWidth;
@dynamic generatorRequestInterpolator;
@synthesize generatorRequest = _generatorRequest;
@synthesize fromGeneratorRequest = _fromGeneratorRequest;
@synthesize toGeneratorRequest = _toGeneratorRequest;
@synthesize presentedGeneratorRequest = _presentedGeneratorRequest;
@synthesize cubicGeneratorRequest = _cubicGeneratorRequest;
@synthesize cubicFloatImageRep = _cubicFloatImageRep;
@synthesize volumeData = _volumeData;
@synthesize preferredInterpolationMode = _preferredInterpolationMode;
@synthesize invert = _invert;
@synthesize CLUT = _CLUT;
@synthesize presentedFloatImageRep = _presentedFloatImageRep;

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"windowLevel"]) {
        return YES;
    } else if ([key isEqualToString:@"windowWidth"]) {
        return YES;
    } else if ([key isEqualToString:@"generatorRequestInterpolator"]) {
        return YES;
    } else {
        return [super needsDisplayForKey:key];
    }
}

+ (id)defaultValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"generatorRequestInterpolator"]) {
        return @(-1);
    } else if ([key isEqualToString:@"windowLevel"]) {
        return @(0);
    } else if ([key isEqualToString:@"windowWidth"]) {
        return @(1200);
    } else {
        return [super defaultValueForKey:key];
    }
}

- (void)dealloc
{
    [_presentedGeneratorRequest release];
    _presentedGeneratorRequest = nil;

    [_presentedFloatImageRep release];
    _presentedFloatImageRep = nil;

    [_generatorRequest release];
    _generatorRequest = nil;

    [_fromGeneratorRequest release];
    _fromGeneratorRequest = nil;

    [_toGeneratorRequest release];
    _toGeneratorRequest = nil;

    [_volumeData release];
    _volumeData = nil;

    [_CLUT release];
    _CLUT = nil;

    _cubicGenerator.delegate = nil;
    [_cubicGenerator release];
    _cubicGenerator = nil;

    [_updateCubicTimer invalidate];
    [_updateCubicTimer release];
    _updateCubicTimer = nil;

    [_cubicGeneratorRequest release];
    _cubicGeneratorRequest = nil;

    [_cubicFloatImageRep release];
    _cubicFloatImageRep = nil;

    [super dealloc];
}

- (id < CAAction >)actionForKey:(NSString *)key
{
    if ([key isEqualToString:@"windowLevel"] || [key isEqualToString:@"windowWidth"]) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:key];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        animation.fromValue = [self valueForKey:key];
        return animation;
    } else {
        return [super actionForKey:key];
    }
}

- (BOOL)needsDisplayOnBoundsChange
{
    return YES;
}

- (BOOL)isAsynchronous
{
    return NO;
}

- (void)setVolumeData:(NIVolumeData *)volumeData
{
    if (_volumeData != volumeData) {
        [_volumeData release];
        _volumeData = [volumeData retain];

        _cubicGenerator.delegate = nil;
        [_cubicGenerator release];
        _cubicGenerator = [[NIGenerator alloc] initWithVolumeData:_volumeData];
        _cubicGenerator.delegate = self;

        [self setNeedsDisplay];
    }
}

- (void)setPreferredInterpolationMode:(NIInterpolationMode)preferredInterpolationMode
{
    if (_preferredInterpolationMode != preferredInterpolationMode) {
        _preferredInterpolationMode = preferredInterpolationMode;

        [self setNeedsDisplay];
    }
}

- (void)setInvert:(BOOL)invert
{
    if (_invert != invert) {
        _invert = invert;

        [self setNeedsDisplay];
    }
}

- (void)setCLUT:(id)CLUT
{
    if ([_CLUT isEqual:CLUT] == NO) {
        [_CLUT release];
        _CLUT = [CLUT retain];

        [self setNeedsDisplay];
    }
}

- (void)setGeneratorRequest:(NIGeneratorRequest *)generatorRequest
{
    if (generatorRequest != _generatorRequest) {
        NIGeneratorRequest *oldGeneratorRequest = self.generatorRequest;
        [_generatorRequest autorelease];
        _generatorRequest = [generatorRequest retain];


        if ([CATransaction disableActions] == NO) {
            if ([self animationForKey:@"generatorRequestInterpolator"]) {
                CGFloat interpolator = [[self presentationLayer] generatorRequestInterpolator];
                if (interpolator != -1) {
                    self.fromGeneratorRequest = [self.fromGeneratorRequest interpolateBetween:self.toGeneratorRequest withWeight:interpolator];
                } else {
                    self.fromGeneratorRequest = oldGeneratorRequest;
                }
                self.toGeneratorRequest = generatorRequest;
                [self removeAnimationForKey:@"generatorRequestInterpolator"];
            } else {
                self.fromGeneratorRequest = oldGeneratorRequest;
                self.toGeneratorRequest = generatorRequest;
            }

            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"generatorRequestInterpolator"];
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
            animation.fromValue = @(0.0);
            animation.toValue = @(1.0);
            [self addAnimation:animation forKey:@"generatorRequestInterpolator"];
        } else {
            self.toGeneratorRequest = generatorRequest; // this is not typical behavior for core animation, but in this case the result if better
                                                        // this will make it so that if an animation is ongoing, the animation will be updated to
                                                        // go to the right place
            [self setNeedsDisplay];
        }
    }
}

- (void)_updateCubicTimer
{
    NSAssert(self == [self modelLayer], @"_updateCubicTimer not called on the model layer");

    if (_cubicGenerator == nil && _volumeData != nil) {
        _cubicGenerator = [[NIGenerator alloc] initWithVolumeData:_volumeData];
        _cubicGenerator.delegate = self;
    }

    if (_cubicGenerator == nil) {
        return;
    }

    [_updateCubicTimer invalidate];
    [_updateCubicTimer release];
    _updateCubicTimer = nil;

    NSInvocation *updateCubicInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(_updateCubic)]];
    [updateCubicInvocation setSelector:@selector(_updateCubic)];
    [updateCubicInvocation setTarget:self];

    _updateCubicTimer = [[NSTimer scheduledTimerWithTimeInterval:0.2 invocation:updateCubicInvocation repeats:NO] retain];
}

- (void)_updateCubic
{
    NSAssert(self == [self modelLayer], @"_updateCubic not called on the model layer");

    NIGeneratorRequest *cubicRequest = [[self.presentedGeneratorRequest copy] autorelease];
    if (cubicRequest) {
        cubicRequest.interpolationMode = NIInterpolationModeCubic;
        [_cubicGenerator requestVolume:cubicRequest];
    }
}

- (void)drawInCGLContext:(CGLContextObj)cgl_ctx pixelFormat:(CGLPixelFormatObj)pixelFormat forLayerTime:(CFTimeInterval)timeInterval displayTime:(const CVTimeStamp *)timeStamp
{
    NIGeneratorRequestLayer *presentationLayer = [self presentationLayer];
    NIGeneratorRequestLayer *modelLayer = [self modelLayer];

    NIInterpolationMode liveInterpolationMode = modelLayer.generatorRequest.interpolationMode == NIInterpolationModeNearestNeighbor ? NIInterpolationModeNearestNeighbor : NIInterpolationModeLinear;
    BOOL buildCubic = modelLayer.generatorRequest.interpolationMode == NIInterpolationModeCubic;
    if (self.preferredInterpolationMode != NIInterpolationModeNone) {
        liveInterpolationMode = self.preferredInterpolationMode == NIInterpolationModeNearestNeighbor ? NIInterpolationModeNearestNeighbor : NIInterpolationModeLinear;
        buildCubic = self.preferredInterpolationMode == NIInterpolationModeCubic;
    }

    if (self.preferredInterpolationMode == NIInterpolationModeNearestNeighbor) {
        liveInterpolationMode = NIInterpolationModeNearestNeighbor;
    }

    NIGeneratorRequest *requestToDraw = nil;

    if (presentationLayer == nil || presentationLayer.generatorRequestInterpolator == -1) {
        requestToDraw = modelLayer.generatorRequest;
    } else {
        requestToDraw = [modelLayer.fromGeneratorRequest interpolateBetween:modelLayer.toGeneratorRequest withWeight:presentationLayer.generatorRequestInterpolator];
    }

    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    if (requestToDraw == nil) {
        return;
    }
     
    if (presentationLayer == nil || presentationLayer.generatorRequestInterpolator == -1) {
        requestToDraw = [requestToDraw generatorRequestResizedToPixelsWide:modelLayer.bounds.size.width * modelLayer.contentsScale
                                                                pixelsHigh:modelLayer.bounds.size.height * modelLayer.contentsScale];
        requestToDraw.interpolationMode = liveInterpolationMode;
    } else {
        requestToDraw = [requestToDraw generatorRequestResizedToPixelsWide:modelLayer.bounds.size.width
                                                                pixelsHigh:modelLayer.bounds.size.height];
        requestToDraw.interpolationMode = NIInterpolationModeNearestNeighbor;
    }

    NIFloatImageRep *floatImageRepToDraw = nil;

    NIGeneratorRequest *cubicRequestToDraw = [[requestToDraw copy] autorelease];
    cubicRequestToDraw.interpolationMode = NIInterpolationModeCubic;

    if (buildCubic && [cubicRequestToDraw isEqual:modelLayer.presentedGeneratorRequest]) {
        floatImageRepToDraw = modelLayer.presentedFloatImageRep;
        requestToDraw = modelLayer.presentedGeneratorRequest;
    } else {
        if (buildCubic && [cubicRequestToDraw isEqual:modelLayer.cubicGeneratorRequest]) {
            floatImageRepToDraw = modelLayer.cubicFloatImageRep;
            requestToDraw = modelLayer.cubicGeneratorRequest;
        } else if ([requestToDraw isEqual:modelLayer.presentedGeneratorRequest]){
            floatImageRepToDraw = modelLayer.presentedFloatImageRep;
        } else {
            floatImageRepToDraw = [[NIGenerator synchronousRequestVolume:requestToDraw volumeData:modelLayer.volumeData] floatImageRepForSliceAtIndex:0];
        }
    }

    floatImageRepToDraw.windowLevel = presentationLayer ? presentationLayer.windowLevel : modelLayer.windowLevel;
    floatImageRepToDraw.windowWidth = presentationLayer ? presentationLayer.windowWidth : modelLayer.windowWidth;
    floatImageRepToDraw.invert = modelLayer.invert;
    floatImageRepToDraw.CLUT = modelLayer.CLUT;

    if ([modelLayer.presentedGeneratorRequest isEqual:requestToDraw] == NO) {
        modelLayer.presentedGeneratorRequest = requestToDraw;
    }

    if (modelLayer.presentedFloatImageRep != floatImageRepToDraw) {
        modelLayer.presentedFloatImageRep = floatImageRepToDraw;
    }

    if ([modelLayer.presentedGeneratorRequest isEqual:cubicRequestToDraw] == NO) {
        [modelLayer _updateCubicTimer];
    }

    glEnable(GL_TEXTURE_RECTANGLE_ARB);

    // load new textures
    glPixelStorei (GL_UNPACK_ROW_LENGTH, [floatImageRepToDraw pixelsWide]);
    glPixelStorei (GL_UNPACK_ALIGNMENT, 1);

    GLuint texture = 0;
    glGenTextures((GLuint)1, &texture);

    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, texture);
    glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    if (floatImageRepToDraw.CLUT == nil) {
        glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_LUMINANCE8, [floatImageRepToDraw pixelsWide], [floatImageRepToDraw pixelsHigh], 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, [floatImageRepToDraw windowedBytes]);
    } else {
        glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, [floatImageRepToDraw pixelsWide], [floatImageRepToDraw pixelsHigh], 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8_REV, [floatImageRepToDraw CLUTBytes]);
    }

    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, texture);

    glBegin (GL_QUADS);
    glTexCoord2f (0.0, [floatImageRepToDraw pixelsHigh]);
    glVertex3d (-1.0, 1.0, 0.0);

    glTexCoord2f (0.0, 0.0);
    glVertex3d (-1.0, -1.0, 0.0);

    glTexCoord2f ([floatImageRepToDraw pixelsWide], 0.0);
    glVertex3d (1.0, -1.0, 0.0);

    glTexCoord2f ([floatImageRepToDraw pixelsWide], [floatImageRepToDraw pixelsHigh]);
    glVertex3d (1.0, 1.0, 0.0);
    glEnd();

    [super drawInCGLContext:cgl_ctx pixelFormat:pixelFormat forLayerTime:timeInterval displayTime:timeStamp];

    glDeleteTextures(1, &texture);
    
    glDisable (GL_TEXTURE_RECTANGLE_ARB);
}

- (void)generator:(NIGenerator *)generator didGenerateVolume:(NIVolumeData *)volume request:(NIGeneratorRequest *)request
{
    NSAssert(self == [self modelLayer], @"generator:didGenerateVolume not called on the model layer");

    self.cubicGeneratorRequest = request;
    self.cubicFloatImageRep = [volume floatImageRepForSliceAtIndex:0];
    [self setNeedsDisplay];
}

- (CGPoint)convertPointFromDICOMVector:(NIVector)vector
{
    NIGeneratorRequest *generatorRequest = [(NIGeneratorRequestLayer *)self.modelLayer presentedGeneratorRequest];;

    if (generatorRequest == nil || generatorRequest.pixelsWide == 0 || generatorRequest.pixelsHigh == 0) {
        return CGPointZero;
    }

    CGPoint point = NSPointToCGPoint(NSPointFromNIVector([generatorRequest convertVolumeVectorFromDICOMVector:vector]));

    point.x += 0.5;
    point.y += 0.5;

    point.x *= self.bounds.size.width / (CGFloat)generatorRequest.pixelsWide;
    point.y *= self.bounds.size.height / (CGFloat)generatorRequest.pixelsHigh;

    return point;
}

- (NIVector)convertPointToDICOMVector:(CGPoint)point
{
    NIGeneratorRequest *generatorRequest = [(NIGeneratorRequestLayer *)self.modelLayer presentedGeneratorRequest];;

    if (generatorRequest == nil || self.bounds.size.width == 0 || self.bounds.size.height == 0) {
        return NIVectorZero;
    }

    point.x *= (CGFloat)generatorRequest.pixelsWide / self.bounds.size.width;
    point.y *= (CGFloat)generatorRequest.pixelsHigh / self.bounds.size.height;

    point.x -= .5;
    point.y -= .5;

    return [generatorRequest convertVolumeVectorToDICOMVector:NIVectorMake(point.x, point.y, 0)];
}


@end
