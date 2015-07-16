//
//  NSBezierLine+NIMPR.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/16/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSBezierPath (NIMPR)

- (BOOL)intersectsRect:(NSRect)rect;

@end
