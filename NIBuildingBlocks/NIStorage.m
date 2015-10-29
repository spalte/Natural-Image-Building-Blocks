//
//  NIStorage.m
//  NIBuildingBlocks
//
//  Created by Alessandro Volz on 10/28/15.
//  Copyright © 2015 Spaltenstein Natural Image. All rights reserved.
//

#import "NIStorage.h"
#import <objc/runtime.h>

@implementation NIStorage

+ (NSURL*)defaultLocationForBundle:(NSBundle*)bundle {
    // find the NIStorageLocators
    Protocol* storageLocatorProtocol = NSProtocolFromString(@"NIStorageLocator"); // TODO: Is there a better way to obtain this Protocol*?
    int count = objc_getClassList(NULL, 0);
    Class c[count]; objc_getClassList(c, count);
    NSMutableArray<Class>* NIStorageLocators = [NSMutableArray array];
    for (int i = 0; i < count; ++i) {
        if (class_conformsToProtocol(c[i], storageLocatorProtocol))
            [NIStorageLocators addObject:c[i]];
    }
    
    NSMutableArray<NSBundle*>* bundles = [NSMutableArray arrayWithObject:NSBundle.mainBundle];
    if (bundle && ![bundles containsObject:bundle])
        [bundles addObject:bundle];
    
    static NSString* const CFBundleName = @"CFBundleName";
    NSError* err = nil;
    
    NSURL* dir = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&err];
    if (err)
        @throw [NSException exceptionWithName:NSGenericException reason:@"Couldn't determine Application Support directory location" userInfo:@{ NSUnderlyingErrorKey: err }];
    
    for (NSBundle* bundle in bundles) {
        NSURL* bundleDir = nil;
        
        // locators method
        
        for (Class c in NIStorageLocators)
            @try {
                NSURL* ldir = [c NIStorageDefaultLocationForBundle:bundle];
                if (ldir) {
                    bundleDir = ldir;
                    break;
                }
            } @catch (...) {
                // do nothing
            }
        
        // default method
        
        if (!bundleDir) {
            NSMutableArray<NSString*>* sdirs = [NSMutableArray array]; // regarding Library/Application Support, Apple switched their recommendation to BundleIdentifier instead of the application name a while ago. According to them all new apps should use the bundle identifier.
            [sdirs addObject:bundle.bundleIdentifier];
            if ([bundle.infoDictionary[CFBundleName] length])
                [sdirs addObject:bundle.infoDictionary[CFBundleName]];
            else [sdirs addObject:[[bundle.bundleURL lastPathComponent] stringByDeletingPathExtension]];

            for (NSString* sdir in sdirs) {
                NSURL* sdirDir = [dir URLByAppendingPathComponent:sdir isDirectory:YES];
                if ([sdirDir checkPromisedItemIsReachableAndReturnError:NULL]) {
                    bundleDir = sdirDir;
                    break;
                }
            }
            
            if (!bundleDir) {
                [NSFileManager.defaultManager createDirectoryAtURL:(bundleDir = [dir URLByAppendingPathComponent:sdirs[0] isDirectory:YES]) withIntermediateDirectories:YES attributes:nil error:&err];
                if (err)
                    @throw [NSException exceptionWithName:NSGenericException reason:@"Couldn't create Application Support directory" userInfo:@{ NSUnderlyingErrorKey: err }];
            }
        }

        dir = bundleDir;
    }
    
    return dir;
}

@end
