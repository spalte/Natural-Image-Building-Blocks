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
#import "NIBBGeneratorOperation.h"
#import "NIBBGeneratorRequest.h"

@interface NIBBStraightenedOperation : NIBBGeneratorOperation {
    volatile int32_t _outstandingFillOperationCount __attribute__ ((aligned (4)));
    
    float *_floatBytes;
    NSMutableSet *_fillOperations;
	NSOperation *_projectionOperation;
    BOOL _operationExecuting;
    BOOL _operationFinished;
    BOOL _operationFailed;
    
    CGFloat _sampleSpacing; // renerated and cached by the operation based on the width and the length of the bezier
}

- (id)initWithRequest:(NIBBStraightenedGeneratorRequest *)request volumeData:(NIBBVolumeData *)volumeData;

@property (readonly) NIBBStraightenedGeneratorRequest *request;

@end

