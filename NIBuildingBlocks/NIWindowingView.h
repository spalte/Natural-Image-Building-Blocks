//
//  NIWindowingView.h
//  NIBuildingBlocks
//
//  Created by Joël Spaltenstein on 6/5/15.
//  Copyright (c) 2015 Spaltenstein Natural Image. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NIWindowingView : NSView
{
    NSPoint _clickPoint;
    CGFloat _clickWindowLevel;
    CGFloat _clickWindowWidth;


    CGFloat _windowLevel;
    CGFloat _windowWidth;
}


@property (nonatomic, readwrite, assign) CGFloat windowLevel;
@property (nonatomic, readwrite, assign) CGFloat windowWidth;

@end
