//
//  NSData+zlib.h
//  NIMPR
//
//  Created by Alessandro Volz on 9/1/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const ZlibDomain;

typedef enum : NSUInteger {
    NIZlibDefaultCompressionLevel,
    NIZlibBestCompressionLevel,
} NIZlibCompressionLevel;

@interface NSData (zlib)

+ (NIZlibCompressionLevel)defaultCompressionLevel;
+ (void)setDefaultCompressionLevel:(NIZlibCompressionLevel)compressionLevel;

- (NSData*)zlibDeflatedData;
- (NSData*)zlibDeflatedDataWithError:(NSError**)err;
- (NSData*)zlibDeflatedDataWithLevel:(NIZlibCompressionLevel)compressionLevel error:(NSError**)err;

- (NSData*)zlibInflatedData;
- (NSData*)zlibInflatedDataWithError:(NSError**)err;

@end
