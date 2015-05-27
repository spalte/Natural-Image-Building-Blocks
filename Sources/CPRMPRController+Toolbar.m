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

@implementation CPRMPRController (Toolbar)

static NSString* const CPRMPRToolsToolbarItemIdentifier = @"CPRMPRTools";

- (NSArray*)tools {
    static NSArray* tools = nil;
    if (!tools) tools = [@[ [CPRMPRToolRecord toolWithTag:CPRMPRToolWLWW label:NSLocalizedString(@"WL/WW", nil) image:[[[NSImage alloc] initWithContentsOfURL:[CPRMPR.bundle URLForImageResource:@"Tool-WLWW"]] autorelease] handler:CPRMPRWLWWTool.class],
                            [CPRMPRToolRecord toolWithTag:CPRMPRToolMove label:NSLocalizedString(@"Move", nil) image:[[[NSImage alloc] initWithContentsOfURL:[CPRMPR.bundle URLForImageResource:@"Tool-Move" ]] autorelease] handler:CPRMPRMoveTool.class],
                            [CPRMPRToolRecord toolWithTag:CPRMPRToolZoom label:NSLocalizedString(@"Zoom", nil) image:[[[NSImage alloc] initWithContentsOfURL:[CPRMPR.bundle URLForImageResource:@"Tool-Zoom"]] autorelease] handler:CPRMPRZoomTool.class],
                            [CPRMPRToolRecord toolWithTag:CPRMPRToolRotate label:NSLocalizedString(@"Rotate", nil) image:[[[NSImage alloc] initWithContentsOfURL:[CPRMPR.bundle URLForImageResource:@"Tool-Rotate"]] autorelease] handler:CPRMPRRotateTool.class] ] retain];
    return tools;
}

- (void)Toolbar_observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (object == self && [keyPath isEqualToString:@"currentToolTag"]) {
        CPRMPRToolRecord* tool = [[self.tools filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"tag = %@", change[NSKeyValueChangeNewKey]]] lastObject];
        self.tool = [[[tool.handler alloc] init] autorelease];
    }
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    if ([itemIdentifier isEqualToString:CPRMPRToolsToolbarItemIdentifier]) {
        NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:CPRMPRToolsToolbarItemIdentifier] autorelease];
        item.label = NSLocalizedString(@"Mouse Tool", nil);
        
        NSSegmentedControl* seg = [[[NSSegmentedControl alloc] initWithFrame:NSZeroRect] autorelease];
        NSSegmentedCell* cell = [seg cell];
        
        NSMenu* menu = [[[NSMenu alloc] init] autorelease];
        item.menuFormRepresentation = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Mouse Tool", nil) action:nil keyEquivalent:@""];
        item.menuFormRepresentation.submenu = menu;
        
        NSArray* tools = [self tools];
        seg.segmentCount = tools.count;
        [tools enumerateObjectsUsingBlock:^(CPRMPRToolRecord* tool, NSUInteger i, BOOL* stop) {
            [cell setTag:tool.tag forSegment:i];
//            [seg setLabel:tool.label forSegment:i];
            [seg setImage:tool.image forSegment:i];
            NSMenuItem* mi = [[NSMenuItem alloc] initWithTitle:tool.label action:nil keyEquivalent:@""];
            mi.tag = tool.tag;
            mi.submenu = tool.submenu;
            [menu addItem:mi];
        }];
        
        [seg sizeToFit];
        item.view = seg;
        
        return item;
    }
    
    return nil;
}

- (NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return @[ CPRMPRToolsToolbarItemIdentifier ];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return @[ CPRMPRToolsToolbarItemIdentifier ];
}

- (void)toolbarWillAddItem:(NSNotification*)notification {
    NSToolbarItem* item = notification.userInfo[@"item"];
    
    if ([item.itemIdentifier isEqualToString:CPRMPRToolsToolbarItemIdentifier]) {
        NSSegmentedControl* seg = (id)item.view;
        NSSegmentedCell* cell = [seg cell];
        [cell bind:@"selectedTag" toObject:self withKeyPath:@"currentToolTag" options:0];
    }
}

- (void)toolsSegmentAction:(NSSegmentedControl*)sender {
    CPRMPRToolRecord* tool = self.tools[sender.selectedSegment];
    self.tool = [[[tool.handler alloc] init] autorelease];
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
    tool.image = image; image.size = NSMakeSize(16,16);
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

