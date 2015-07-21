//
//  NIMPRController+Toolbar.m
//  NIMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRController+Toolbar.h"
#import "NIMPRController+Private.h"
#import "NIMPRWindow.h"
#import "NIMPR.h"
#import "NIMPRWLWWTool.h"
#import "NIMPRMoveTool.h"
#import "NIMPRZoomTool.h"
#import "NIMPRRotateTool.h"
#import "NIMPRAnnotationInteractionTool.h"
#import "NIMPRAnnotatePointTool.h"
#import "NIMPRAnnotateSegmentTool.h"
#import "NIMPRAnnotatePolyTool.h"
#import "NIMPRAnnotateRectangleTool.h"
#import "NIMPRAnnotateEllipseTool.h"
#import "NSMenu+NIMPR.h"

@interface NIMPRToolRecord : NSObject {
    NIMPRToolTag _tag;
    NSString* _label;
    NSImage* _image;
    Class _handler;
    NSMenu* _submenu;
}

@property NIMPRToolTag tag;
@property(retain) NSString* label;
@property(retain) NSImage* image;
@property Class handler;
@property(retain) NSMenu* submenu;

+ (instancetype)toolWithTag:(NIMPRToolTag)tag label:(NSString*)label image:(NSImage*)image handler:(Class)handler;

@end

@class NIMPRSegmentedCell;

@interface NIMPRSegmentedControl : NSSegmentedControl

- (NIMPRSegmentedCell*)cell;

@end

@interface NIMPRSegmentedCell : NSSegmentedCell {
    NSInteger _rselectedTag;
    NSMutableArray* _segments;
    NSRect _rightMouseFrame;
    BOOL _rightMouseInside;
}

@property NSInteger rselectedTag;
@property(retain) NSMutableArray* segments;
@property NSRect rightMouseFrame;
@property BOOL rightMouseInside;

- (NSRect)boundsForSegment:(NSInteger)s inView:(NIMPRSegmentedControl*)view;

@end

@implementation NIMPRController (Toolbar)

NSString* const NIMPRControllerToolbarItemIdentifierTools = @"NIMPRTools";
NSString* const NIMPRControllerToolbarItemIdentifierAnnotationTools = @"NIMPRAnnotationTools";
NSString* const NIMPRControllerToolbarItemIdentifierSlabWidth = @"NIMPRSlabWidth";

- (NSArray*)tools {
    return [self.navigationTools arrayByAddingObjectsFromArray:self.annotationTools];
}

- (NSArray*)navigationTools {
    static NSArray* tools = nil;
    if (!tools) tools = [@[ [NIMPRToolRecord toolWithTag:NIMPRToolWLWW label:NSLocalizedString(@"WL/WW", nil) image:[NIMPR image:@"Tool-WLWW"] handler:NIMPRWLWWTool.class],
                            [NIMPRToolRecord toolWithTag:NIMPRToolMove label:NSLocalizedString(@"Move", nil) image:[NIMPR image:@"Tool-Move"] handler:NIMPRMoveTool.class],
                            [NIMPRToolRecord toolWithTag:NIMPRToolZoom label:NSLocalizedString(@"Zoom", nil) image:[NIMPR image:@"Tool-Zoom"] handler:NIMPRZoomTool.class],
                            [NIMPRToolRecord toolWithTag:NIMPRToolRotate label:NSLocalizedString(@"Rotate", nil) image:[NIMPR image:@"Tool-Rotate"] handler:NIMPRRotateTool.class],
                            [NIMPRToolRecord toolWithTag:NIMPRToolInteract label:NSLocalizedString(@"Interact", nil) image:[NSCursor.pointingHandCursor image] handler:NIMPRAnnotationInteractionTool.class] ] retain];
    return tools;
}

- (NSArray*)annotationTools {
    static NSArray* tools = nil;
    if (!tools) tools = [@[ [NIMPRToolRecord toolWithTag:NIMPRToolAnnotatePoint label:NSLocalizedString(@"Point", nil) image:[NIMPR image:@"Tool-Annotate-Point"] handler:NIMPRAnnotatePointTool.class],
                            [NIMPRToolRecord toolWithTag:NIMPRToolAnnotateSegment label:NSLocalizedString(@"Segment", nil) image:[NIMPR image:@"Tool-Annotate-Segment"] handler:NIMPRAnnotateSegmentTool.class],
                            [NIMPRToolRecord toolWithTag:NIMPRToolAnnotatePoly label:NSLocalizedString(@"Poly", nil) image:[NIMPR image:@"Tool-Annotate-Poly"] handler:NIMPRAnnotatePolyTool.class],
                            [NIMPRToolRecord toolWithTag:NIMPRToolAnnotateRectangle label:NSLocalizedString(@"Rectangle", nil) image:[NIMPR image:@"Tool-Annotate-Rectangle"] handler:NIMPRAnnotateRectangleTool.class],
                            [NIMPRToolRecord toolWithTag:NIMPRToolAnnotateEllipse label:NSLocalizedString(@"Ellipse", nil) image:[NIMPR image:@"Tool-Annotate-Ellipse"] handler:NIMPRAnnotateEllipseTool.class] ] retain];
    return tools;
}

- (Class)toolClassForTag:(NIMPRToolTag)tag {
    return [[[self.tools filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NIMPRToolRecord* tool, NSDictionary* bindings) {
        return (tool.tag == tag);
    }]] lastObject] handler];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return @[ NIMPRControllerToolbarItemIdentifierTools, NIMPRControllerToolbarItemIdentifierSlabWidth ];
}

- (NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return @[ NIMPRControllerToolbarItemIdentifierTools, NIMPRControllerToolbarItemIdentifierAnnotationTools, NSToolbarSpaceItemIdentifier, NIMPRControllerToolbarItemIdentifierSlabWidth, @"Test" ];
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)identifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    
    NSDictionary* tas = @{ NIMPRControllerToolbarItemIdentifierTools: @[ NSLocalizedString(@"Navigation", nil), self.navigationTools ],
                           NIMPRControllerToolbarItemIdentifierAnnotationTools: @[ NSLocalizedString(@"Annotations", nil), self.annotationTools ] };
    
    NSArray* ta = [tas objectForKey:identifier];
    if (ta) {
        item.label = ta[0];
        
        NIMPRSegmentedControl* seg = [[[NIMPRSegmentedControl alloc] initWithFrame:NSZeroRect] autorelease];
        NIMPRSegmentedCell* cell = [seg cell];
        
        NSMenu* menu = [[[NSMenu alloc] init] autorelease];
        item.menuFormRepresentation = [[NSMenuItem alloc] initWithTitle:ta[0] action:nil keyEquivalent:@""];
        item.menuFormRepresentation.submenu = menu;
        
        seg.segmentCount = [ta[1] count];
        [ta[1] enumerateObjectsUsingBlock:^(NIMPRToolRecord* tool, NSUInteger i, BOOL* stop) {
            [cell setTag:tool.tag forSegment:i];
            [seg setImage:tool.image forSegment:i];
            NSMenuItem* mi = [[NSMenuItem alloc] initWithTitle:tool.label action:nil keyEquivalent:@""];
            mi.tag = tool.tag;
            mi.submenu = tool.submenu;
            [menu addItem:mi];
        }];
        
        cell.controlSize = NSSmallControlSize;
        [seg sizeToFit];
        item.view = seg;
    }
    
    if ([identifier isEqualToString:NIMPRControllerToolbarItemIdentifierSlabWidth]) {
        item.label = NSLocalizedString(@"Slab Width", nil);
        
        NSSlider* slider = [[[NSSlider alloc] initWithFrame:NSZeroRect] autorelease];
        NSSliderCell* cell = slider.cell;
        slider.minValue = 0; slider.maxValue = 1;
        slider.numberOfTickMarks = 10;
        slider.allowsTickMarkValuesOnly = NO;
        slider.doubleValue = 0;
        
        cell.controlSize = NSSmallControlSize;
        slider.frame = NSMakeRect(0, 0, 100, 20);
        item.view = slider;
    }
    
    item.autovalidates = NO;
    return item;
}

- (void)toolbarWillAddItem:(NSNotification*)notification {
    NSToolbarItem* item = notification.userInfo[@"item"];
    
    if ([item.itemIdentifier isEqualToString:NIMPRControllerToolbarItemIdentifierTools] || [item.itemIdentifier isEqualToString:NIMPRControllerToolbarItemIdentifierAnnotationTools]) {
        NIMPRSegmentedControl* seg = (id)item.view;
        [seg.cell bind:@"selectedTag" toObject:self withKeyPath:@"ltoolTag" options:0];
        [seg.cell bind:@"rselectedTag" toObject:self withKeyPath:@"rtoolTag" options:0];
    }
    
    if ([item.itemIdentifier isEqualToString:NIMPRControllerToolbarItemIdentifierSlabWidth]) {
        NSSlider* slider = (id)item.view;
        [slider bind:@"value" toObject:self withKeyPath:@"slabWidth" options:0];
    }
}

@end

@implementation NIMPRToolRecord

@synthesize tag = _tag;
@synthesize label = _label;
@synthesize image = _image;
@synthesize handler = _handler;
@synthesize submenu = _submenu;

+ (instancetype)toolWithTag:(NIMPRToolTag)tag label:(NSString*)label image:(NSImage*)image handler:(Class)handler {
    NIMPRToolRecord* tool = [[[self.class alloc] init] autorelease];
    tool.tag = tag;
    tool.label = label;
    tool.image = image; image.size = NSMakeSize(14,14);
    tool.handler = handler;
    return tool;
}

- (void)dealloc {
    self.label = nil;
    self.image = nil;
    self.submenu = nil;
    [super dealloc];
}

@end

//static NSString* const NIMPRSegment = @"NIMPRSegment";

@implementation NIMPRSegmentedControl

- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.cell = [[[NIMPRSegmentedCell alloc] init] autorelease];
        [self addObserver:self forKeyPath:@"cell.rightMouseInside" options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:NIMPRSegmentedControl.class];
    }
    
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"cell.rightMouseInside" context:NIMPRSegmentedControl.class];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != NIMPRSegmentedControl.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"cell.rightMouseInside"])
        if ([[change[NSKeyValueChangeNewKey] if:NSNumber.class] boolValue] != [[change[NSKeyValueChangeOldKey] if:NSNumber.class] boolValue]) {
            [self setNeedsDisplay];
        }
}

- (NIMPRSegmentedCell*)cell {
    return [super cell];
}

- (BOOL)interceptsToolbarRightMouseEvents {
    return YES;
}

- (void)rightMouseDown:(NSEvent*)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
    
    NSInteger s; NSRect sframe;
    for (s = 0; s < self.segmentCount; ++s) {
        sframe = [self.cell boundsForSegment:s inView:self];
        if (location.x <= NSMaxX(sframe))
            break;
    }
    
//    self.cell.rightMouseFrame = NSMakeRect(px+0, 0, x-px-1, NSHeight(self.bounds)-2);
    self.cell.rightMouseFrame = sframe;
    
    do {
        self.cell.rightMouseInside = NSPointInRect(event.locationInWindow, [self convertRect:self.cell.rightMouseFrame toView:nil]);
        if (event.type == NSRightMouseUp) {
            if (self.cell.rightMouseInside)
                self.cell.rselectedTag = [self.cell tagForSegment:s];
            break;
        }
    } while ((event = [self.window nextEventMatchingMask:NSRightMouseDraggedMask|NSRightMouseUpMask]));
    
    self.cell.rightMouseInside = NO;
    self.cell.rightMouseFrame = NSZeroRect;
}

@end

@interface NSSegmentedCell (Hidden)

- (NSRect)_rectForSegment:(NSInteger)s inFrame:(NSRect)frame;

@end

@implementation NIMPRSegmentedCell

@synthesize rselectedTag = _rselectedTag;
@synthesize segments = _segments;
@synthesize rightMouseFrame = _rightMouseFrame, rightMouseInside = _rightMouseInside;

- (void)dealloc {
    self.segments = nil;
    [super dealloc];
}

- (void)setSegmentCount:(NSInteger)count {
    [super setSegmentCount:count];
    if (!self.segments) self.segments = [NSMutableArray array];
    if (self.segments.count > count) [self.segments removeObjectsInRange:NSMakeRange(count, self.segments.count-count)];
    while (self.segments.count < count)
        [self.segments addObject:[NSMutableDictionary dictionary]];
}

- (NSShadow*)shadowWithColor:(NSColor*)color {
    NSShadow* shadow = [[[NSShadow alloc] init] autorelease];
    shadow.shadowColor = color;
    shadow.shadowOffset = NSMakeSize(0,0);
    shadow.shadowBlurRadius = 2;
    return shadow;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NIMPRSegmentedControl*)view {
    [super drawInteriorWithFrame:cellFrame inView:view];
    if (self.rightMouseInside) {
        [NSGraphicsContext saveGraphicsState];
        [[[NSColor blackColor] colorWithAlphaComponent:0.1] set];
        [NSBezierPath fillRect:self.rightMouseFrame];
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (void)drawSegment:(NSInteger)s inFrame:(NSRect)frame withView:(NIMPRSegmentedControl*)view {
    [super drawSegment:s inFrame:frame withView:view];
    if ([self tagForSegment:s] == self.rselectedTag) {
        [NSGraphicsContext saveGraphicsState];
        frame = NSInsetRect([self boundsForSegment:s inView:view], 2, -1); // NSInsetRect(frame, (NSWidth(view.frame)-view.totalWidth)/(view.segmentCount*2)-1, -2);
        CGFloat size = [NSFont systemFontSizeForControlSize:NSMiniControlSize];
        
        NSMutableParagraphStyle* ps = [[NSMutableParagraphStyle.defaultParagraphStyle mutableCopy] autorelease];
        ps.alignment = NSRightTextAlignment;
        NSString* r = NSLocalizedString(@"R", nil);
        NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin/*|NSStringDrawingUsesFontLeading*/;
        NSDictionary* attributes = @{ NSFontAttributeName: [NSFont systemFontOfSize:size],
                                      NSForegroundColorAttributeName: ([self isSelectedForSegment:s]? [NSColor colorWithCalibratedWhite:0.8 alpha:1] : [NSColor colorWithCalibratedWhite:0.2 alpha:1]),
                                      NSShadowAttributeName: [self shadowWithColor:([self isSelectedForSegment:s]? NSColor.blackColor : NSColor.whiteColor)],
                                      NSParagraphStyleAttributeName: ps };
        
        NSRect rframe = [r boundingRectWithSize:frame.size options:options attributes:attributes];
        [[([self isSelectedForSegment:s]? NSColor.darkGrayColor : NSColor.lightGrayColor) colorWithAlphaComponent:0.5] set];
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(NSMaxX(frame)-rframe.size.width-1, frame.origin.y+2, rframe.size.width+2, rframe.size.height-3)] fill];
        
        [r drawWithRect:frame options:options attributes:attributes];
        
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (NSRect)boundsForSegment:(NSInteger)s inView:(NIMPRSegmentedControl*)view {
    return [self _rectForSegment:s inFrame:view.bounds];
//    CGFloat cellwidth = view.frame.size.width/view.segmentCount;
//    return NSMakeRect(cellwidth*s, 0, cellwidth, view.frame.size.height);
}

@end
