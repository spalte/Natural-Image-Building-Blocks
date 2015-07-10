//
//  NIMPRAnnotatedGeneratorRequestView.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/8/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <NIBuildingBlocks/NIBuildingBlocks.h>

@class NIAnnotation;

@interface NIAnnotatedGeneratorRequestView : NIGeneratorRequestView {
    CALayer* _annotationsLayer;
    NSMutableSet* _annotations;
}

@property (readonly, retain) CALayer* annotationsLayer;

- (NSMutableSet*)publicAnnotations;

//- (void)addAnnotation:(NIAnnotation*)object;
//- (void)removeAnnotation:(NIAnnotation*)object;

- (CGFloat)maximumDistanceToPlane;

@end

