//
//  NISegmentationAlgorithm.h
//  NIMPR
//
//  Created by Alessandro Volz on 8/5/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NIVolumeData, NIMaskAnnotation;

@protocol NISegmentationAlgorithm <NSObject>

- (NSString*)name;
- (NSString*)shortName;
- (NSViewController*)viewController;

- (void)processWithSeeds:(NSArray*)seedIndexes volume:(NIVolumeData*)volume annotation:(NIMaskAnnotation*)annotation operation:(NSOperation*)operation;

@end


