//
//  NIBackgroundView.h
//  NIMPR
//
//  Created by Alessandro Volz on 8/3/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NIBackgroundView : NSView {
    NSColor* _backgroundColor;
    void (^_updateConstraintsBlock)();
//    void (^_willMoveToSuperviewBlock)(NSView*);
    NSMutableArray* _retains;
}

@property(retain) NSColor* backgroundColor;
@property(copy) void (^updateConstraintsBlock)();
//@property(copy) void (^willMoveToSuperviewBlock)(NSView*);

- (id)initWithFrame:(NSRect)frameRect color:(NSColor*)backgroundColor;

- (id)retain:(id)obj;

@end

@interface NSTextField (NI)

+ (instancetype)labelWithControlSize:(NSControlSize)controlSize;
+ (instancetype)fieldWithControlSize:(NSControlSize)controlSize;

@end