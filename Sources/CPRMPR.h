//
//  OurPluginClass.h
//  XMLRPC Dicom Send
//
//  Created by Alessandro Volz on 3/24/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <OsiriXAPI/PluginFilter.h>

@interface CPRMPR : PluginFilter {
    NSBundle* _bundle;
}

@property(retain,readonly) NSBundle* bundle;

+ (CPRMPR*)instance;
+ (NSBundle*)bundle;

@end
