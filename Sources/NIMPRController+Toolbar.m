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

@interface NIMPRSegmentedControl : NSSegmentedControl

@end

@interface NIMPRSegmentedCell : NSSegmentedCell {
    NSInteger _rselectedTag;
    NSMutableArray* _segments;
}

@property NSInteger rselectedTag;
@property(retain) NSMutableArray* segments;

@end

@implementation NIMPRController (Toolbar)

static NSString* const NIMPRToolsToolbarItemIdentifier = @"NIMPRTools";
static NSString* const NIMPRSlabWidthToolbarItemIdentifier = @"NIMPRSlabWidth";

- (NSArray*)tools {
    static NSArray* tools = nil;
    if (!tools) tools = [@[ [NIMPRToolRecord toolWithTag:NIMPRToolWLWW label:NSLocalizedString(@"WL/WW", nil) image:[NIMPR image:@"Tool-WLWW"] handler:NIMPRWLWWTool.class],
                            [NIMPRToolRecord toolWithTag:NIMPRToolMove label:NSLocalizedString(@"Move", nil) image:[NIMPR image:@"Tool-Move"] handler:NIMPRMoveTool.class],
                            [NIMPRToolRecord toolWithTag:NIMPRToolZoom label:NSLocalizedString(@"Zoom", nil) image:[NIMPR image:@"Tool-Zoom"] handler:NIMPRZoomTool.class],
                            [NIMPRToolRecord toolWithTag:NIMPRToolRotate label:NSLocalizedString(@"Rotate", nil) image:[NIMPR image:@"Tool-Rotate"] handler:NIMPRRotateTool.class] ] retain];
    return tools;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return @[ NIMPRToolsToolbarItemIdentifier, NIMPRSlabWidthToolbarItemIdentifier ];
}

- (NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return @[ NIMPRToolsToolbarItemIdentifier, NIMPRSlabWidthToolbarItemIdentifier ];
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)identifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];

    if ([identifier isEqualToString:NIMPRToolsToolbarItemIdentifier]) {
        item.label = NSLocalizedString(@"Mouse Tool", nil);
        
        NIMPRSegmentedControl* seg = [[[NIMPRSegmentedControl alloc] initWithFrame:NSZeroRect] autorelease];
        NIMPRSegmentedCell* cell = [seg cell];
        
        NSMenu* menu = [[[NSMenu alloc] init] autorelease];
        item.menuFormRepresentation = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Mouse Tool", nil) action:nil keyEquivalent:@""];
        item.menuFormRepresentation.submenu = menu;
        
        NSArray* tools = [self tools];
        seg.segmentCount = tools.count;
        [tools enumerateObjectsUsingBlock:^(NIMPRToolRecord* tool, NSUInteger i, BOOL* stop) {
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
    
    if ([identifier isEqualToString:NIMPRSlabWidthToolbarItemIdentifier]) {
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
    
    if ([item.itemIdentifier isEqualToString:NIMPRToolsToolbarItemIdentifier]) {
        NIMPRSegmentedControl* seg = (id)item.view;
        [seg.cell bind:@"selectedTag" toObject:self withKeyPath:@"ltoolTag" options:0];
        [seg.cell bind:@"rselectedTag" toObject:self withKeyPath:@"rtoolTag" options:0];
    }
    
    if ([item.itemIdentifier isEqualToString:NIMPRSlabWidthToolbarItemIdentifier]) {
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
    }
    
    return self;
}

- (CGFloat)totalWidth {
    CGFloat t = 0;
    for (NSInteger s = 0; s < self.segmentCount; ++s)
        t += [self widthForSegment:s];
    return t;
}

- (BOOL)interceptsToolbarRightMouseEvents {
    return YES;
}

- (void)rightMouseDown:(NSEvent*)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
    CGFloat extraWidth = (NSWidth(self.frame)-self.totalWidth)/self.segmentCount;
    
    NSInteger s = 0, px = 0, x;
    for (x = 0; s < self.segmentCount; ++s) {
        px = x; x += [self widthForSegment:s]+extraWidth;
        if (location.x < x)
            break;
    }
    
    if (s >= self.segmentCount)
        return;
    
    // TODO: this popup menu bit sucks...
    
    NSMenu* menu = [[[NSMenu alloc] init] autorelease];
    [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Set right button tool to %@", nil), [[self.window.windowController tools][s] label]] block:^{
        [self.window.windowController setRtoolTag:[[self.window.windowController tools][s] tag]];
    }];
    
    [NSMenu popUpContextMenu:menu withEvent:event forView:self withFont:[NSFont menuFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
    
//    if ([self.cell trackMouse:event inRect:NSMakeRect(px, 0, x, NSHeight(self.bounds)) ofView:self untilMouseUp:YES]) {
//        [self.cell setRselectedTag:[self.cell tagForSegment:s]];
//        [self setNeedsDisplay:YES];
//    }
}

@end

@implementation NIMPRSegmentedCell

@synthesize rselectedTag = _rselectedTag;
@synthesize segments = _segments;

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

- (void)drawSegment:(NSInteger)s inFrame:(NSRect)frame withView:(NIMPRSegmentedControl*)view {
    [super drawSegment:s inFrame:frame withView:view];
    if ([self tagForSegment:s] == self.rselectedTag) {
        frame = NSInsetRect(frame, (NSWidth(view.frame)-view.totalWidth)/(view.segmentCount*2)-1, -2);
        NSMutableParagraphStyle* ps = [[NSMutableParagraphStyle.defaultParagraphStyle mutableCopy] autorelease];
        ps.alignment = NSRightTextAlignment;
        NSString* r = NSLocalizedString(@"R", nil);
        NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading;
        NSDictionary* attributes = @{ NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]],
                                      NSForegroundColorAttributeName: ([self isSelectedForSegment:s]? [NSColor colorWithCalibratedWhite:0.8 alpha:1] : [NSColor colorWithCalibratedWhite:0.2 alpha:1]),
                                      NSShadowAttributeName: [self shadowWithColor:([self isSelectedForSegment:s]? NSColor.blackColor : NSColor.whiteColor)],
                                      NSParagraphStyleAttributeName: ps };
//        NSRect rframe = NSZeroRect; rframe = [r boundingRectWithSize:frame.size options:options attributes:attributes];
//        [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(frame.origin.x+rframe.origin.x, frame.origin.y+rframe.origin.y, rframe.size.width, rframe.size.height)];
        [r drawWithRect:frame options:options attributes:attributes];
    }
}


@end
