//
//  OurPluginClass.h
//  XMLRPC Dicom Send
//
//  Created by Alessandro Volz on 3/24/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#import <OsiriXAPI/PluginFilter.h>

#pragma clang diagnostic pop

@interface NIMPRPlugin : PluginFilter

+ (NIMPRPlugin*)instance;

@end
