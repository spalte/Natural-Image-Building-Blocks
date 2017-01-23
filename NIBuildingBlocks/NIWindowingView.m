//  Created by Joël Spaltenstein on 6/5/15.
//  Copyright (c) 2017 Spaltenstein Natural Image
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

#import "NIWindowingView.h"

@implementation NIWindowingView

@synthesize windowLevel = _windowLevel;
@synthesize windowWidth = _windowWidth;

- (void)mouseDown:(NSEvent *)theEvent
{
    _clickPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    _clickWindowLevel = _windowLevel;
    _clickWindowWidth = _windowWidth;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint dragPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    self.windowLevel = _clickWindowLevel + (dragPoint.y - _clickPoint.y)*10.0;
    self.windowWidth = MAX(_clickWindowWidth + (dragPoint.x - _clickPoint.x)*10.0, 0);
}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSPoint dragPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    self.windowLevel = _clickWindowLevel + (dragPoint.y - _clickPoint.y)*10.0;
    self.windowWidth = MAX(_clickWindowWidth + (dragPoint.x - _clickPoint.x)*10.0, 0);

    _clickPoint = NSZeroPoint;
    _clickWindowLevel = 0;
    _clickWindowWidth = 0;
}

- (BOOL)mouseDownCanMoveWindow
{
    return NO;
}

@end
