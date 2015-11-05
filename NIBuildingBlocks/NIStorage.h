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

- (instancetype)initWithBundle:(NSBundle*)bundle; // determines the location through +[NIStorage defaultLocationForBundle:bundle]
- (instancetype)initWithLocation:(NSURL*)location;

- (NSURL*)directoryForKey:(id)key; // key must be either NSString* or NSArray<NSString*>, in which case the resulting directoy will have a subdirectory for every element in the array
- (NSURL*)directoryForKey:(id)key create:(BOOL)create; // by default, create is YES

@end

@protocol NIStorageLocator

+ (NSURL*)NIStorageDefaultLocationForBundle:(NSBundle*)bundle;

@end