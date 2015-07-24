//
//  NIBezierSurfaceAnnotation.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/23/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotation.h"
#import <NIBuildingBlocks/NIGeometry.h>

struct NIBezierPatch { // bicubic
    NIVector p00, p01, p02, p03;
    NIVector p10, p11, p12, p13;
    NIVector p20, p21, p22, p23;
    NIVector p30, p31, p32, p33;
};
typedef struct NIBezierPatch NIBezierPatch;

@interface NIBezierSurfaceAnnotation : NIAnnotation
    
// work in progress......

@end
