//  Created by Joël Spaltenstein on 4/26/15.
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


#import "NIBBSprite.h"
#import "NIBBSpritePrivate.h"
#import "NIBBMouseBullseyeLayer.h"
#import "NIBBGeneratorRequestView.h"

NSString* const NIBBMouseBullsEyeSprite = @"NIBBMouseBullsEyeSprite";


@implementation NIBBSprite

@synthesize hidden = _hidden;

+ (instancetype)spriteWithName:(NSString *)spriteName
{
    NSAssert([spriteName isEqualToString:NIBBMouseBullsEyeSprite], @"only NIBBMouseBullsEyeSprite is defined for now");

    NIBBSprite *sprite = [[[NIBBSprite alloc] init] autorelease];
    sprite.layer = [[[NIBBMouseBullseyeLayer alloc] init] autorelease];

    return sprite;
}

- (void)dealloc
{
    [_layer removeFromSuperlayer];
    [_layer release];
    _layer = nil;

    [super dealloc];
}

- (void)setColor:(NSColor *)color
{
    [(NIBBMouseBullseyeLayer *)self.layer setStrokeColor:[color CGColor]];
}

- (NSColor *)color
{
    return [NSColor colorWithCGColor:[(NIBBMouseBullseyeLayer *)self.layer strokeColor]];
}

- (void)setPosition:(NSPoint)position
{
    [(NIBBMouseBullseyeLayer *)self.layer setPosition:NSPointToCGPoint(position)];
}

- (NSPoint)position
{
    return NSPointFromCGPoint([(NIBBMouseBullseyeLayer *)self.layer position]);
}

- (void)setHidden:(BOOL)hidden
{
    if (_hidden != hidden) {
        _hidden = hidden;

        if (_hidden) {
            [self.layer removeFromSuperlayer];
        } else if (self.generatorRequestView) {
            [self.generatorRequestView.frameLayer addSublayer:self.layer];
        }
    }
}

- (void)setLayer:(CALayer *)layer
{
    if (_layer != layer) {
        [_layer release];
        _layer = [layer retain];
    }
}

- (CALayer *)layer
{
    return _layer;
}

- (void)setGeneratorRequestView:(NIBBGeneratorRequestView *)generatorRequestView
{
    if (_generatorRequestView != generatorRequestView) {
        _generatorRequestView = generatorRequestView;
        [self.layer removeFromSuperlayer];

        if (_hidden == NO) {
            [_generatorRequestView.frameLayer addSublayer:self.layer];
        }
    }
}

- (NIBBGeneratorRequestView *)generatorRequestView
{
    return _generatorRequestView;
}

@end
