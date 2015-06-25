//
//  OurPluginClass.m
//  XMLRPC Dicom Send
//
//  Created by Alessandro Volz on 3/24/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRPlugin.h"
#import "NIMPR.h"
#import "NIMPRController.h"
#import <NIBuildingBlocks/NIBuildingBlocks.h>

static NIMPRPlugin* instance = nil;

@implementation NIMPRPlugin

+ (NIMPRPlugin*)instance {
    return instance;
}

- (void)initPlugin {
    instance = self;
}

- (void)dealloc {
    instance = nil;
    [super dealloc];
}

- (long)filterImage:(NSString*)menuName {
    NIVolumeData* data = [viewerController NIVolumeDataForMovieIndex:viewerController.curMovieIndex];
    
    NIMPRController* mpr = [[NIMPRController alloc] initWithData:data window:viewerController.curWL:viewerController.curWW];
    mpr.displayScaleBars = mpr.displayOrientationLabels = YES;
    
    [mpr.window makeKeyAndOrderFront:self];
    
    return 0;
}

@end
