//  Copyright (c) 2017 Spaltenstein Natural Image
//  Copyright (c) 2017 OsiriX Foundation
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

#ifndef _NIGENERATOR_H_
#define _NIGENERATOR_H_

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class NIGeneratorRequest;
@class NIVolumeData;

@protocol NIGeneratorDelegate;

/**
 ID token used to refer back to a specific asynchronous request to the generator.
 */
typedef int64_t NIGeneratorAsynchronousRequestID;

/**
 The NIGenerator class is used in conjunction with a NIVolumeData and a NIGeneratorRequest subclasses to build a new NIVolumeData
 that represents the slice described by the NIGeneratorRequest. The synchronous and asynchronous class methods are the
 preferred way to use this class. Curved NIVolumeData objects can not be used as source NIVolumeDate objects.
 */
@interface NIGenerator : NSObject {
    NSOperationQueue *_generatorQueue;
    NSMutableSet *_observedOperations;
    NSMutableArray *_finishedOperations;
    id <NIGeneratorDelegate> _delegate;
    
    NSMutableArray *_generatedFrameTimes;
    
    NIVolumeData *_volumeData;
}

/**
 The NIGenerator's delegate.
*/
@property (nullable, readwrite, weak) id <NIGeneratorDelegate> delegate;

/**
 The NIVolumeData object that serves as the source when generating new NIVolumeData objects.
*/
@property (readonly) NIVolumeData *volumeData;

/**
 Returns a new NIVolumeData object based on the slice described by the given NIGeneratorRequest. The Quality of Service
 of synchronous requests is NSQualityOfServiceUserInteractive if called from the main thread, and NSQualityOfServiceUserInitiated if
 called from another thread.
 @param request The NIGeneratorRequest object that defines to slice to be generatred.
 @param volumeData The source volume from which to generate the slice.
*/
+ (NIVolumeData *)synchronousRequestVolume:(NIGeneratorRequest *)request volumeData:(NIVolumeData *)volumeData;

/**
 Begins asynchronously generating a NIVolumeData object based on the slice described by the given NIGeneratorRequest. The
 newly generated NIVolumeData is returned via the given completionBlock. The execution context for your completion block is not guaranteed.
 The returned NIVolumeData object is generated using NSQualityOfServiceUserInitiated suaity of service.
 @param request The NIGeneratorRequest object that defines to slice to be generatred.
 @param volumeData The source volume from which to generate the slice.
 @param completionBlock The block that is used to return the generated NIVolumeData. The context in which this block is called in not defined.
 @see asynchronousRequestVolume:volumeData:qualityOfService:completionBlock:
*/
+ (NIGeneratorAsynchronousRequestID)asynchronousRequestVolume:(NIGeneratorRequest *)request volumeData:(NIVolumeData *)volumeData completionBlock:(void (^)(NIVolumeData* __nullable generatedVolume))completionBlock;
/**
 Begins asynchronously generating a NIVolumeData object based on the slice described by the given NIGeneratorRequest. The
 newly generated NIVolumeData is returned via the given completionBlock. The execution context for your completion block is not guaranteed.
 @param request The NIGeneratorRequest object that defines to slice to be generatred.
 @param volumeData The source volume from which to generate the slice.
 @param qualityOfService The quality of sevice used to generate the returned NIVolumeData object.
 @param completionBlock The block that is used to return the generated NIVolumeData. The context in which this block is called in not defined.
 @return Returns a NIGeneratorAsynchronousRequestID as an ID token that can be used to refer to this request.
 @see asynchronousRequestVolume:volumeData:qualityOfService:completionBlock:
 */
+ (NIGeneratorAsynchronousRequestID)asynchronousRequestVolume:(NIGeneratorRequest *)request volumeData:(NIVolumeData *)volumeData qualityOfService:(NSQualityOfService)qualityOfService completionBlock:(void (^)(NIVolumeData* __nullable generatedVolume))completionBlock;
/**
 Cancels the request refered to by the give NIGeneratorAsynchronousRequestID token ID. The completion block will still be called, but if the
 NIVolumeData has not yet been generated, the generated volume will be nil.
 @param requestID The token ID of the request to cancel.
*/
+ (void)cancelAsynchronousRequest:(NIGeneratorAsynchronousRequestID)requestID;
/**
 Blocks until the request given by the requestID has finished. The completion block will still be called.
 @param requestID The token ID of the request for which to wait.
 @return Returns the generated NIVolumeData object. If the operation was canceled, this method returns nil.
*/
+ (nullable NIVolumeData *)waitUntilAsynchronousRequestFinished:(NIGeneratorAsynchronousRequestID)requestID;
/**
 Returns YES if the request for the given request token ID is finished.
 @param requestID The token ID of the request of interest.
 #return Returns YES if the request for the given request token ID is finished
*/
+ (BOOL)isAsynchronousRequestFinished:(NIGeneratorAsynchronousRequestID)requestID;

+ (void)setPriority:(CGFloat)priority forAsynchronousRequest:(NIGeneratorAsynchronousRequestID)requestID __deprecated; // Use quality of service instead


// Don't use the functions below. They are either broken or behaves strangely.
// Use synchronousRequestVolume:... and asynchronousRequestVolume:... instead

- (id)initWithVolumeData:(NIVolumeData *)volumeData;

- (void)requestVolume:(NIGeneratorRequest *)request;

- (void)runUntilAllRequestsAreFinished; // must be called on the main thread. Delegate callbacks will happen, but this method will not return until all outstanding requests have been processed

- (CGFloat)frameRate;

@end

// Don't get data back with a delegate. This code will change in the future.
// Use synchronousRequestVolume:... and asynchronousRequestVolume:... instead

@protocol NIGeneratorDelegate <NSObject>
@required
- (void)generator:(NIGenerator *)generator didGenerateVolume:(NIVolumeData *)volume request:(NIGeneratorRequest *)request;
@optional
- (void)generator:(NIGenerator *)generator didAbandonRequest:(NIGeneratorRequest *)request;
@end

NS_ASSUME_NONNULL_END

#endif /* _NIGENERATOR_H_ */
