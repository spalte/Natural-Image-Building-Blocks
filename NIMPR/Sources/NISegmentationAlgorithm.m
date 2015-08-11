//
//  NISegmentationAlgorithm.m
//  NIMPR
//
//  Created by Alessandro Volz on 8/5/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NISegmentationAlgorithm.h"

@implementation NISegmentationAlgorithm

+ (NSSet*)keyPathsForValuesAffectingSegmentationAlgorithm {
    return [NSSet set];
}

- (NSString*)name {
    return nil;
}

- (NSString*)shortName {
    return nil;
}

- (NSViewController*)viewController {
    return nil;
}

- (void)processWithSeeds:(NSArray*)seedIndexes volume:(NIVolumeData*)volume annotation:(NIMaskAnnotation*)annotation operation:(NSOperation*)operation {
}


@end