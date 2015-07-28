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

#import "NIMaskRunStack.h"

@implementation NIMaskRunStack

- (id)initWithMaskRunData:(NSData *)maskRunData
{
    if ( (self = [super init])) {
        _maskRunData = [maskRunData retain];
        maskRunCount = [maskRunData length] / sizeof(NIMaskRun);
        _maskRunArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_maskRunData release];
    [_maskRunArray release];
    
    [super dealloc];
}

- (NIMaskRun)currentMaskRun
{
    if ([_maskRunArray count]) {
        return [[_maskRunArray lastObject] NIMaskRunValue];
    } else if (_maskRunIndex < maskRunCount) {
        return ((NIMaskRun *)[_maskRunData bytes])[_maskRunIndex];
    } else {
        assert(0);
        return NIMaskRunZero;
    }
}

- (void)pushMaskRun:(NIMaskRun)maskRun
{
    [_maskRunArray addObject:[NSValue valueWithNIMaskRun:maskRun]];
}

- (NIMaskRun)popMaskRun
{
    NIMaskRun maskRun;
    
    if ([_maskRunArray count]) {
        maskRun = [[_maskRunArray lastObject] NIMaskRunValue];
        [_maskRunArray removeLastObject];
    } else if (_maskRunIndex < maskRunCount) {
        maskRun = ((NIMaskRun *)[_maskRunData bytes])[_maskRunIndex];
        _maskRunIndex++;
    } else {
        assert(0);
        maskRun = NIMaskRunZero;
    }
    
    return maskRun;
}

- (NSUInteger)count
{
    return [_maskRunArray count] + (maskRunCount - _maskRunIndex);
}

@end
