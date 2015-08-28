//
//  NIAnnotation+JSON.m
//  NIMPR
//
//  Created by Alessandro Volz on 8/28/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotation+JSON.h"
#import "NIJSON.h"

#import "NIPointAnnotation.h"
#import "NISegmentAnnotation.h"
#import "NIEllipseAnnotation.h"
#import "NIPolyAnnotation.h"
#import "NIMaskAnnotation.h"

@implementation NIAnnotation (JSON)

+ (void)load {
    [NIJSON setName:@"point" forClass:NIPointAnnotation.class];
    [NIJSON setName:@"segment" forClass:NISegmentAnnotation.class];
    [NIJSON setName:@"rectangle" forClass:NIRectangleAnnotation.class];
    [NIJSON setName:@"ellipse" forClass:NIEllipseAnnotation.class];
    [NIJSON setName:@"poly" forClass:NIPolyAnnotation.class];
    [NIJSON setName:@"mask" forClass:NIMaskAnnotation.class];
}

@end
