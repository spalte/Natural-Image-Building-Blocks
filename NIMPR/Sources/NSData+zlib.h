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

- (NSData*)zlibDeflate;
- (NSData*)zlibDeflate:(NSError**)err;
- (NSData*)zlibDeflate:(NSError**)err level:(NIZlibCompressionLevel)compressionLevel;

- (NSData*)zlibInflate;
- (NSData*)zlibInflate:(NSError**)err;

@end
