//
//  OurPluginClass.m
//  XMLRPC Dicom Send
//
//  Created by Alessandro Volz on 3/24/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPR.h"
#import "CPRMPRController.h"
#import "Additions.h"
#import <OsiriXAPI/CPRVolumeData.h>
#import <OsiriXAPI/pluginSDKAdditions.h>

@interface CPRMPR ()

@property(retain,readwrite) NSBundle* bundle;

@end

static CPRMPR* instance = nil;

@implementation CPRMPR

@synthesize bundle = _bundle;

+ (CPRMPR*)instance {
    return instance;
}

+ (NSBundle*)bundle {
    return self.instance.bundle;
}

- (void)initPlugin {
    instance = self;
    self.bundle = [NSBundle bundleForClass:self.class];
    taviSwizzles();
}

- (void)dealloc {
    self.bundle = nil;
    instance = nil;
    [super dealloc];
}

- (long)filterImage:(NSString*)menuName {
    CPRVolumeData* data = [viewerController CPRVolumeDataForMovieIndex:viewerController.curMovieIndex];
    
    CPRMPRController* mpr = [[CPRMPRController alloc] initWithData:data];
    mpr.windowLevel = viewerController.curWL;
    mpr.windowWidth = viewerController.curWW;
    mpr.displayScaleBars = mpr.displayOrientationLabels = YES;
    
    [mpr.window makeKeyAndOrderFront:self];
    
    return 0;
}

@end
