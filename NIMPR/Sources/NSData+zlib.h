//
//  NSData+zlib.h
//  NIMPR
//
//  Created by Alessandro Volz on 9/1/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const ZlibDomain;

@interface NSData (zlib)

- (NSData*)zlibDeflate:(NSError**)err; // compress
- (NSData*)zlibInflate:(NSError**)err; // decompress

@end
