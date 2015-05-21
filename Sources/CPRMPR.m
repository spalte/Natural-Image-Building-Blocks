//
//  OurPluginClass.m
//  XMLRPC Dicom Send
//
//  Created by Alessandro Volz on 3/24/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPR.h"
#import "CPRMPRController.h"
#import <OsiriXAPI/CPRVolumeData.h>
#import <OsiriXAPI/pluginSDKAdditions.h>

@implementation CPRMPR

- (void)initPlugin {
    
}

- (long)filterImage:(NSString*)menuName {
    NSArray* pixList = [viewerController pixList:viewerController.curMovieIndex];
    NSData* volume = [viewerController volumeData:viewerController.curMovieIndex];
    [viewerController computeInterval];
    CPRVolumeData* data = [[[CPRVolumeData alloc] initWithWithPixList:pixList volume:volume] autorelease];
    
    CPRMPRController* mpr = [[CPRMPRController alloc] initWithData:data];
    mpr.windowLevel = viewerController.curWL;
    mpr.windowWidth = viewerController.curWW;
    mpr.displayScaleBars = mpr.displayOrientationLabels = YES;
    
    [mpr.window makeKeyAndOrderFront:self];
    
    return 0;
}

@end
