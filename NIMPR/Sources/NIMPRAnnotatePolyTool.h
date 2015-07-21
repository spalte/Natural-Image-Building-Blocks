//
//  NIMPRAnnotatePolyTool.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/21/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateTool.h"

@class NIPolyAnnotation;

@interface NIMPRAnnotatePolyTool : NIMPRAnnotateTool

@property(retain) NIPolyAnnotation* annotation;

@end
