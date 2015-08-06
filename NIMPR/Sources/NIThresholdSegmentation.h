//
//  NIThresholdSegmentation.h
//  NIMPR
//
//  Created by Alessandro Volz on 8/5/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NISegmentationAlgorithm.h"

@interface NIThresholdSegmentation : NSObject <NISegmentationAlgorithm> {
    CGFloat _lowerThreshold, _higherThreshold;
}

@property CGFloat lowerThreshold, higherThreshold;

@end

@interface NIThresholdIntervalSegmentation : NIThresholdSegmentation

@property CGFloat interval;

@end



