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
    NIVolumeData* _volume;
    NSLock* _volumeLock;
}

@property(retain, nonatomic) NIMask* mask;
@property(nonatomic) NIAffineTransform modelToDicomTransform;
@property(retain, nonatomic) NIVolumeData* volume;

- (id)initWithMask:(NIMask*)mask transform:(NIAffineTransform)modelToDicomTransform;
- (id)initWithVolume:(NIVolumeData*)volume;

@end
