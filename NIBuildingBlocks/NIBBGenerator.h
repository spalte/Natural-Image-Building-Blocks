//  Copyright (c) 2015 OsiriX Foundation
//  Copyright (c) 2015 Spaltenstein Natural Image
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



