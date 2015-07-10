//
//  NIMPRAnnotateTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/10/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateTool.h"

@implementation NIMPRAnnotateTool

@synthesize annotation = _annotation;

- (NSArray*)cursors {
    return @[ NSCursor.crosshairCursor, NSCursor.crosshairCursor ];
}

@end
