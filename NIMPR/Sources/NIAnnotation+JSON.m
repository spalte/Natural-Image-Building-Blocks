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
#import "NIRectangleAnnotation.h"
#import "NIEllipseAnnotation.h"
#import "NIImageAnnotation.h"
#import "NIPolyAnnotation.h"
#import "NIMaskAnnotation.h"

@implementation NIAnnotation (JSON)

+ (void)load {
    [NIJSON setName:@"point-annotation" forClass:NIPointAnnotation.class];
    [NIJSON setName:@"segment-annotation" forClass:NISegmentAnnotation.class];
    [NIJSON setName:@"rectangle-annotation" forClass:NIRectangleAnnotation.class];
    [NIJSON setName:@"ellipse-annotation" forClass:NIEllipseAnnotation.class];
    [NIJSON setName:@"image-annotation" forClass:NIImageAnnotation.class];
    [NIJSON setName:@"poly-annotation" forClass:NIPolyAnnotation.class];
    [NIJSON setName:@"mask-annotation" forClass:NIMaskAnnotation.class];
}

@end
