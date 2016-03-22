//  Copyright (c) 2016 OsiriX Foundation
//  Copyright (c) 2016 Spaltenstein Natural Image
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

@class NIGeneratorRequest;
@class NIVolumeData;

@protocol NIGeneratorDelegate;

typedef int64_t NIGeneratorAsynchronousRequestID;

@interface NIGenerator : NSObject {
    NSOperationQueue *_generatorQueue;
    NSMutableSet *_observedOperations;
    NSMutableArray *_finishedOperations;
    id <NIGeneratorDelegate> _delegate;
    
    NSMutableArray *_generatedFrameTimes;
    
    NIVolumeData *_volumeData;
}

@property (nonatomic, readwrite, assign) id <NIGeneratorDelegate> delegate;
@property (readonly) NIVolumeData *volumeData;

+ (NIVolumeData *)synchronousRequestVolume:(NIGeneratorRequest *)request volumeData:(NIVolumeData *)volumeData;

// The execution context for your completion block is not guaranteed
+ (NIGeneratorAsynchronousRequestID)asynchronousRequestVolume:(NIGeneratorRequest *)request volumeData:(NIVolumeData *)volumeData completionBlock:(void (^)(NIVolumeData* generatedVolume))completionBlock;
+ (void)cancelAsynchronousRequest:(NIGeneratorAsynchronousRequestID)requestID;


- (id)initWithVolumeData:(NIVolumeData *)volumeData;

- (void)requestVolume:(NIGeneratorRequest *)request;

- (void)runUntilAllRequestsAreFinished; // must be called on the main thread. Delegate callbacks will happen, but this method will not return until all outstanding requests have been processed

- (CGFloat)frameRate;

@end


@protocol NIGeneratorDelegate <NSObject>
@required
- (void)generator:(NIGenerator *)generator didGenerateVolume:(NIVolumeData *)volume request:(NIGeneratorRequest *)request;
@optional
- (void)generator:(NIGenerator *)generator didAbandonRequest:(NIGeneratorRequest *)request;
@end



