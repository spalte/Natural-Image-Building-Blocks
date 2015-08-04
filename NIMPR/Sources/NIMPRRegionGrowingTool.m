//
//  NIMPRRegionGrowTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRRegionGrowingTool.h"
#import "NIMaskAnnotation.h"
#import "NIBackgroundView.h"

@interface NIMPRRegionGrowingTool ()

@property(readwrite, retain, nonatomic) NSPopover* popover;

@end

@implementation NIMPRRegionGrowingTool

@dynamic annotation;
@synthesize popover = _popover;

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^{
        NIVector miv = NIVectorApplyTransform(self.mouseDownLocationVector, view.data.volumeTransform);
        NIMaskIndex mi = {miv.x, miv.y, miv.z};
        
        NIMask* mask = [[[NIMask alloc] initWithIndexes:@[[NSValue valueWithNIMaskIndex:mi]]] autorelease];
        
        NIMaskAnnotation* ma = [[NIMaskAnnotation alloc] initWithMask:mask transform:NIAffineTransformInvert(view.data.volumeTransform)];
        [view.mutableAnnotations addObject:ma];
        
        [self.class seed:mi volume:view.data annotation:ma];
    }];
}

- (void)toolbarItemAction:(id)sender {
    if (!self.popover.isShown)
        [self.popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
    else [self.popover performClose:sender];
}

- (NSPopover*)popover {
    if (_popover)
        return _popover;
    
    NSPopover* po = _popover = [[NSPopover alloc] init];
    po.delegate = self;
    po.contentViewController = [[[NSViewController alloc] init] autorelease];
    po.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    po.contentViewController.view = [self popoverView];
    
    return po;
}

- (void)dealloc {
    [_popover performClose:nil];
    [_popover release];
    [super dealloc];
}

- (BOOL)popoverShouldDetach:(NSPopover*)popover {
    return YES;
}

+ (void)seed:(NIMaskIndex)seed volume:(NIVolumeData*)data annotation:(NIMaskAnnotation*)ma {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        const NIVector dirs[6] = {{1,0,0},{0,1,0},{0,0,1},{-1,0,0},{0,-1,0},{0,0,-1}};
        const size_t xd = data.pixelsWide, yd = data.pixelsHigh, zd = data.pixelsDeep, xyd = xd*yd, xyzd = xyd*zd;
        
        NSMutableArray* queue = [NSMutableArray arrayWithObject:[NSValue valueWithNIMaskIndex:seed]];
        
        NSMutableData* visitedd = [[[NSMutableData alloc] initWithLength:sizeof(float)*xyzd] autorelease];
#define visited(i) ((float*)visitedd.mutableBytes)[i.x+i.y*xd+i.z*xyd]
        NSMutableData* voxels = [[[NSMutableData alloc] initWithLength:sizeof(float)*xyzd] autorelease];
#define voxel(i) ((float*)voxels.mutableBytes)[i.x+i.y*xd+i.z*xyd]
        NIVolumeData* result = [[[NIVolumeData alloc] initWithData:voxels pixelsWide:data.pixelsWide pixelsHigh:data.pixelsHigh pixelsDeep:data.pixelsDeep volumeTransform:NIAffineTransformIdentity outOfBoundsValue:0] autorelease];
        
        visited(seed) = 1; voxel(seed) = 1;
        float seedv = [data floatAtPixelCoordinateX:seed.x y:seed.y z:seed.z];
        NSTimeInterval lut = [NSDate timeIntervalSinceReferenceDate];
        
//        NSUInteger vc = 1, pc = 1;
        
        while (queue.count) {
            NIMaskIndex mi = [queue[0] NIMaskIndexValue];
            [queue removeObjectAtIndex:0];
            
            for (size_t i = 0; i < 6; ++i) {
                NIMaskIndex imi = {mi.x+dirs[i].x, mi.y+dirs[i].y, mi.z+dirs[i].z};
                
                if (imi.x == NSUIntegerMax || imi.y == NSUIntegerMax || imi.z == NSUIntegerMax || imi.x >= data.pixelsWide || imi.y >= data.pixelsHigh || imi.z >= data.pixelsDeep)
                    continue;
                if (visited(imi))
                    continue;
                
                visited(imi) = true;
                
//                ++vc;
                float imiv = [data floatAtPixelCoordinateX:imi.x y:imi.y z:imi.z];
                if (fabs(imiv-seedv) < 75) {
                    voxel(imi) = 1;
//                    ++pc;
                    [queue addObject:[NSValue valueWithNIMaskIndex:imi]];
                }
            }
            
            NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
            if (t >= lut+1 || !queue.count) {
                lut = t;
//                NSLog(@"Updating %d %d q%d", vc, pc, queue.count);
                NSData* data = [voxels.copy autorelease];
                dispatch_async(dispatch_get_main_queue(), ^{
                    ma.volume = [[NIVolumeData alloc] initWithData:data pixelsWide:result.pixelsWide pixelsHigh:result.pixelsHigh pixelsDeep:result.pixelsDeep volumeTransform:NIAffineTransformIdentity outOfBoundsValue:0];
                });
            }
        }
        
#undef visited
#undef rvoxel
    });
}

- (NSView*)popoverView {
    NIBackgroundView* view = [[[NIBackgroundView alloc] initWithFrame:NSZeroRect color:[NSColor.blackColor colorWithAlphaComponent:.8]] autorelease];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:120]];
    
    NSTextField* label = [[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    label.translatesAutoresizingMaskIntoConstraints = label.selectable = label.bordered = label.drawsBackground = NO;
    label.controlSize = NSSmallControlSize;
    label.stringValue = NSLocalizedString(@"Region Growing", nil);
    
    [view addSubview:label];
//    [view addObserver:<#(NSObject *)#> forKeyPath:<#(NSString *)#> options:<#(NSKeyValueObservingOptions)#> context:<#(void *)#>];
//    
//    [view addObserver:self forKeyPath:<#(NSString *)#> options:<#(NSKeyValueObservingOptions)#> context:<#(void *)#>];
    
//    [[NSOperationQueue mainQueue] add];
    
//    
//    [view addObserver:^{
//        
//    } forKeyPath:@"superview" options:0];
//    
    
    NSDictionary* m = @{ @"d": @5 };
    
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-d-[label]-d-|" options:0 metrics:m views:NSDictionaryOfVariableBindings(label)]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-d-[label]" options:0 metrics:m views:NSDictionaryOfVariableBindings(label)]];

    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label]-d-|" options:0 metrics:m views:NSDictionaryOfVariableBindings(label)]];
    
    [view layout];
    return view;
}

@end
