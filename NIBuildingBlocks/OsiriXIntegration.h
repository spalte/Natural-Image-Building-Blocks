//
//  OsiriXIntegration.h
//  NIBuildingBlocks
//
//  Created by Joël Spaltenstein on 6/1/15.
//  Copyright (c) 2015 Spaltenstein Natural Image. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NIBBVolumeData;

// call this function to add the methods below to OsiriX, returns 0 on success
int NIBuildingBlocksInstallOsiriXCategories();

// These methods will be added to OsiriX's ViewerController
@interface NSObject (NIBuildingBlocksViewerControllerAdditions)
- (NIBBVolumeData *)NIBBVolumeDataForMovieIndex:(NSUInteger)movieIndex;
@end
