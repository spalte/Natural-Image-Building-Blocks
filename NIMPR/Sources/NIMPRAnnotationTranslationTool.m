//
//  NIMPRAnnotationTranslationTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/22/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRAnnotationTranslationTool.h"
#import "NIAnnotation.h"
#import "NIMPRView.h"

@implementation NIMPRAnnotationTranslationTool

- (BOOL)view:(NIMPRView*)view mouseDragged:(NSEvent*)event {
    [super view:view mouseDragged:event];
    
    for (NIAnnotation* a in view.selectedAnnotations)
        [a translate:NIVectorSubtract(self.currentLocationVector, self.previousLocationVector)];
    
    return YES;
}

- (NSArray*)cursorsForView:(NIMPRView*)view {
    return @[ NSCursor.openHandCursor, NSCursor.closedHandCursor ];
}

@end
