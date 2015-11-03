//
//  NIStorage.h
//  NIBuildingBlocks
//
//  Created by Alessandro Volz on 10/28/15.
//  Copyright © 2015 Spaltenstein Natural Image. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NIStorage : NSObject {
    NSURL* _location;
}

+ (NSURL*)defaultLocationForBundle:(NSBundle*)bundle;

@property(retain, readonly) NSURL* location;

- (instancetype)initWithLocation:(NSURL*)location;

@end

@protocol NIStorageLocator

+ (NSURL*)NIStorageDefaultLocationForBundle:(NSBundle*)bundle;

@end