//
//  NSData+zlib.m
//  NIMPR
//
//  Created by Alessandro Volz on 9/1/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NSData+zlib.h"
#import <zlib.h>

NSString* const ZlibDomain = @"zlib";

@implementation NSData (zlib)

- (NSData*)zlibDeflate:(NSError**)err {
    if (self.length == 0)
        return self;
    
    z_stream zs;
    zs.zalloc = Z_NULL;
    zs.zfree = Z_NULL;
    zs.opaque = Z_NULL;
    zs.total_out = 0;
    zs.next_in = (Bytef*)self.bytes;
    zs.avail_in = (uInt)self.length;
    
    int initError = deflateInit2(&zs, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (MAX_WBITS+16), 8, Z_DEFAULT_STRATEGY);
    
    if (initError != Z_OK) {
        NSString* message = nil;
        switch (initError) {
            case Z_STREAM_ERROR: message = NSLocalizedString(@"Invalid parameter passed in to function", @"Description for zlib Z_STREAM_ERROR"); break;
            case Z_MEM_ERROR: message = NSLocalizedString(@"Insufficient memory", @"Description for zlib Z_MEM_ERROR"); break;
            case Z_VERSION_ERROR: message = NSLocalizedString(@"The version of zlib.h and the version of the library linked do not match", @"Description for zlib Z_VERSION_ERROR"); break;
            default: message = NSLocalizedString(@"Unknown error code", @"Description for unknown zlib error"); break;
        }
        
        if (err)
            *err = [NSError errorWithDomain:ZlibDomain code:initError userInfo:@{ NSLocalizedDescriptionKey: message, NSLocalizedFailureReasonErrorKey: @(zs.msg) }];
        else NSLog(@"deflateInit2() error %d in %s: %@, %s", initError, __func__, message, zs.msg);
        
        return nil;
    }
    
    NSMutableData* rd = [NSMutableData dataWithLength:self.length * 1.01 + 12];
    int status;
    do {
        zs.next_out = rd.mutableBytes + zs.total_out;
        zs.avail_out = (uInt)(rd.length - zs.total_out);
    } while ((status = deflate(&zs, Z_FINISH)) == Z_OK);
    
    if (status != Z_STREAM_END) {
        NSString* message = nil;
        switch (status) {
            case Z_ERRNO: message = NSLocalizedString(@"Error occured while reading file", @"Description for zlib deflate Z_ERRNO"); break;
            case Z_STREAM_ERROR: message = NSLocalizedString(@"The stream state was inconsistent (e.g., next_in or next_out was NULL)", @"Description for zlib deflate Z_STREAM_ERROR"); break;
            case Z_DATA_ERROR: message = NSLocalizedString(@"The deflate data was invalid or incomplete", @"Description for zlib deflate Z_DATA_ERROR"); break;
            case Z_MEM_ERROR: message = NSLocalizedString(@"Memory could not be allocated for processing", @"Description for zlib deflate Z_MEM_ERROR"); break;
            case Z_BUF_ERROR: message = NSLocalizedString(@"Ran out of output buffer for writing compressed bytes", @"Description for zlib deflate Z_BUF_ERROR"); break;
            case Z_VERSION_ERROR: message = NSLocalizedString(@"The version of zlib.h and the version of the library linked do not match", @"Description for zlib Z_VERSION_ERROR"); break;
            default: message = NSLocalizedString(@"Unknown error code", @"Description for unknown zlib error"); break;
        }
        
        if (err)
            *err = [NSError errorWithDomain:ZlibDomain code:initError userInfo:@{ NSLocalizedDescriptionKey: message, NSLocalizedFailureReasonErrorKey: @(zs.msg) }];
        else NSLog(@"deflate() error %d in %s: %@, %s", initError, __func__, message, zs.msg);
        
        deflateEnd(&zs);
        return nil;
    }
    
    deflateEnd(&zs);
    [rd setLength:zs.total_out];
    
    return rd;
}

- (NSData*)zlibInflate:(NSError**)err {
    if (self.length == 0)
        return self;
    
    z_stream zs;
    zs.zalloc = Z_NULL;
    zs.zfree = Z_NULL;
    zs.opaque = Z_NULL;
    zs.total_out = 0;
    zs.next_in = (Bytef*)self.bytes;
    zs.avail_in = (uInt)self.length;
    
    int initError = inflateInit2(&zs, (MAX_WBITS+32));
    
    if (initError != Z_OK) {
        NSString* message = nil;
        switch (initError) {
            case Z_STREAM_ERROR: message = NSLocalizedString(@"Invalid parameter passed in to function", @"Description for zlib Z_STREAM_ERROR"); break;
            case Z_MEM_ERROR: message = NSLocalizedString(@"Insufficient memory", @"Description for zlib Z_MEM_ERROR"); break;
            case Z_VERSION_ERROR: message = NSLocalizedString(@"The version of zlib.h and the version of the library linked do not match", @"Description for zlib Z_VERSION_ERROR"); break;
            default: message = NSLocalizedString(@"Unknown error code", @"Description for unknown zlib error"); break;
        }
        
        if (err)
            *err = [NSError errorWithDomain:ZlibDomain code:initError userInfo:@{ NSLocalizedDescriptionKey: message, NSLocalizedFailureReasonErrorKey: @(zs.msg) }];
        else NSLog(@"inflateInit2() error %d in %s: %@, %s", initError, __func__, message, zs.msg);
        
        return nil;
    }
    
    NSMutableData* rd = [NSMutableData dataWithLength:self.length*2];
    int status;
    do {
        zs.next_out = rd.mutableBytes + zs.total_out;
        zs.avail_out = (uInt)(rd.length - zs.total_out);
        if ((status = inflate(&zs, Z_FINISH)) == Z_BUF_ERROR) {
            rd.length += self.length;
            status = Z_OK;
        }
    } while (status == Z_OK);
    
    if (status != Z_STREAM_END) {
        NSString* message = nil;
        switch (status) {
            case Z_ERRNO: message = NSLocalizedString(@"Error occured while reading file", @"Description for zlib inflate Z_ERRNO"); break;
            case Z_STREAM_ERROR: message = NSLocalizedString(@"The stream state was inconsistent (e.g., next_in or next_out was NULL)", @"Description for zlib inflate Z_STREAM_ERROR"); break;
            case Z_DATA_ERROR: message = NSLocalizedString(@"The inflate data was invalid or incomplete", @"Description for zlib inflate Z_DATA_ERROR"); break;
            case Z_MEM_ERROR: message = NSLocalizedString(@"Memory could not be allocated for processing", @"Description for zlib inflate Z_MEM_ERROR"); break;
            case Z_BUF_ERROR: message = NSLocalizedString(@"Ran out of output buffer for writing compressed bytes", @"Description for zlib inflate Z_BUF_ERROR"); break;
            case Z_VERSION_ERROR: message = NSLocalizedString(@"The version of zlib.h and the version of the library linked do not match", @"Description for zlib Z_VERSION_ERROR"); break;
            default: message = NSLocalizedString(@"Unknown error code", @"Description for unknown zlib error"); break;
        }
        
        if (err)
            *err = [NSError errorWithDomain:ZlibDomain code:initError userInfo:@{ NSLocalizedDescriptionKey: message, NSLocalizedFailureReasonErrorKey: @(zs.msg) }];
        else NSLog(@"inflate() error %d in %s: %@, %s", initError, __func__, message, zs.msg);
        
        inflateEnd(&zs);
        return nil;
    }
    
    inflateEnd(&zs);
    [rd setLength:zs.total_out];
    
    return rd;
}

@end
