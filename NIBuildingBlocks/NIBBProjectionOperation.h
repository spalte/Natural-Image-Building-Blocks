/*=========================================================================
 Program:   OsiriX

 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL

 See http://www.osirix-viewer.com/copyright.html for details.

 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import <Cocoa/Cocoa.h>
#import "NIBBGeneratorRequest.h"

@class NIBBVolumeData;

// give this operation a volumeData at the start, when the operation is finished, if everything went well, generated volume will be the projection through the Z (depth) direction

@interface NIBBProjectionOperation : NSOperation {
    NIBBVolumeData *_volumeData;
    NIBBVolumeData *_generatedVolume;

    NIBBProjectionMode _projectionMode;
}

@property (nonatomic, readwrite, retain) NIBBVolumeData *volumeData;
@property (nonatomic, readonly, retain) NIBBVolumeData *generatedVolume;

@property (nonatomic, readwrite, assign) NIBBProjectionMode projectionMode;

@end
