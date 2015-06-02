//  Created by Joël Spaltenstein on 4/24/15.
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

#import <Cocoa/Cocoa.h>

#import "NIMouseBullseyeLayer.h"

@implementation NIMouseBullseyeLayer

- (instancetype)init
{
    if ( (self = [super init]) ) {
        CGMutablePathRef path = CGPathCreateMutable();

        CGPathAddEllipseInRect(path, NULL, CGRectMake(0, 0, 16, 16));

        CGPathMoveToPoint(path, NULL, 8, 0);
        CGPathAddLineToPoint(path, NULL, 8, 4);

        CGPathMoveToPoint(path, NULL, 16, 8);
        CGPathAddLineToPoint(path, NULL, 12, 8);

        CGPathMoveToPoint(path, NULL, 8, 16);
        CGPathAddLineToPoint(path, NULL, 8, 12);

        CGPathMoveToPoint(path, NULL, 0, 8);
        CGPathAddLineToPoint(path, NULL, 4, 8);

        self.path = path;
        self.lineWidth = 1;
        self.strokeColor = [[NSColor whiteColor] CGColor];
        self.fillColor = [[NSColor clearColor] CGColor];

        CGPathRelease(path);
        self.bounds = CGRectMake(0, 0, 16, 16);
    }
    return self;
}

@end
