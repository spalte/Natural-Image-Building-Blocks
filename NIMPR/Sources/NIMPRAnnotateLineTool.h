//
//  NIMPRAnnotateLineTool.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/10/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateTool.h"

@class NILineAnnotation;

@interface NIMPRAnnotateLineTool : NIMPRAnnotateTool

@property(retain) NILineAnnotation* annotation;

@end
