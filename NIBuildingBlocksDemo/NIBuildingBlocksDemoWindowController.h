//
//  NIBuildingBlocksDemoWindowController.h
//  NIBuildingBlocksDemo
//
//  Created by Joël Spaltenstein on 6/15/15.
//  Copyright (c) 2015 Spaltenstein Natural Image. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NIVolumeData;
@class NIGeneratorRequestView;
@class NIBuildingBlocksDemoView;
@class NIIntersection;

@interface NIBuildingBlocksDemoWindowController : NSWindowController
{
    NIVolumeData *_volumeData;

    NIBuildingBlocksDemoView *_leftView;
    NIGeneratorRequestView *_rightView;

    NIIntersection *_leftIntersection;
    NIIntersection *_rightIntersection;
}

@property (nonatomic, readwrite, assign) IBOutlet NIBuildingBlocksDemoView *leftView;
@property (nonatomic, readwrite, assign) IBOutlet NIGeneratorRequestView *rightView;

@property (nonatomic, readwrite, retain) NIVolumeData *volumeData;

@end
