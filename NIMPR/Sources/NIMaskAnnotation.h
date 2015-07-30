//
//  NIMaskAnnotation.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/13/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotation.h"
#import <NIBuildingBlocks/NIMask.h>

@interface NIMaskAnnotation : NIAnnotation <NITransformAnnotation> {
    NIMask* _mask;
    NIAffineTransform _modelToDicomTransform;
}

@property(retain) NIMask* mask;
@property NIAffineTransform modelToDicomTransform;

- (id)initWithMask:(NIMask*)mask transform:(NIAffineTransform)modelToDicomTransform;

@end
