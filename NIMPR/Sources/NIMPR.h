//
//  NIMPR.h
//  NIMPR
//
//  Created by Alessandro Volz on 6/2/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NIMPR : NSObject {
    NSBundle* _bundle;
}

@property(retain,readonly) NSBundle* bundle;

+ (NIMPR*)instance;
+ (NSBundle*)bundle;

#ifndef NIMPR_Private
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
#endif

+ (NSImage*)image:(NSString*)name;

//- (void)setStorage:(id<NIStorage>)storage;



@end


//
//
//
//@protocol NIStorage <NSObject>
//
//- (void)store:(NSData*)data forVolume:(NIVolumeData*)data key:(NSString*)key;
//- (NSData*)dataForVolume:(NIVolumeData*)data key:(NSString*)key;
//
//@end
//
//
//
//
//dans osi
//
//
//- (void)initPlugin {
//    [NIBB initForOsiriX];
//    
//}
//
//+ (void)initForOsiriX {
//    [NIMPR.instance setStorage:[[[NIStorageOsiriX alloc] init] autorelease]];
//}