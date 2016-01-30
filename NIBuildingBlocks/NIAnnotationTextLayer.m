//  Created by Joël Spaltenstein on 4/20/15.
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

#import "NIAnnotationTextLayer.h"

#import <Cocoa/Cocoa.h>

@implementation NIAnnotationTextLayer

- (instancetype)init
{
    if ( (self = [super init])) {
        self.shadowOffset = CGSizeMake(1, -1);
        self.shadowOpacity = 1;
        self.shadowRadius = 1;
        self.shadowColor = [[NSColor blackColor] CGColor];
    }

    return self;
}

- (void)dealloc
{
    [super dealloc];
}


- (void)setAnnotationString:(NSString *)annotationString
{
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:14];
    NSAttributedString *whiteString = [[[NSAttributedString alloc] initWithString:annotationString attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName:[NSColor whiteColor]}] autorelease];

    self.string = whiteString;
}

- (NSString *)annotationString
{
    if ([self.string respondsToSelector:@selector(string)]) {
        return [(NSAttributedString *)self.string string];
    } else {
        return self.string;
    }
}


@end
