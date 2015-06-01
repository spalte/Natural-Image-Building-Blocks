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

@protocol NIBBGeneratorDelegate;

@interface NIBBGenerator : NSObject {
    NSOperationQueue *_generatorQueue;
    NSMutableSet *_observedOperations;
    NSMutableArray *_finishedOperations;
    id <NIBBGeneratorDelegate> _delegate;
    
    NSMutableArray *_generatedFrameTimes;
    
    NIBBVolumeData *_volumeData;
}

@property (nonatomic, readwrite, assign) id <NIBBGeneratorDelegate> delegate;
@property (readonly) NIBBVolumeData *volumeData;

+ (NIBBVolumeData *)synchronousRequestVolume:(NIBBGeneratorRequest *)request volumeData:(NIBBVolumeData *)volumeData;

- (id)initWithVolumeData:(NIBBVolumeData *)volumeData;

- (void)requestVolume:(NIBBGeneratorRequest *)request;

- (void)runUntilAllRequestsAreFinished; // must be called on the main thread. Delegate callbacks will happen, but this method will not return until all outstanding requests have been processed

- (CGFloat)frameRate;

@end


@protocol NIBBGeneratorDelegate <NSObject>
@required
- (void)generator:(NIBBGenerator *)generator didGenerateVolume:(NIBBVolumeData *)volume request:(NIBBGeneratorRequest *)request;
@optional
- (void)generator:(NIBBGenerator *)generator didAbandonRequest:(NIBBGeneratorRequest *)request;
@end



