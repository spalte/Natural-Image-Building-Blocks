//
//  NIMPRController+Toolbar.m
//  NIMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRWindowController+Toolbar.h"
#import "NIMPRWindowController+Private.h"
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
#import "NIMPRRegionGrowingTool.h"
#import "NSMenu+NIMPR.h"
#import "NSObject+NI.h"

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

@implementation NIMPRWindowController (Toolbar)

NSString* const NIMPRControllerToolbarItemIdentifierTools = @"NITools";
NSString* const NIMPRControllerToolbarItemIdentifierAnnotationTools = @"NIAnnotationTools";
NSString* const NIMPRControllerToolbarItemIdentifierLayouts = @"NILayouts";
NSString* const NIMPRControllerToolbarItemIdentifierProjection = @"NIProjection";

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
                   [NIMPRToolRecord recordWithLabel:NSLocalizedString(@"Ellipse", nil) image:[NIMPR image:@"Tool-Annotate-Ellipse"] tag:NIMPRToolAnnotateEllipse handler:NIMPRAnnotateEllipseTool.class],
                   [NIMPRToolRecord recordWithLabel:NSLocalizedString(@"Region Growing", nil) image:[NIMPR image:@"Tool-Annotate-RegionGrowing"] tag:NIMPRToolRegionGrowing handler:NIMPRRegionGrowingTool.class]] retain];
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
              @"ImageTest",
              @"MaskTest" ];
}

- (NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return @[ NIMPRControllerToolbarItemIdentifierTools,
              NIMPRControllerToolbarItemIdentifierAnnotationTools,
              NSToolbarSpaceItemIdentifier,
              NIMPRControllerToolbarItemIdentifierProjection,
              NSToolbarFlexibleSpaceItemIdentifier,
              NIMPRControllerToolbarItemIdentifierLayouts,
              @"ImageTest",
              @"MaskTest" ];
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)identifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSString* ident = ([identifier hasPrefix:@"NI"]? [identifier substringFromIndex:2] : identifier);
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"toolbar:itemFor%@%@:", [[ident substringToIndex:1] uppercaseString], [ident substringFromIndex:1]]);
    if ([self respondsToSelector:sel])
        return [self performSelector:sel withObjects:toolbar:@(flag)];
    
    NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];

    NSDictionary* tas = @{ NIMPRControllerToolbarItemIdentifierTools: @[ NSLocalizedString(@"Navigation", nil), self.class.navigationTools ],
                           NIMPRControllerToolbarItemIdentifierAnnotationTools: @[ NSLocalizedString(@"Annotations", nil), self.class.annotationTools ] };
    
    NSArray* ta = [tas objectForKey:identifier];
    if (ta) {
        item.label = item.toolTip = ta[0];
        
        NIMPRSegmentedControl* seg = [[[NIMPRSegmentedControl alloc] initWithFrame:NSZeroRect] autorelease];
        NIMPRSegmentedCell* cell = [seg cell];
        
        NSMenu* menu = [[[NSMenu alloc] init] autorelease];
        item.menuFormRepresentation = [[[NSMenuItem alloc] initWithTitle:ta[0] action:nil keyEquivalent:@""] autorelease];
        item.menuFormRepresentation.submenu = menu;
        
        seg.segmentCount = [ta[1] count];
        [ta[1] enumerateObjectsUsingBlock:^(NIMPRToolRecord* tool, NSUInteger i, BOOL* stop) {
            [cell setTag:tool.tag forSegment:i];
            [seg setImage:tool.image forSegment:i];
            [cell setToolTip:tool.label forSegment:i];
            NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:tool.label action:nil keyEquivalent:@""] autorelease];
            mi.tag = tool.tag;
            mi.submenu = tool.submenu;
            [menu addItem:mi];
        }];
        
        seg.action = @selector(toolbarItemAction:);
        
        cell.controlSize = NSSmallControlSize;
        [seg sizeToFit];
        item.view = seg;
        
        [cell bind:@"selectedTag" toObject:self withKeyPath:@"ltoolTag" options:0];
        [cell bind:@"rselectedTag" toObject:self withKeyPath:@"rtoolTag" options:0];
    }
    
    if ([identifier isEqualToString:@"ImageTest"]) {
        item.label = item.toolTip = identifier;
        item.image = [NSImage imageNamed:@"NSRevealFreestandingTemplate"];
        item.action = @selector(testImage:);
    }
    if ([identifier isEqualToString:@"MaskTest"]) {
        item.label = item.toolTip = identifier;
        item.image = [NSImage imageNamed:@"NSRevealFreestandingTemplate"];
        item.action = @selector(testMask:);
    }
    
    item.autovalidates = NO;
    return item;
}

- (void)toolbarItemAction:(id)sender {
    NSEvent* event = [NSApp currentEvent];
    [self performBlock:^{
        NIMPRTool* tool = self.ltool;
        if (event.type == NSRightMouseUp)
            tool = self.rtool;
        if ([tool respondsToSelector:@selector(toolbarItemAction:)])
            [tool toolbarItemAction:sender];
    } afterDelay:0];
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForLayouts:(BOOL)willBeInsertedIntoToolbar {
    NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:NIMPRControllerToolbarItemIdentifierLayouts] autorelease];
    item.label = item.toolTip = NSLocalizedString(@"Layout", nil);
    
    NSSegmentedControl* seg = [[[NSSegmentedControl alloc] initWithFrame:NSZeroRect] autorelease];
    NSSegmentedCell* cell = [seg cell];
    seg.toolTip = item.label;
    
    NSMenu* menu = [[[NSMenu alloc] init] autorelease];
    item.menuFormRepresentation = [[[NSMenuItem alloc] initWithTitle:item.label action:nil keyEquivalent:@""] autorelease];
    item.menuFormRepresentation.submenu = menu;
    
    NSArray* layouts = self.class.layouts;
    
    seg.segmentCount = layouts.count;
    [layouts enumerateObjectsUsingBlock:^(NIMPRLayoutRecord* r, NSUInteger i, BOOL* stop) {
        [cell setTag:r.tag forSegment:i];
        [seg setImage:r.image forSegment:i];
        [menu addItem:[NIBlockMenuItem itemWithTitle:r.label block:^{
            self.viewsLayout = r.tag;
        }]];
    }];
    
    cell.controlSize = NSSmallControlSize;
    [seg sizeToFit];
    item.view = seg;
    
    [cell bind:@"selectedTag" toObject:self withKeyPath:@"viewsLayout" options:0];
    
    item.autovalidates = NO;
    return item;
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForProjection:(BOOL)willBeInsertedIntoToolbar {
    NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:NIMPRControllerToolbarItemIdentifierProjection] autorelease];
    item.label = item.toolTip = NSLocalizedString(@"Projection", nil);
    
    NSButton* checkbox = [[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    checkbox.translatesAutoresizingMaskIntoConstraints = NO;
    checkbox.controlSize = NSMiniControlSize;
    checkbox.title = nil;
    [checkbox.cell setButtonType:NSSwitchButton];
    [checkbox sizeToFit];
    [checkbox bind:@"value" toObject:self withKeyPath:@"projectionFlag" options:0];
    
    NSPopUpButton* popup = [[[NSPopUpButton alloc] initWithFrame:NSZeroRect] autorelease];
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

@interface NIMPRSegmentedControl ()

@property(retain) NSTrackingArea* track;
@property(retain) NSString* tempToolTip;

@end

@implementation NIMPRSegmentedControl

@synthesize track = _track;
@synthesize tempToolTip = _tempToolTip;

- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.cell = [[[NIMPRSegmentedCell alloc] init] autorelease];
        [self addObserver:self forKeyPath:@"cell.rightMouseInside" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NIMPRSegmentedControl.class];
        [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NIMPRSegmentedControl.class];
    }
    
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"frame" context:NIMPRSegmentedControl.class];
    [self removeObserver:self forKeyPath:@"cell.rightMouseInside" context:NIMPRSegmentedControl.class];
    self.track = nil;
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != NIMPRSegmentedControl.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"cell.rightMouseInside"])
        if ([[change[NSKeyValueChangeNewKey] if:NSNumber.class] boolValue] != [[change[NSKeyValueChangeOldKey] if:NSNumber.class] boolValue]) {
            [self setNeedsDisplay];
        }
    
    if ([keyPath isEqualToString:@"frame"]) {
        if (self.track) [self removeTrackingArea:self.track];
        [self addTrackingArea:(self.track = [[[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved+NSTrackingActiveInActiveApp owner:self userInfo:@{ @"NIMPRViewTrackingArea": @YES }] autorelease])];
    }
}

- (NIMPRSegmentedCell*)cell {
    return [super cell];
}

- (BOOL)interceptsToolbarRightMouseEvents {
    return YES;
}

- (NSRect)boundsForSegment:(NSInteger)s {
    return [self.cell boundsForSegment:s inView:self];
}

- (NSInteger)segmentAtLocation:(NSPoint)location frame:(NSRect*)rframe {
    for (NSInteger s = 0; s < self.segmentCount; ++s) {
        NSRect frame = [self boundsForSegment:s];
        if (location.x <= NSMaxX(frame)) {
            if (rframe)
                *rframe = frame;
            return s;
        }
    }
    
    return -1;
}

- (void)rightMouseDown:(NSEvent*)event {
    NSRect sframe = NSZeroRect; NSInteger s = [self segmentAtLocation:[event locationInView:self] frame:&sframe];
    self.cell.rightMouseFrame = sframe;
    
    do {
        self.cell.rightMouseInside = NSPointInRect(event.locationInWindow, [self convertRect:self.cell.rightMouseFrame toView:nil]);
        if (event.type == NSRightMouseUp) {
            if (self.cell.rightMouseInside) {
                self.cell.rselectedTag = [self.cell tagForSegment:s];
                [self sendAction:self.action to:nil];
            } break;
        }
    } while ((event = [self.window nextEventMatchingMask:NSRightMouseDraggedMask|NSRightMouseUpMask]));
    
    self.cell.rightMouseInside = NO;
    self.cell.rightMouseFrame = NSZeroRect;
}

static NSString* const NSSegmentedControlSegmentToolTip = @"ToolTip";

- (NSString*)toolTipForSegment:(NSInteger)s {
    return self.cell.segments[s][NSSegmentedControlSegmentToolTip];
}

- (void)setToolTip:(NSString *)toolTip forSegment:(NSInteger)s {
    self.cell.segments[s][NSSegmentedControlSegmentToolTip] = toolTip;
}

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)data {
    return [self toolTipForSegment:(NSInteger)data];
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
    if (!self.segments)
        self.segments = [NSMutableArray array];
    if (self.segments.count > count)
        [self.segments removeObjectsInRange:NSMakeRange(count, self.segments.count-count)];
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

static NSString* const NSSegmentedControlSegmentToolTipTagRecord = @"ToolTipTagRecord";

- (void)drawSegment:(NSInteger)s inFrame:(NSRect)frame withView:(NIMPRSegmentedControl*)view {
    [super drawSegment:s inFrame:frame withView:view];
//    @unsafeify(view)
    
    NSToolTipTag ttt = [view addToolTipRect:[self boundsForSegment:s inView:view] owner:view userData:(void*)s];
    self.segments[s][NSSegmentedControlSegmentToolTipTagRecord] = [NIObject dealloc:^{
//        @strongify(view)
        [view removeToolTip:ttt];
    }];

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
}

@end
