//
//  CPRMPRController+Toolbar.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRController+Toolbar.h"
#import "CPRMPRController+Private.h"
#import "CPRMPR.h"
#import "CPRMPRWLWWTool.h"
#import "CPRMPRMoveTool.h"
#import "CPRMPRZoomTool.h"
#import "CPRMPRRotateTool.h"

@interface CPRMPRToolRecord : NSObject {
    CPRMPRToolTag _tag;
    NSString* _label;
    NSImage* _image;
    Class _handler;
    NSMenu* _submenu;
}

@property CPRMPRToolTag tag;
@property(retain) NSString* label;
@property(retain) NSImage* image;
@property Class handler;
@property(retain) NSMenu* submenu;

+ (instancetype)toolWithTag:(CPRMPRToolTag)tag label:(NSString*)label image:(NSImage*)image handler:(Class)handler;

@end

@interface CPRMPRSegmentedControl : NSSegmentedControl

@end

@interface CPRMPRSegmentedCell : NSSegmentedCell {
    NSInteger _rselectedTag;
    NSMutableArray* _segments;
}

@property NSInteger rselectedTag;
@property(retain) NSMutableArray* segments;

@end

@implementation CPRMPRController (Toolbar)

static NSString* const CPRMPRToolsToolbarItemIdentifier = @"CPRMPRTools";
static NSString* const CPRMPRSlabWidthToolbarItemIdentifier = @"CPRMPRSlabWidth";

- (NSArray*)tools {
    static NSArray* tools = nil;
    if (!tools) tools = [@[ [CPRMPRToolRecord toolWithTag:CPRMPRToolWLWW label:NSLocalizedString(@"WL/WW", nil) image:[[[NSImage alloc] initWithContentsOfURL:[CPRMPR.bundle URLForImageResource:@"Tool-WLWW"]] autorelease] handler:CPRMPRWLWWTool.class],
                            [CPRMPRToolRecord toolWithTag:CPRMPRToolMove label:NSLocalizedString(@"Move", nil) image:[[[NSImage alloc] initWithContentsOfURL:[CPRMPR.bundle URLForImageResource:@"Tool-Move" ]] autorelease] handler:CPRMPRMoveTool.class],
                            [CPRMPRToolRecord toolWithTag:CPRMPRToolZoom label:NSLocalizedString(@"Zoom", nil) image:[[[NSImage alloc] initWithContentsOfURL:[CPRMPR.bundle URLForImageResource:@"Tool-Zoom"]] autorelease] handler:CPRMPRZoomTool.class],
                            [CPRMPRToolRecord toolWithTag:CPRMPRToolRotate label:NSLocalizedString(@"Rotate", nil) image:[[[NSImage alloc] initWithContentsOfURL:[CPRMPR.bundle URLForImageResource:@"Tool-Rotate"]] autorelease] handler:CPRMPRRotateTool.class] ] retain];
    return tools;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return @[ CPRMPRToolsToolbarItemIdentifier, CPRMPRSlabWidthToolbarItemIdentifier ];
}

- (NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return @[ CPRMPRToolsToolbarItemIdentifier, CPRMPRSlabWidthToolbarItemIdentifier ];
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)identifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];

    if ([identifier isEqualToString:CPRMPRToolsToolbarItemIdentifier]) {
        item.label = NSLocalizedString(@"Mouse Tool", nil);
        
        CPRMPRSegmentedControl* seg = [[[CPRMPRSegmentedControl alloc] initWithFrame:NSZeroRect] autorelease];
        CPRMPRSegmentedCell* cell = [seg cell];
        
        NSMenu* menu = [[[NSMenu alloc] init] autorelease];
        item.menuFormRepresentation = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Mouse Tool", nil) action:nil keyEquivalent:@""];
        item.menuFormRepresentation.submenu = menu;
        
        NSArray* tools = [self tools];
        seg.segmentCount = tools.count;
        [tools enumerateObjectsUsingBlock:^(CPRMPRToolRecord* tool, NSUInteger i, BOOL* stop) {
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
    
    if ([identifier isEqualToString:CPRMPRSlabWidthToolbarItemIdentifier]) {
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
    
    if ([item.itemIdentifier isEqualToString:CPRMPRToolsToolbarItemIdentifier]) {
        CPRMPRSegmentedControl* seg = (id)item.view;
        [seg.cell bind:@"selectedTag" toObject:self withKeyPath:@"ltoolTag" options:0];
        [seg.cell bind:@"rselectedTag" toObject:self withKeyPath:@"rtoolTag" options:0];
    }
    
    if ([item.itemIdentifier isEqualToString:CPRMPRSlabWidthToolbarItemIdentifier]) {
        NSSlider* slider = (id)item.view;
        [slider bind:@"value" toObject:self withKeyPath:@"slabWidth" options:0];
    }
}

@end

@implementation CPRMPRToolRecord

@synthesize tag = _tag;
@synthesize label = _label;
@synthesize image = _image;
@synthesize handler = _handler;
@synthesize submenu = _submenu;

+ (instancetype)toolWithTag:(CPRMPRToolTag)tag label:(NSString*)label image:(NSImage*)image handler:(Class)handler {
    CPRMPRToolRecord* tool = [[[self.class alloc] init] autorelease];
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

//static NSString* const CPRMPRSegment = @"CPRMPRSegment";

@implementation CPRMPRSegmentedControl

- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.cell = [[[CPRMPRSegmentedCell alloc] init] autorelease];
    }
    
    return self;
}

- (CGFloat)totalWidth {
    CGFloat t = 0;
    for (NSInteger s = 0; s < self.segmentCount; ++s)
        t += [self widthForSegment:s];
    return t;
}

@end

@implementation CPRMPRSegmentedCell

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

- (void)drawSegment:(NSInteger)s inFrame:(NSRect)frame withView:(CPRMPRSegmentedControl*)view {
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
