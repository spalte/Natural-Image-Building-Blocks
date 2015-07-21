//
//  NIMPRAnnotateLineTool.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/10/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateTool.h"

@class NISegmentAnnotation;

@interface NIMPRAnnotateSegmentTool : NIMPRValidatedAnnotateTool

@property(retain) NISegmentAnnotation* annotation;

@end
