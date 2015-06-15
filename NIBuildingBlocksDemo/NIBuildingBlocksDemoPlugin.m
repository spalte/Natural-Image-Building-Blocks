//
//  NIBuildingBlocksDemoPlugin.m
//  NIBuildingBlocksDemo
//
//  Created by Joël Spaltenstein on 6/15/15.
//  Copyright (c) 2015 Spaltenstein Natural Image. All rights reserved.
//

#import "NIBuildingBlocksDemoPlugin.h"
#import "NIBuildingBlocksDemoWindowController.h"

@implementation NIBuildingBlocksDemoPlugin

- (long)filterImage:(NSString*)menuName
{
    if (_buildingBlocksDemoWindowController == nil) {
        _buildingBlocksDemoWindowController = [[NIBuildingBlocksDemoWindowController alloc] initWithWindowNibName:@"NIBuildingBlocksDemoWindowController"];
    }

    [_buildingBlocksDemoWindowController.window makeKeyAndOrderFront:self];

    return 0;
}

@end
