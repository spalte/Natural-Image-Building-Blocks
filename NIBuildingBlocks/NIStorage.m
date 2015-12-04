//
//  NIStorage.m
//  NIBuildingBlocks
//
//  Created by Alessandro Volz on 10/28/15.
//  Copyright © 2015 Spaltenstein Natural Image. All rights reserved.
//

#import "NIStorage.h"
#import <objc/runtime.h>

@interface NIStorage ()

@property (retain, readwrite) NSURL* location;

@end

@implementation NIStorage

@synthesize location = _location;

- (instancetype)initWithBundle:(NSBundle*)bundle {
    return [self initWithLocation:[self.class defaultLocationForBundle:bundle]];
}

- (instancetype)initWithLocation:(NSURL*)location {
    if (!(self = [super init]))
        return nil;
    
    self.location = location;
    
    return self;
}

- (void)dealloc {
    self.location = nil;
    [super dealloc];
}

- (NSURL*)directoryForKey:(NSString*)keyPath {
    return [self directoryForKey:keyPath create:YES];
}

- (NSURL*)directoryForKey:(NSString*)keyPath create:(BOOL)create {
    if (!keyPath)
        return nil;
    NSArray* keyComponents = [keyPath componentsSeparatedByString:@"."];
    
    NSURL* url = self.location;
    for (NSString* keyComponent in keyComponents)
        url = [url URLByAppendingPathComponent:keyComponent isDirectory:YES];
    
    if (create)
        [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:NULL];
    
    return url;
}

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
    
    [NIStorageLocators sortUsingComparator:^NSComparisonResult(Class c1, Class c2) { // prioritize classes inside the bundle argument
        NSBundle *b1 = [NSBundle bundleForClass:c1], *b2 = [NSBundle bundleForClass:c2];
        if (b1 == b2) return NSOrderedSame;
        if (b1 == bundle) return NSOrderedAscending;
        if (b2 == bundle) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
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
            NSString* bundleName = bundle.infoDictionary[CFBundleName];
            if (bundleName.length)
                [sdirs addObject:bundleName];
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
