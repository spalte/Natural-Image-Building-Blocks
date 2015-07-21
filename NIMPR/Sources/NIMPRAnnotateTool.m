//
//  NIMPRAnnotateTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/10/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotateTool.h"
#import "NIBezierPathAnnotation.h"

@implementation NIMPRAnnotateTool

@synthesize annotation = _annotation;

- (NSArray*)cursorsForView:(NIMPRView*)view {
    return @[ NSCursor.crosshairCursor, NSCursor.crosshairCursor ];
}

@end

@implementation NIMPRValidatedAnnotateTool

- (BOOL)view:(NIMPRView *)view mouseUp:(NSEvent *)event {
    BOOL r = [super view:view mouseUp:event];
    
    if ([self.annotation isKindOfClass:NIBezierPathAnnotation.class]) {
        NSRect bounds = [[[self.annotation NIBezierPathForSlabView:view complete:YES] NSBezierPath] bounds];
        if (bounds.size.width < 1 && bounds.size.height < 1)
            [view.mutableAnnotations removeObject:self.annotation];
    }
    
    return r;
}

@end