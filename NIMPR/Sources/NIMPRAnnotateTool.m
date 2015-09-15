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

- (instancetype)initWithViewer:(NIMPRWindowController*)viewer {
    if ((self = [super initWithViewer:viewer])) {
        [self addObserver:self forKeyPath:@"annotation" options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIMPRAnnotateTool.class];
    }
    
    return self;
}

- (void)dealloc {
    self.annotation = nil;
    [self removeObserver:self forKeyPath:@"annotation" context:NIMPRAnnotateTool.class];
    [super dealloc];
}

static NSString* const NIMPRAnnotateToolAnnotationRemovalKey = @"NIMPRAnnotateToolAnnotationRemoval";

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != NIMPRAnnotateTool.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"annotation"]) {
        [self retain:[[change[NSKeyValueChangeNewKey] if:NIAnnotation.class] observeNotification:NIAnnotationRemovedNotification block:^(NSNotification* n) {
            self.annotation = nil;
        }] forKey:NIMPRAnnotateToolAnnotationRemovalKey];
    }
}

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise confirm:(void(^)())confirm {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^{
        if (confirm)
            confirm();
        if (self.annotation)
            [view.mutableSelectedAnnotations set:self.annotation];
    }];
}

- (NSArray*)cursorsForView:(NIMPRView*)view {
    return @[ NSCursor.crosshairCursor, NSCursor.crosshairCursor ];
}

- (void)drawInView:(NIMPRView *)view {
    if (!view.displayAnnotations && self.annotation)
        [self.annotation drawInView:view cache:nil];
}

@end

@implementation NIMPRValidatedAnnotateTool

- (BOOL)view:(NIMPRView *)view mouseUp:(NSEvent *)event {
    BOOL r = [super view:view mouseUp:event];
    
    if ([self.annotation isKindOfClass:NIBezierPathAnnotation.class]) { // TODO: this is no good...
        NSRect bounds = [[[self.annotation NIBezierPathForSlabView:view complete:YES] NSBezierPath] bounds];
        if (bounds.size.width < 1 && bounds.size.height < 1) {
            [view.mutableAnnotations removeObject:self.annotation];
            self.annotation = nil;
        }
    }
    
    self.annotation = nil;
    
    return r;
}

@end