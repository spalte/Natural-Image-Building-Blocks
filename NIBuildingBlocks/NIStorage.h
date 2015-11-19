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

@property (retain, readonly) NSURL* location;

- (instancetype)initWithBundle:(NSBundle*)bundle; // determines the location through +[NIStorage defaultLocationForBundle:bundle]
- (instancetype)initWithLocation:(NSURL*)location;

- (NSURL*)directoryForKey:(NSString*)keyPath;
- (NSURL*)directoryForKey:(NSString*)keyPath create:(BOOL)create; // by default, create is YES

@end

@protocol NIStorageLocator

+ (NSURL*)NIStorageDefaultLocationForBundle:(NSBundle*)bundle;

@end