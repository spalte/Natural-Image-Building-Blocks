//  Created by Joël Spaltenstein on 4/26/15.
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


#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Cocoa/Cocoa.h>

extern NSString* const NIMouseBullsEyeSprite;

@class NIGeneratorRequestView;

@interface NISprite : NSObject
{
@private
    NIGeneratorRequestView *_generatorRequestView; // not retained
    CALayer *_layer;

    BOOL _hidden;
}

+ (instancetype)spriteWithName:(NSString *)spriteName;

@property (nonatomic, readwrite, retain) NSColor *color;
@property (nonatomic, readwrite, assign) NSPoint position;
@property (nonatomic, readwrite, assign, getter=isHidden) BOOL hidden;

@end
