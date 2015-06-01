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

@class NIBBGeneratorRequest;
@class NIBBVolumeData;

@interface NIBBGeneratorOperation : NSOperation {
    NIBBVolumeData *_volumeData;
    NIBBGeneratorRequest *_request;
    NIBBVolumeData *_generatedVolume;
}

- (id)initWithRequest:(NIBBGeneratorRequest *)request volumeData:(NIBBVolumeData *)volumeData;

@property (readonly) NIBBGeneratorRequest *request;
@property (readonly) NIBBVolumeData *volumeData;
@property (readonly) BOOL didFail;
@property (readwrite, retain) NIBBVolumeData *generatedVolume;

@end

