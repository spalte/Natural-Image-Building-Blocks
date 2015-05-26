//
//  CPRMPRController+Toolbar.m
//  CPRMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRController+Toolbar.h"
#import "CPRMPR.h"

@interface CPRMPRTool : NSObject {
    CPRMPRToolTag _tag;
    NSString* _label;
    NSImage* _image;
    //    void(^_block)();
    NSMenu* _submenu;
}

@property CPRMPRToolTag tag;
@property(retain) NSString* label;
@property(retain) NSImage* image;
//@property(copy) void(^block)();
@property(retain) NSMenu* submenu;

+ (instancetype)toolWithTag:(CPRMPRToolTag)tag label:(NSString*)label image:(NSImage*)image /*block:(void(^)())block*/;

@end

@implementation CPRMPRController (Toolbar)

NSString* const CPRMPRToolsToolbarItemIdentifier = @"CPRMPRTools";

- (NSArray*)tools {
    static NSArray* tools = nil;
    if (!tools) tools = [@[ [CPRMPRTool toolWithTag:CPRMPRToolWLWW label:NSLocalizedString(@"WL/WW", nil) image:[[[NSImage alloc] initWithContentsOfURL:[CPRMPR.bundle URLForImageResource:@"Tool-WLWW"]] autorelease]],
                            [CPRMPRTool toolWithTag:CPRMPRToolMove label:NSLocalizedString(@"Move", nil) image:[[[NSImage alloc] initWithContentsOfURL:[CPRMPR.bundle URLForImageResource:@"Tool-Move" ]] autorelease]],
                            [CPRMPRTool toolWithTag:CPRMPRToolZoom label:NSLocalizedString(@"Zoom", nil) image:[[[NSImage alloc] initWithContentsOfURL:[CPRMPR.bundle URLForImageResource:@"Tool-Zoom"]] autorelease]],
                            [CPRMPRTool toolWithTag:CPRMPRToolRotate label:NSLocalizedString(@"Rotate", nil) image:[[[NSImage alloc] initWithContentsOfURL:[CPRMPR.bundle URLForImageResource:@"Tool-Rotate"]] autorelease]] ] retain];
    return tools;
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    if ([itemIdentifier isEqualToString:CPRMPRToolsToolbarItemIdentifier]) {
        NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:CPRMPRToolsToolbarItemIdentifier] autorelease];
        item.label = NSLocalizedString(@"Tools", nil);
        
        NSSegmentedControl* seg = [[[NSSegmentedControl alloc] initWithFrame:NSZeroRect] autorelease];
        NSSegmentedCell* cell = [seg cell];
        
        NSMenu* menu = [[[NSMenu alloc] init] autorelease];
        item.menuFormRepresentation = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Tools", nil) action:nil keyEquivalent:@""];
        item.menuFormRepresentation.submenu = menu;
        
        NSArray* tools = [self tools];
        seg.segmentCount = tools.count;
        //        seg.target = self;
        //        seg.action = @selector(toolsSegmentAction:);
        [tools enumerateObjectsUsingBlock:^(CPRMPRTool* tool, NSUInteger i, BOOL* stop) {
            [cell setTag:tool.tag forSegment:i];
            //            [seg setLabel:tool.label forSegment:i];
            [seg setImage:tool.image forSegment:i];
            NSMenuItem* mi = [[NSMenuItem alloc] initWithTitle:tool.label action:nil keyEquivalent:@""];
            mi.tag = tool.tag;
            mi.submenu = tool.submenu;
            [menu addItem:mi];
            
            //            if (!tool.submenu) {
            //                [menu addItemWithTitle:tool.label block:tool.block];
            //            } else {
            //                [seg setMenu:tool.submenu forSegment:i];
            //                [menu addItemWithTitle:tool.label submenu:tool.submenu];
            //            }
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

//- (void)toolsSegmentAction:(NSSegmentedControl*)sender {
//    CPRMPRTool* tool = self.tools[sender.selectedSegment];
//    tool.block();
//}

@end

@implementation CPRMPRTool

@synthesize tag = _tag;
@synthesize label = _label;
@synthesize image = _image;
//@synthesize block = _block;
@synthesize submenu = _submenu;

+ (instancetype)toolWithTag:(CPRMPRToolTag)tag label:(NSString*)label image:(NSImage*)image /*block:(void(^)())block*/ {
    CPRMPRTool* tool = [[[self.class alloc] init] autorelease];
    tool.tag = tag;
    tool.label = label;
    tool.image = image;
    image.size = NSMakeSize(16,16);
    //    tool.block = block;
    return tool;
}

- (void)dealloc {
    self.label = nil;
    self.image = nil;
    //    self.block = nil;
    self.submenu = nil;
    [super dealloc];
}

@end

