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

#import "NIProjectionOperation.h"
#include <Accelerate/Accelerate.h>
#import "NIVolumeData.h"

@implementation NIProjectionOperation

@synthesize volumeData = _volumeData;
@synthesize generatedVolume = _generatedVolume;
@synthesize projectionMode = _projectionMode;

- (id)init
{
    if ( (self = [super init]) ) {
        _projectionMode = NIProjectionModeNone;
    }
    return self;
}

- (void)dealloc
{
    [_volumeData release];
    _volumeData = nil;
    [_generatedVolume release];
    _generatedVolume = nil;
    [super dealloc];
}

- (void)main
{
    float *floatBytes;
    NSInteger i;
    float floati;
    NSInteger pixelsPerPlane;
    NIAffineTransform volumeTransform;
    NIVolumeDataInlineBuffer inlineBuffer;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    @try {
        if ([self isCancelled]) {
            return;
        }

        if (_projectionMode == NIProjectionModeNone) {
            _generatedVolume = [_volumeData retain];
            return;
        }

        pixelsPerPlane = _volumeData.pixelsWide * _volumeData.pixelsHigh;
        floatBytes = malloc(sizeof(float) * pixelsPerPlane);

        [_volumeData aquireInlineBuffer:&inlineBuffer];
        memcpy(floatBytes, NIVolumeDataFloatBytes(&inlineBuffer), sizeof(float) * pixelsPerPlane);
        switch (_projectionMode) {
            case NIProjectionModeMIP:
                for (i = 1; i < _volumeData.pixelsDeep; i++) {
                    if ([self isCancelled]) {
                        break;
                    }
                    vDSP_vmax(floatBytes, 1, (float *)NIVolumeDataFloatBytes(&inlineBuffer) + (i * pixelsPerPlane), 1, floatBytes, 1, pixelsPerPlane);
                }
                break;
            case NIProjectionModeMinIP:
                for (i = 1; i < _volumeData.pixelsDeep; i++) {
                    if ([self isCancelled]) {
                        break;
                    }
                    vDSP_vmin(floatBytes, 1, (float *)NIVolumeDataFloatBytes(&inlineBuffer) + (i * pixelsPerPlane), 1, floatBytes, 1, pixelsPerPlane);
                }
                break;
            case NIProjectionModeMean:
                for (i = 1; i < _volumeData.pixelsDeep; i++) {
                    if ([self isCancelled]) {
                        break;
                    }
                    floati = i;
                    vDSP_vavlin((float *)NIVolumeDataFloatBytes(&inlineBuffer) + (i * pixelsPerPlane), 1, &floati, floatBytes, 1, pixelsPerPlane);
                }
                break;
            default:
                break;
        }

        volumeTransform = NIAffineTransformConcat(_volumeData.volumeTransform, NIAffineTransformMakeScale(1.0, 1.0, 1.0/(CGFloat)_volumeData.pixelsDeep));
        _generatedVolume = [[NIVolumeData alloc] initWithBytesNoCopy:floatBytes pixelsWide:_volumeData.pixelsWide pixelsHigh:_volumeData.pixelsHigh pixelsDeep:1
                                                       volumeTransform:volumeTransform outOfBoundsValue:_volumeData.outOfBoundsValue freeWhenDone:YES];
    }
    @catch (...) {
    }
    @finally {
        [pool release];
    }
}

@end




