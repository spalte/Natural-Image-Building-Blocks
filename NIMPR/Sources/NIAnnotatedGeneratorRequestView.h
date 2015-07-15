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

- (CGFloat)maximumDistanceToPlane;

- (NIAnnotation*)annotationClosestToPoint:(NSPoint)location closestPoint:(NSPoint*)closestPoint distance:(CGFloat*)distance;

@end

