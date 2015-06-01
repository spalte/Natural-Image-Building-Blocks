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
#import "NIBBGeometry.h"
#import "NIBBVolumeData.h"

@class NIBBVolumeData;

// This operation will fill out floatBytes from the given data. FloatBytes is assumed to be tightly packed float image of width "width" and height "height"
// float bytes will be filled in with values at vectors and each successive scan line will be filled with with values at vector+normal*scanlineNumber
@interface NIBBHorizontalFillOperation : NSOperation {
    NIBBVolumeData *_volumeData;

    float *_floatBytes;
    NSUInteger _width;
    NSUInteger _height;

    NIBBVectorArray _vectors;
    NIBBVectorArray _normals;

    NIBBInterpolationMode _interpolationMode;
}

// vectors and normals need to be arrays of length width
- (id)initWithVolumeData:(NIBBVolumeData *)volumeData interpolationMode:(NIBBInterpolationMode)interpolationMode floatBytes:(float *)floatBytes width:(NSUInteger)width height:(NSUInteger)height vectors:(NIBBVectorArray)vectors normals:(NIBBVectorArray)normals;

@property (readonly, retain) NIBBVolumeData *volumeData;

@property (readonly, assign) float *floatBytes;
@property (readonly, assign) NSUInteger width;
@property (readonly, assign) NSUInteger height;

@property (readonly, assign) NIBBVectorArray vectors;
@property (readonly, assign) NIBBVectorArray normals;

@property (readonly, assign) NIBBInterpolationMode interpolationMode; // YES by default

@end
