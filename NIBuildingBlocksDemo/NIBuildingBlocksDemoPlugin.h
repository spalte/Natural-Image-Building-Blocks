//
//  NIBuildingBlocksDemoPlugin.h
//  NIBuildingBlocksDemo
//
//  Created by Joël Spaltenstein on 6/15/15.
//  Copyright (c) 2015 Spaltenstein Natural Image. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <OsiriXAPI/PluginFilter.h>

@class NIBuildingBlocksDemoWindowController;

@interface NIBuildingBlocksDemoPlugin : PluginFilter
{
    NIBuildingBlocksDemoWindowController *_buildingBlocksDemoWindowController;
}


@end
