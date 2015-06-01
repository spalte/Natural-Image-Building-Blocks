//  Copyright (c) 2015 OsiriX Foundation
//  Copyright (c) 2015 Spaltenstein Natural Image
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

#import <Cocoa/Cocoa.h>
#import "NIBBGeometry.h"

@interface NIBBUnsignedInt16ImageRep : NSImageRep {
    uint16_t *_unsignedInt16Data;
    
    CGFloat _offset;
    CGFloat _slope;
    
    CGFloat _windowWidth;
    CGFloat _windowLevel;
    CGFloat _pixelSpacingX;
    CGFloat _pixelSpacingY;
    CGFloat _sliceThickness;
    
    NIBBAffineTransform _imageToDicomTransform;
    
    BOOL _freeWhenDone;
}

@property (nonatomic, readwrite, assign) CGFloat windowWidth; // these will affect how this rep will draw when part of an NSImage
@property (nonatomic, readwrite, assign) CGFloat windowLevel;


- (id)initWithData:(uint16_t *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh;

- (uint16_t *)unsignedInt16Data;
@property (nonatomic, readwrite, assign) CGFloat offset;
@property (nonatomic, readwrite, assign) CGFloat slope;
@property (nonatomic, readwrite, assign) CGFloat pixelSpacingX;
@property (nonatomic, readwrite, assign) CGFloat pixelSpacingY;
@property (nonatomic, readwrite, assign) CGFloat sliceThickness;

@property (nonatomic, readwrite, assign) NIBBAffineTransform imageToDicomTransform;

@end

@interface NIBBUnsignedInt16ImageRep (DCMPixAndVolume)

- (void)getOrientation:(float[6])orientation;
- (void)getOrientationDouble:(double[6])orientation;

@property (readonly) float originX;
@property (readonly) float originY;
@property (readonly) float originZ;

@end


