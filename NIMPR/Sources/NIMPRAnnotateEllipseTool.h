//
//  NIMPRAnnotateEllipseTool.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/10/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateTool.h"

@class NIEllipseAnnotation;

@interface NIMPRAnnotateEllipseTool : NIMPRValidatedAnnotateTool

@property(retain) NIEllipseAnnotation* annotation;

@end
