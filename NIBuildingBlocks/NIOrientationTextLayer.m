//  Created by Joël Spaltenstein on 4/19/15.
//  Copyright (c) 2016 Spaltenstein Natural Image
//  Copyright (c) 2016 Michael Hilker and Andreas Holzamer
//  Copyright (c) 2016 volz io
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


#import "NIOrientationTextLayer.h"

@implementation NIOrientationTextLayer

@synthesize orientationVector = _orientationVector;

- (void)setOrientationVector:(NIVector)orientationVector
{
    NSInteger i;   

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

    self.annotationString = orientationString;
}

@end






