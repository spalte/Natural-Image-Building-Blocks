//
//  CPRMPRRotateTool.h
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRTool.h"

@interface CPRMPRRotateTool : CPRMPRTool {
    N3Vector _previousLocationVector;
}

@property(readonly) N3Vector previousLocationVector;

- (void)view:(CPRMPRView*)view rotate:(CGFloat)rads;

@end
