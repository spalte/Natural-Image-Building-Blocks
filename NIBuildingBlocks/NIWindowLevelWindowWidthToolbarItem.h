//
//  NIWindowLevelWindowWidthToolbarItem.h
//  NIBuildingBlocks
//
//  Created by Joël Spaltenstein on 6/4/15.
//  Copyright (c) 2015 Spaltenstein Natural Image. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NIWindowingView;

@interface NIWindowLevelWindowWidthToolbarItem : NSToolbarItem
{
    NSPopover *_popover;
    NIWindowingView* _windowingView;
    BOOL _observingView; // YES if the toolbarItem is currently observing the view

    NSArray *_generatorRequestViews;
    NSArray *_volumeDataProperties;
    NSUInteger _volumeDataIndex;
}

@property (nonatomic, readwrite, retain) IBOutlet NSPopover *popover;
@property (nonatomic, readwrite, retain) IBOutlet NIWindowingView* windowingView;
@property (nonatomic, readwrite, copy) NSArray *generatorRequestViews;
@property (nonatomic, readwrite, assign) NSUInteger volumeDataIndex;

@end
