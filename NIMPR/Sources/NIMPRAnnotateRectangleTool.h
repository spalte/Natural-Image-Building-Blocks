//
//  NIMPRAnnotateRectangleTool.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/13/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateTool.h"

@class NIRectangleAnnotation;

@interface NIMPRAnnotateRectangleTool : NIMPRAnnotateTool

@property(retain) NIRectangleAnnotation* annotation;

@end
