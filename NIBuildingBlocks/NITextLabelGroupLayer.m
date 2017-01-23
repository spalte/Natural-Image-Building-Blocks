//  Created by Joël Spaltenstein on 6/7/15.
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

#import "NITextLabelGroupLayer.h"

#import "NIAnnotationTextLayer.h"


@interface NITextLabelGroupLayer ()
- (NSString *)uniqueLabelName;
- (void)resetSizeAndConstraints;

@end

@implementation NITextLabelGroupLayer

@synthesize textLabels = _textLabels;
@synthesize labelLocation = _labelLocation;
@synthesize magicLabelValues = _magicLabelValues;

- (instancetype)init
{
    if ( (self = [super init]) ) {
        _textLabels = [[NSMutableArray alloc] init];
        self.layoutManager = [CAConstraintLayoutManager layoutManager];
    }

    return self;
}

- (void)dealloc
{
    [_textLabels release];
    _textLabels = nil;
    [_magicLabelValues release];
    _magicLabelValues = nil;

    [super dealloc];
}

- (NSUInteger)countOfTextLabels
{
    return [_textLabels count];
}

- (NSString *)objectInTextLabelsAtIndex:(NSUInteger)index
{
    return [_textLabels objectAtIndex:index];
}

- (void)insertObject:(NSString *)textLabel inTextLabelsAtIndex:(NSUInteger)index
{
    NIAnnotationTextLayer *textLayer = [[[NIAnnotationTextLayer alloc] init] autorelease];
    textLayer.annotationString = textLabel;
    textLayer.name = [self uniqueLabelName];
    textLayer.contentsScale = self.contentsScale;

    if (index < [self.sublayers count]) {
        textLayer.constraints = [self.sublayers[index] constraints];
    } else if (index == 0) {
        if (self.labelLocation == NITextLabelLocationTopLeftEdgeSite || self.labelLocation == NITextLabelLocationTopEdgeSite || self.labelLocation == NITextLabelLocationTopRightEdgeSite) {
            [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:-5]];
        } else if (self.labelLocation == NITextLabelLocationBottomLeftEdgeSite || self.labelLocation == NITextLabelLocationBottomEdgeSite || self.labelLocation == NITextLabelLocationBottomRightEdgeSite) {
            [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY]];
        }
    } else {
        if (self.labelLocation == NITextLabelLocationTopLeftEdgeSite || self.labelLocation == NITextLabelLocationBottomLeftEdgeSite) {
            [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX offset:7]];
        } else if (self.labelLocation == NITextLabelLocationTopEdgeSite || self.labelLocation == NITextLabelLocationBottomEdgeSite) {
            [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
        } else if (self.labelLocation == NITextLabelLocationTopRightEdgeSite || self.labelLocation == NITextLabelLocationBottomRightEdgeSite) {
            [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX offset:-7]];
        }

        [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:[self.sublayers[index - 1] name] attribute:kCAConstraintMinY]];
    }

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [_textLabels insertObject:textLabel atIndex:index];
    [self insertSublayer:textLayer atIndex:(unsigned int)index];

    [self layoutIfNeeded];
    [CATransaction commit];

    [self resetSizeAndConstraints];
}

- (void)removeObjectFromTextLabelsAtIndex:(NSUInteger)index
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    [_textLabels removeObjectAtIndex:index];
    [(CALayer *)self.sublayers[index] removeFromSuperlayer];

    [CATransaction commit];

    [self resetSizeAndConstraints];
}

- (void)replaceObjectInTextLabelsAtIndex:(NSUInteger)index withObject:(NSString *)object
{
    [_textLabels replaceObjectAtIndex:index withObject:object];
    [(NIAnnotationTextLayer *)self.sublayers[index] setAnnotationString:object];
    [self resetSizeAndConstraints];
}

- (void)resetSizeAndConstraints
{
    // remove all the previous constraints
    NSUInteger i;
    for (i = 0; i < [[self sublayers] count]; i++) {
        CALayer *textLayer = self.sublayers[i];
        textLayer.constraints = @[];

        if (self.labelLocation == NITextLabelLocationTopLeftEdgeSite || self.labelLocation == NITextLabelLocationBottomLeftEdgeSite) {
            [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX offset:7]];
        } else if (self.labelLocation == NITextLabelLocationTopEdgeSite || self.labelLocation == NITextLabelLocationBottomEdgeSite) {
            [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
        } else if (self.labelLocation == NITextLabelLocationTopRightEdgeSite || self.labelLocation == NITextLabelLocationBottomRightEdgeSite) {
            [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX offset:-7]];
        }
    }

    if ([[self sublayers] count]) {
        if (self.labelLocation == NITextLabelLocationTopLeftEdgeSite || self.labelLocation == NITextLabelLocationTopEdgeSite || self.labelLocation == NITextLabelLocationTopRightEdgeSite) {
            [(CALayer*)self.sublayers[0] addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:-5]];
        } else if (self.labelLocation == NITextLabelLocationBottomLeftEdgeSite || self.labelLocation == NITextLabelLocationBottomEdgeSite || self.labelLocation == NITextLabelLocationBottomRightEdgeSite) {
            [(CALayer*)self.sublayers[0] addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY]];
        }
    }

    for (i = 1; i < [[self sublayers] count]; i++) {
        NIAnnotationTextLayer *prevTextLayer = (NIAnnotationTextLayer *)self.sublayers[i-1];
        NIAnnotationTextLayer *textLayer = (NIAnnotationTextLayer *)self.sublayers[i];

        [textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:prevTextLayer.name attribute:kCAConstraintMinY]];


    }

    [self layoutIfNeeded];

    CGSize size = CGSizeZero;
    for (i = 0; i < [[self sublayers] count]; i++) {
        CALayer *textLayer = self.sublayers[i];

//        size.height += textLayer.bounds.size.height;
        // it would be better to now hardcode this, but getting the height is a pain
        size.height += 17;
        size.width = MAX(size.width, textLayer.bounds.size.width + 7);
    }

    if ([[self sublayers] count]) {
        size.height += 5;
    }

    CGRect bounds = self.bounds;
    bounds.size = size;
    self.bounds = bounds;
    
    [self.superlayer layoutIfNeeded];
}


- (NSString *)uniqueLabelName
{
    static NSUInteger labelNumber = 0;
    return [NSString stringWithFormat:@"NITextLabel%lld", (long long)labelNumber++];
}

@end



























