//
//  NIMPRAnnotatePointTool.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/8/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateTool.h"

@class NIPointAnnotation;

@interface NIMPRAnnotatePointTool : NIMPRAnnotateTool

@property(retain) NIPointAnnotation* annotation;

@end
