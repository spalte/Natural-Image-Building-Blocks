//
//  NIMPRAnnotationSelectionTool.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/15/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRTool.h"
#import "NIAnnotation.h"

typedef enum : NSUInteger {
    NIMPRAnnotationSelectionInteractionToolMode,
    NIMPRAnnotationMoveInteractionToolMode,
} NIMPRAnnotationInteractionToolMode;

@interface NIMPRAnnotationInteractionTool : NIMPRTool {
    NIMPRAnnotationInteractionToolMode _mode;
}

@property NIMPRAnnotationInteractionToolMode mode;

@end
