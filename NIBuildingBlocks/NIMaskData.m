//  Copyright (c) 2016 Spaltenstein Natural Image
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

/*=========================================================================
 Program:   OsiriX

 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL

 See http://www.osirix-viewer.com/copyright.html for details.

 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/


#import "NIMaskData.h"
#import "NIVolumeData.h"
#include <Accelerate/Accelerate.h>

@implementation NIMaskData

@synthesize mask = _mask;
@synthesize volumeData = _volumeData;

- (id)initWithMask:(NIMask *)mask volumeData:(NIVolumeData *)volumeData
{
	if ( (self = [super init]) ) {
		_mask = [mask retain];
		_volumeData = [volumeData retain];
        _valueCache = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[_mask release];
	_mask = nil;
	[_volumeData release];
	_volumeData = nil;
	[_floatData release];
	_floatData = nil;
	[_valueCache release];
	_valueCache = nil;
	[super dealloc];
}

- (float)intensityMean
{
	NSUInteger floatCount = [self floatCount];
	float mean;
    
    @synchronized(self) {
        NSNumber *meanNumber = [_valueCache objectForKey:@"intensityMean"];
        if (meanNumber) {
            return [meanNumber floatValue];
        }
        
        if (floatCount == 0) {
            return NAN;
        }
        
        floatCount = [self floatCount];
        vDSP_meanv((float *)[[self floatData] bytes], 1, &mean, floatCount);
        
        [_valueCache setObject:[NSNumber numberWithFloat:mean] forKey:@"intensityMean"];
    }
    
	return mean;
}

- (float)meanIntensity // legacy support
{
    return [self intensityMean];
}

- (float)intensityMax
{
    float max;
    
    [self getIntensityMinimum:NULL firstQuartile:NULL secondQuartile:NULL thirdQuartile:NULL maximum:&max];
    return max;
}

- (float)maxIntensity // legacy support
{
    return [self intensityMax];
}

- (float)intensityMin
{
    float min;
    
    [self getIntensityMinimum:&min firstQuartile:NULL secondQuartile:NULL thirdQuartile:NULL maximum:NULL];
    return min;
}

- (float)minIntensity // legacy support
{
    return [self intensityMin];
}

- (float)intensityMedian
{
    float median;
    
    [self getIntensityMinimum:NULL firstQuartile:NULL secondQuartile:&median thirdQuartile:NULL maximum:NULL];
    return median;
}

- (void)getIntensityMinimum:(float *)minimum firstQuartile:(float *)firstQuartile secondQuartile:(float *)secondQuartile thirdQuartile:(float *)thirdQuartile maximum:(float *)maximum
{
    NSUInteger floatCount = [self floatCount];
    NSUInteger Q1Index;
    NSUInteger Q2Index;
    NSUInteger Q3Index;
    NSUInteger Q3StartIndex;
    NSUInteger QLength;
    
    float Q1;
    float Q2;
    float Q3;
    
    @synchronized(self) {
        NSNumber *minimumNumber = [_valueCache objectForKey:@"intesityMinimum"];
        NSNumber *Q1Number = [_valueCache objectForKey:@"intesityFirstQuartile"];
        NSNumber *Q2Number = [_valueCache objectForKey:@"intesitySecondQuartile"];
        NSNumber *Q3Number = [_valueCache objectForKey:@"intesityThirdQuartile"];
        NSNumber *maximumNumber = [_valueCache objectForKey:@"intesityMaximum"];
        
        if (minimumNumber && Q1Number && Q2Number && Q3Number && maximumNumber) {
            if (minimum) {
                *minimum = [minimumNumber floatValue];
            }
            if (firstQuartile) {
                *firstQuartile = [Q1Number floatValue];
            }
            if (secondQuartile) {
                *secondQuartile = [Q2Number floatValue];
            }
            if (thirdQuartile) {
                *thirdQuartile = [Q3Number floatValue];
            }
            if (maximum) {
                *maximum = [maximumNumber floatValue];
            }
            return;
        }
        
        if (floatCount == 0) {
            if (minimum) {
                *minimum = NAN;
            }
            if (firstQuartile) {
                *firstQuartile = NAN;
            }
            if (secondQuartile) {
                *secondQuartile = NAN;
            }
            if (thirdQuartile) {
                *thirdQuartile = NAN;
            }
            if (maximum) {
                *maximum = NAN;
            }
            return;
        } else if (floatCount == 1) {
            float intensity = ((float *)[[self floatData] bytes])[0];
            if (minimum) {
                *minimum = intensity;
            }
            if (firstQuartile) {
                *firstQuartile = intensity;
            }
            if (secondQuartile) {
                *secondQuartile = intensity;
            }
            if (thirdQuartile) {
                *thirdQuartile = intensity;
            }
            if (maximum) {
                *maximum = intensity;
            }
            return;
        }
        
        float *sorted = malloc(floatCount * sizeof(float));
        memcpy(sorted, [[self floatData] bytes], floatCount * sizeof(float));
        vDSP_vsort(sorted, floatCount, 1);
        
        if (floatCount % 2) { // floatCount is odd
            Q2Index = (floatCount - 1) / 2;
            Q3StartIndex = Q2Index + 1;
            Q2 = sorted[Q2Index];
        } else {
            Q2Index = floatCount/2;
            Q3StartIndex = Q2Index;
            Q2 = (sorted[Q2Index] + sorted[Q2Index - 1]) / 2.0f;
        }
        QLength = Q2Index;
        
        if (QLength % 2) {
            Q1Index = (QLength - 1) / 2;
            Q1 = sorted[Q1Index];
            
            Q3Index = Q1Index + Q3StartIndex;
            Q3 = sorted[Q3Index];
        } else {
            Q1Index = QLength/2;
            Q1 = (sorted[Q1Index] + sorted[Q1Index - 1]) / 2.0f;
            
            Q3Index = Q1Index + Q3StartIndex;
            Q3 = (sorted[Q3Index] + sorted[Q3Index - 1]) / 2.0f;
        }
        
        [_valueCache setObject:[NSNumber numberWithFloat:sorted[0]] forKey:@"intesityMinimum"];
        [_valueCache setObject:[NSNumber numberWithFloat:Q1] forKey:@"intesityFirstQuartile"];
        [_valueCache setObject:[NSNumber numberWithFloat:Q2] forKey:@"intesitySecondQuartile"];
        [_valueCache setObject:[NSNumber numberWithFloat:Q3] forKey:@"intesityThirdQuartile"];
        [_valueCache setObject:[NSNumber numberWithFloat:sorted[floatCount - 1]] forKey:@"intesityMaximum"];
        
        if (minimum) {
            *minimum = sorted[0];
        }
        if (firstQuartile) {
            *firstQuartile = Q1;
        }
        if (secondQuartile) {
            *secondQuartile = Q2;
        }
        if (thirdQuartile) {
            *thirdQuartile = Q3;
        }
        if (maximum) {
            *maximum = sorted[floatCount - 1];
        }
        
        free( sorted);
    }
}

- (float)intensityInterQuartileRange
{
    float Q1;
    float Q3;
    [self getIntensityMinimum:NULL firstQuartile:&Q1 secondQuartile:NULL thirdQuartile:&Q3 maximum:NULL];
    return Q3-Q1;
}

- (float)intensityStandardDeviation
{
    float negativeMean = -[self meanIntensity];
    float stdDev;
    float unscaledStdDev;
    NSUInteger floatCount = [self floatCount];
    
    @synchronized(self) {
        NSNumber *standardDeviationNumber = [_valueCache objectForKey:@"intensityStandardDeviation"];
        if (standardDeviationNumber) {
            return [standardDeviationNumber floatValue];
        }
        
        if (floatCount == 0) {
            return NAN;
        }
        
        float *scrap1 = malloc(floatCount * sizeof(float));
        float *scrap2 = malloc(floatCount * sizeof(float));
        
        vDSP_vsadd((float *)[[self floatData] bytes], 1, &negativeMean, scrap1, 1, floatCount);
        vDSP_vsq(scrap1, 1, scrap2, 1, floatCount);
        vDSP_sve(scrap2, 1, &unscaledStdDev, floatCount);
        
        free(scrap1);
        free(scrap2);
        
        stdDev = sqrtf(unscaledStdDev / (float)floatCount);
        
        [_valueCache setObject:[NSNumber numberWithFloat:stdDev] forKey:@"intensityStandardDeviation"];
    }
    
    return stdDev;
}

- (NSUInteger)floatCount
{
    NSUInteger floatCount;
    @synchronized(self) {
        if (_floatData) {
            return [_floatData length] / sizeof(float);
        }

        NIMaskRun *maskRuns = (NIMaskRun *)[[_mask maskRunsData] bytes];
        NSInteger i;

        floatCount = 0;
        for (i = 0; i < [_mask maskRunCount]; i++) {
            floatCount += maskRuns[i].widthRange.length;
        }
    }
    return floatCount;
}

- (NSUInteger)getFloatData:(float *)buffer floatCount:(NSUInteger)count
{
    NSUInteger bytesCopied;
    @synchronized(self) {
        bytesCopied = MIN(count, [[self floatData] length] / sizeof(float));
        [[self floatData] getBytes:buffer length:[[self floatData] length]];
    }
    return bytesCopied;
}

- (NSData *)floatData
{
    @synchronized(self) {
        if (_floatData) {
            return _floatData;
        }

        NSUInteger floatCount = [self floatCount];

        if (floatCount == 0) {
            _floatData = [[NSData alloc] init];
            return _floatData;
        }
        
        NIMaskRun *maskRuns = (NIMaskRun *)[[_mask maskRunsData] bytes];
        NSInteger i;
//        float *buffer;
        float *runBuffer;
        float *floatBuffer;

        floatBuffer = malloc(floatCount * sizeof(float));
        memset(floatBuffer, 0, floatCount * sizeof(float));

        runBuffer = floatBuffer;
        for (i = 0; i < [_mask maskRunCount]; i++) {
            [_volumeData getFloatRun:runBuffer atPixelCoordinateX:maskRuns[i].widthRange.location y:maskRuns[i].heightIndex z:maskRuns[i].depthIndex length:maskRuns[i].widthRange.length];
            runBuffer += maskRuns[i].widthRange.length;
        }
        
        _floatData = [[NSData alloc] initWithBytesNoCopy:floatBuffer length:floatCount * sizeof(float) freeWhenDone:YES];
    }
    return _floatData;
}

- (NSString*)description {
    float min, max, mean = [self intensityMean], sd = [self intensityStandardDeviation], median = [self intensityMedian];
    [self getIntensityMinimum:&min firstQuartile:NULL secondQuartile:NULL thirdQuartile:NULL maximum:&max];
    return [NSString stringWithFormat:@"<%@: 0x%lX min: %@, max: %@, mean: %@, sd: %@, median: %@>", self.className, (unsigned long)self, @(min), @(max), @(mean), @(sd), @(median)];
}

@end
