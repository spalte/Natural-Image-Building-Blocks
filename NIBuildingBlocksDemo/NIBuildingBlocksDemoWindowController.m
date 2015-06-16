//
//  NIBuildingBlocksDemoWindowController.m
//  NIBuildingBlocksDemo
//
//  Created by Joël Spaltenstein on 6/15/15.
//  Copyright (c) 2015 Spaltenstein Natural Image. All rights reserved.
//

#import <NIBuildingBlocks/NIBuildingBlocks.h>

#import "NIBuildingBlocksDemoWindowController.h"
#import "NIBuildingBlocksDemoView.h"

@interface NIBuildingBlocksDemoWindowController ()
- (void)updateVolumes;
@end

@implementation NIBuildingBlocksDemoWindowController

@synthesize volumeData =_volumeData;
@synthesize leftView =_leftView;
@synthesize rightView = _rightView;

- (void)windowDidLoad {
    [super windowDidLoad];

    _leftView.rimColor = [[NSColor greenColor] colorWithAlphaComponent:0.8];
    _leftView.displayRim = YES;
    _leftView.displayScaleBar = YES;
    _leftView.displayOrientationLabels = YES;
    _rightView.rimColor = [[NSColor redColor] colorWithAlphaComponent:0.8];
    _rightView.displayRim = YES;
    _rightView.displayScaleBar = YES;
    _rightView.displayOrientationLabels = YES;

    _leftIntersection = [[NIIntersection alloc] init];
    _leftIntersection.color = [[NSColor redColor] colorWithAlphaComponent:0.8];
    _leftIntersection.thickness = 2;
    _leftIntersection.maskAroundMouse = YES;
    [_leftIntersection bind:@"intersectingObject" toObject:_rightView withKeyPath:@"presentedGeneratorRequest" options:nil];
    [_leftView addIntersection:_leftIntersection forKey:@"leftIntersection"];

    _rightIntersection = [[NIIntersection alloc] init];
    _rightIntersection.color = [[NSColor greenColor] colorWithAlphaComponent:0.8];
    _rightIntersection.thickness = 2;
    _rightIntersection.maskAroundMouse = YES;
    [_rightIntersection bind:@"intersectingObject" toObject:_leftView withKeyPath:@"presentedGeneratorRequest" options:nil];
    [_rightView addIntersection:_rightIntersection forKey:@"rightIntersection"];

    [self updateVolumes];
}

- (void)dealloc
{
    [_volumeData release];
    _volumeData = nil;

    [_leftIntersection unbind:@"intersectingObject"];
    [_leftIntersection release];
    _leftIntersection = nil;

    [_rightIntersection unbind:@"intersectingObject"];
    [_rightIntersection release];
    _rightIntersection = nil;

    [super dealloc];
}

- (void)setVolumeData:(NIVolumeData *)volumeData
{
    if (_volumeData != volumeData) {
        [_volumeData release];
        _volumeData = [volumeData retain];

        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        if (_leftView.volumeDataCount) {
            [_leftView removeVolumeDataAtIndex:0];
        }
        if (_rightView.volumeDataCount) {
            [_rightView removeVolumeDataAtIndex:0];
        }
        [CATransaction commit];

        [self updateVolumes];
    }
}

- (void)updateVolumes
{
    if (_volumeData) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];

        [_leftView addVolumeData:_volumeData];

        NIVolumeDataProperties *properties = [_rightView addVolumeData:_volumeData];
        properties.CLUT = [[[NSGradient alloc] initWithStartingColor:[NSColor blueColor] endingColor:[NSColor redColor]] autorelease];

        NIAffineTransform inverseVolumeTransform = NIAffineTransformInvert(_volumeData.volumeTransform);
        NIVector center = NIVectorApplyTransform(NIVectorMake(round(_volumeData.pixelsWide / 2.0), round(_volumeData.pixelsHigh / 2.0), round(_volumeData.pixelsDeep / 2.0)), inverseVolumeTransform);
        NIObliqueSliceGeneratorRequest *leftRequest = [[[NIObliqueSliceGeneratorRequest alloc] initWithCenter:center pixelsWide:200 pixelsHigh:200
                                                                                                       xBasis:_volumeData.directionX yBasis:NIVectorInvert(_volumeData.directionY)] autorelease];
        leftRequest.interpolationMode = NIInterpolationModeCubic;
        NIObliqueSliceGeneratorRequest *rightRequest = [[[NIObliqueSliceGeneratorRequest alloc] initWithCenter:center pixelsWide:200 pixelsHigh:200
                                                                                                       xBasis:_volumeData.directionX yBasis:_volumeData.directionZ] autorelease];
        rightRequest.interpolationMode = NIInterpolationModeCubic;

        _leftView.generatorRequest = leftRequest;
        _rightView.generatorRequest = rightRequest;
        [CATransaction commit];
    }
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return @[@"WindowLevelWindowWidthIdentifier", NSToolbarFlexibleSpaceItemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return @[@"WindowLevelWindowWidthIdentifier", NSToolbarFlexibleSpaceItemIdentifier];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];

    if ([itemIdentifier isEqual:@"WindowLevelWindowWidthIdentifier"]) {
        NIWindowLevelWindowWidthToolbarItem *windowingToolbarItem;
        windowingToolbarItem = [[[NIWindowLevelWindowWidthToolbarItem alloc] initWithItemIdentifier:@"WindowLevelWindowWidthIdentifier"] autorelease];
        windowingToolbarItem.generatorRequestViews = @[_leftView, _rightView];
        return windowingToolbarItem;
    } else {
        // itemIdentifier referred to a toolbar item that is not
        // not provided or supported by us or cocoa
        // Returning nil will inform the toolbar
        // this kind of item is not supported
        toolbarItem = nil;
    }
    return toolbarItem;
}


@end
