//
//  NIMPRAnnotateTool.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/10/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRTool.h"

@interface NIMPRAnnotateTool : NIMPRTool {
    id _annotation;
}

@property(retain) id annotation;

@end
