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
#import "NIMPRAnnotationSelectionTool.h"
#import "NIMPRAnnotatePointTool.h"
#import "NIMPRAnnotateSegmentTool.h"
#import "NIMPRAnnotatePolyTool.h"
#import "NIMPRAnnotateRectangleTool.h"
#import "NIMPRAnnotateEllipseTool.h"
#import "NSMenu+NIMPR.h"



//@interface ASDView : NSView
//
//@end
//
//@implementation ASDView
//
//- (void)drawRect:(NSRect)dirtyRect {
//    [super drawRect:dirtyRect];
//    [NSColor.redColor set];
//    [[NSBezierPath bezierPathWithRect:self.bounds] fill];
//}
//
//@end




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
NSString* const NIMPRControllerToolbarItemIdentifierLayouts = @"NIMPRLayouts";
NSString* const NIMPRControllerToolbarItemIdentifierProjection = @"NIMPRProjection";

+ (NSArray*)tools {
    return [self.class.navigationTools arrayByAddingObjectsFromArray:self.class.annotationTools];
}

+ (NSArray*)navigationTools {
    static NSArray* tools = nil;
    if (!tools)
        tools = [@[[NIMPRToolRecord recordWithLabel:NSLocalizedString(@"WL/WW", nil) image:[NIMPR image:@"Tool-WLWW"] tag:NIMPRToolWLWW handler:NIMPRWLWWTool.class],
                   [NIMPRToolRecord recordWithLabel:NSLocalizedString(@"Move", nil) image:[NIMPR image:@"Tool-Move"] tag:NIMPRToolMove handler:NIMPRMoveTool.class],
                   [NIMPRToolRecord recordWithLabel:NSLocalizedString(@"Zoom", nil) image:[NIMPR image:@"Tool-Zoom"] tag:NIMPRToolZoom handler:NIMPRZoomTool.class],
                   [NIMPRToolRecord recordWithLabel:NSLocalizedString(@"Rotate", nil) image:[NIMPR image:@"Tool-Rotate"] tag:NIMPRToolRotate handler:NIMPRRotateTool.class],
                   [NIMPRToolRecord recordWithLabel:NSLocalizedString(@"Interact", nil) image:[NSCursor.pointingHandCursor image] tag:NIMPRToolInteract handler:NIMPRAnnotationSelectionTool.class]] retain];
    return tools;
}

+ (NSArray*)annotationTools {
    static NSArray* tools = nil;
    if (!tools)
        tools = [@[[NIMPRToolRecord recordWithLabel:NSLocalizedString(@"Point", nil) image:[NIMPR image:@"Tool-Annotate-Point"] tag:NIMPRToolAnnotatePoint handler:NIMPRAnnotatePointTool.class],
                   [NIMPRToolRecord recordWithLabel:NSLocalizedString(@"Segment", nil) image:[NIMPR image:@"Tool-Annotate-Segment"] tag:NIMPRToolAnnotateSegment handler:NIMPRAnnotateSegmentTool.class],
                   [NIMPRToolRecord recordWithLabel:NSLocalizedString(@"Poly", nil) image:[NIMPR image:@"Tool-Annotate-Poly"] tag:NIMPRToolAnnotateSegment handler:NIMPRAnnotatePolyTool.class],
                   [NIMPRToolRecord recordWithLabel:NSLocalizedString(@"Rectangle", nil) image:[NIMPR image:@"Tool-Annotate-Rectangle"] tag:NIMPRToolAnnotateRectangle handler:NIMPRAnnotateRectangleTool.class],
                   [NIMPRToolRecord recordWithLabel:NSLocalizedString(@"Ellipse", nil) image:[NIMPR image:@"Tool-Annotate-Ellipse"] tag:NIMPRToolAnnotateEllipse handler:NIMPRAnnotateEllipseTool.class] ] retain];
    return tools;
}

+ (NIMPRToolRecord*)defaultTool {
    return self.class.navigationTools[0];
}

+ (NSArray*)layouts {
    static NSArray* modes = nil;
    if (!modes)
        modes = [@[[NIMPRLayoutRecord recordWithLabel:NSLocalizedString(@"Classic", nil) image:[NIMPR image:@"Layout-Classic"] tag:NIMPRLayoutClassic],
                   [NIMPRLayoutRecord recordWithLabel:NSLocalizedString(@"Vertical", nil) image:[NIMPR image:@"Layout-Vertical"] tag:NIMPRLayoutVertical],
                   [NIMPRLayoutRecord recordWithLabel:NSLocalizedString(@"Horizontal", nil) image:[NIMPR image:@"Layout-Horizontal"] tag:NIMPRLayoutHorizontal]] retain];
    return modes;
}

+ (NIMPRLayoutRecord*)defaultLayout {
    return self.class.layouts[0];
}

- (Class)toolClassForTag:(NIMPRToolTag)tag {
    return [[[self.class.tools filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NIMPRToolRecord* tool, NSDictionary* bindings) {
        return (tool.tag == tag);
    }]] lastObject] handler];
}

- (NSArray*)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return @[ NSToolbarSpaceItemIdentifier,
              NSToolbarFlexibleSpaceItemIdentifier,
              NIMPRControllerToolbarItemIdentifierTools,
              NIMPRControllerToolbarItemIdentifierAnnotationTools,
              NIMPRControllerToolbarItemIdentifierLayouts,
              NIMPRControllerToolbarItemIdentifierProjection,
              @"Test" ];
}

- (NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return @[ NIMPRControllerToolbarItemIdentifierTools,
              NIMPRControllerToolbarItemIdentifierAnnotationTools,
              NSToolbarSpaceItemIdentifier,
              NIMPRControllerToolbarItemIdentifierProjection,
              NSToolbarFlexibleSpaceItemIdentifier,
              NIMPRControllerToolbarItemIdentifierLayouts,
              @"Test" ];
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)identifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    
    NSDictionary* tas = @{ NIMPRControllerToolbarItemIdentifierTools: @[ NSLocalizedString(@"Navigation", nil), self.class.navigationTools ],
                           NIMPRControllerToolbarItemIdentifierAnnotationTools: @[ NSLocalizedString(@"Annotations", nil), self.class.annotationTools ] };
    
    if ([identifier isEqualToString:NIMPRControllerToolbarItemIdentifierLayouts]) {
        item.label = NSLocalizedString(@"Layout", nil);
        
        NSSegmentedControl* seg = [[[NSSegmentedControl alloc] initWithFrame:NSZeroRect] autorelease];
        NSSegmentedCell* cell = [seg cell];
        seg.toolTip = item.label;
        
        NSMenu* menu = [[[NSMenu alloc] init] autorelease];
        item.menuFormRepresentation = [[NSMenuItem alloc] initWithTitle:item.label action:nil keyEquivalent:@""];
        item.menuFormRepresentation.submenu = menu;
        
        NSArray* layouts = self.class.layouts;
        
        seg.segmentCount = layouts.count;
        [layouts enumerateObjectsUsingBlock:^(NIMPRLayoutRecord* r, NSUInteger i, BOOL* stop) {
            [cell setTag:r.tag forSegment:i];
            [seg setImage:r.image forSegment:i];
            [menu addItem:[NIMPRBlockMenuItem itemWithTitle:r.label keyEquivalent:@"" block:^{
                self.viewsLayout = r.tag;
            }]];
        }];
        
        cell.controlSize = NSSmallControlSize;
        [seg sizeToFit];
        item.view = seg;
        
        [cell bind:@"selectedTag" toObject:self withKeyPath:@"viewsLayout" options:0];
    }
    
    NSArray* ta = [tas objectForKey:identifier];
    if (ta) {
        item.label = ta[0];
        
        NIMPRSegmentedControl* seg = [[[NIMPRSegmentedControl alloc] initWithFrame:NSZeroRect] autorelease];
        NIMPRSegmentedCell* cell = [seg cell];
        seg.toolTip = item.label;
        
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
        
        [cell bind:@"selectedTag" toObject:self withKeyPath:@"ltoolTag" options:0];
        [cell bind:@"rselectedTag" toObject:self withKeyPath:@"rtoolTag" options:0];
    }
    
    if ([identifier isEqualToString:NIMPRControllerToolbarItemIdentifierProjection]) {
        item.label = NSLocalizedString(@"Projection", nil);
        
        NSButton* checkbox = [[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
        checkbox.translatesAutoresizingMaskIntoConstraints = NO;
        checkbox.controlSize = NSMiniControlSize;
        checkbox.title = nil;
        [checkbox.cell setButtonType:NSSwitchButton];
        [checkbox sizeToFit];
        [checkbox bind:@"value" toObject:self withKeyPath:@"projectionFlag" options:0];

        NSPopUpButton* popup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect];
        popup.translatesAutoresizingMaskIntoConstraints = NO;
        [popup.menu addItemWithTitle:NSLocalizedString(@"MIP", nil) alt:NSLocalizedString(@"MIP - Maximum intensity projection", nil) tag:NIProjectionModeMIP];
        [popup.menu addItemWithTitle:NSLocalizedString(@"MinIP", nil) alt:NSLocalizedString(@"MinIP - Minimum intensity projection", nil) tag:NIProjectionModeMinIP];
        [popup.menu addItemWithTitle:NSLocalizedString(@"Mean", nil) tag:NIProjectionModeMean];
        [popup.cell setControlSize:NSMiniControlSize];
        popup.font = [NSFont controlContentFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]];
        popup.toolTip = NSLocalizedString(@"Projection mode", nil);
        [popup sizeToFit];
        [popup bind:@"selectedTag" toObject:self withKeyPath:@"projectionMode" options:0];
        [popup bind:@"enabled" toObject:self withKeyPath:@"projectionFlag" options:0];
        
        NSSlider* slider = [[[NSSlider alloc] initWithFrame:NSZeroRect] autorelease]; // NSMakeRect(0, 0, 100, 20)
        slider.translatesAutoresizingMaskIntoConstraints = NO;
        slider.minValue = 0; slider.maxValue = 1;
        slider.numberOfTickMarks = 10;
        slider.allowsTickMarkValuesOnly = NO;
        slider.doubleValue = 0;
        [slider.cell setControlSize:NSMiniControlSize];
        slider.toolTip = NSLocalizedString(@"Slab width", nil);
        [slider sizeToFit];
        [slider bind:@"value" toObject:self withKeyPath:@"slabWidth" options:0];
        [slider bind:@"enabled" toObject:self withKeyPath:@"projectionFlag" options:0];
        
        NSView* view = [[[NSView alloc] initWithFrame:NSZeroRect] autorelease];
        [view addSubview:checkbox];
        [view addSubview:popup];
        [view addSubview:slider];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[checkbox]-d-[popup]-0-|" options:0 metrics:@{@"d":@(-4)} views:NSDictionaryOfVariableBindings(checkbox, popup)]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[slider]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(slider)]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[popup]-d-[slider]-0-|" options:0 metrics:@{@"d":@(-1)} views:NSDictionaryOfVariableBindings(popup, slider)]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:checkbox attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:popup attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];

        [view setFrameSize:NSMakeSize(100, 28)];
        [view layout];
        
        item.view = view;
    }
    
    if ([identifier isEqualToString:@"Test"]) {
        item.label = item.toolTip = identifier;
        item.image = [NSImage imageNamed:@"NSRevealFreestandingTemplate"];
        item.action = @selector(test:);
    }
    
    item.autovalidates = NO;
    return item;
}

//- (void)toolbarWillAddItem:(NSNotification*)notification {
//    NSToolbarItem* item = notification.userInfo[@"item"];
//    
//    NSLog(@"added %@", item.itemIdentifier);
//    
//    if ([item.itemIdentifier isEqualToString:NIMPRControllerToolbarItemIdentifierProjection]) {
//        
//    }
//}

@end

@implementation NIMPRToolRecord

@synthesize tag = _tag;
@synthesize label = _label;
@synthesize image = _image;
@synthesize handler = _handler;
@synthesize submenu = _submenu;

+ (instancetype)recordWithLabel:(NSString*)label image:(NSImage*)image tag:(NIMPRToolTag)tag handler:(Class)handler {
    NIMPRToolRecord* r = [[[self.class alloc] init] autorelease];
    r.label = label;
    r.image = image;
    r.tag = tag;
    r.handler = handler;
    return r;
}

- (void)dealloc {
    self.label = nil;
    self.image = nil;
    self.submenu = nil;
    [super dealloc];
}

@end

@implementation NIMPRLayoutRecord

@synthesize label = _label;
@synthesize image = _image;
@synthesize tag = _tag;

+ (instancetype)recordWithLabel:(NSString *)label image:(NSImage *)image tag:(NIMPRLayoutTag)tag {
    NIMPRLayoutRecord* r = [[[self.class alloc] init] autorelease];
    r.label = label;
    r.image = image;
    r.tag = tag;
    return r;
}

- (void)dealloc {
    self.label = nil;
    self.image = nil;
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
