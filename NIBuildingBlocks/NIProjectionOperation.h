//  Copyright (c) 2017 Spaltenstein Natural Image
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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

#ifndef _NIPROJECTIONOPERATION_H_
#define _NIPROJECTIONOPERATION_H_

#import <Cocoa/Cocoa.h>
#import "NIGeneratorRequest.h"

@class NIVolumeData;

// give this operation a volumeData at the start, when the operation is finished, if everything went well, generated volume will be the projection through the Z (depth) direction

@interface NIProjectionOperation : NSOperation {
    NIVolumeData *_volumeData;
    NIVolumeData *_generatedVolume;

    NIProjectionMode _projectionMode;
}

@property (nonatomic, readwrite, retain) NIVolumeData *volumeData;
@property (nonatomic, readonly, retain) NIVolumeData *generatedVolume;

@property (nonatomic, readwrite, assign) NIProjectionMode projectionMode;

@end

#endif /* _NIPROJECTIONOPERATION_H_ */
