//  Created by Joël Spaltenstein on 6/7/15.
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

#import <QuartzCore/QuartzCore.h>

#import <NIGeneratorRequestView.h>

typedef NS_ENUM(NSInteger, NITextLabelLocation) {
    NITextLabelLocationUnknownSite = -1,
    NITextLabelLocationTopLeftEdgeSite = 0,
    NITextLabelLocationTopRightEdgeSite,
    NITextLabelLocationBottomLeftEdgeSite,
    NITextLabelLocationBottomRightEdgeSite,
    NITextLabelLocationTopEdgeSite,
    NITextLabelLocationBottomEdgeSite,
};

static const NSInteger NITextLabelLocationCount = 6;

@interface NITextLabelGroupLayer : CALayer
{
    NSMutableArray *_textLabels;
    NSDictionary *_magicLabelValues;
    NITextLabelLocation _labelLocation;
}

@property (nonatomic, readonly, copy) NSArray *textLabels;
@property (nonatomic, readwrite, retain) NSDictionary* magicLabelValues;
@property (nonatomic, readwrite, assign) NITextLabelLocation labelLocation;

- (NSUInteger)countOfTextLabels;
- (NSString *)objectInTextLabelsAtIndex:(NSUInteger)index;
- (void)insertObject:(NSString *)textLanel inTextLabelsAtIndex:(NSUInteger)index;
- (void)removeObjectFromTextLabelsAtIndex:(NSUInteger)index;
- (void)replaceObjectInTextLabelsAtIndex:(NSUInteger)index withObject:(NSString *)object;

@end
