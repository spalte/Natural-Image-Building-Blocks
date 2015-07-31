//
//  NIMPRRegionGrowTool.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRRegionGrowTool.h"
#import "NIMPRRegionGrowToolWindowController.h"
#import "NIMaskAnnotation.h"

@interface NIMPRRegionGrowTool ()

@property(readwrite, retain) NIMPRRegionGrowToolWindowController* controller;

@end

@implementation NIMPRRegionGrowTool

@dynamic annotation;
@synthesize controller = _controller;

- (BOOL)view:(NIMPRView*)view mouseDown:(NSEvent*)event otherwise:(void(^)())otherwise {
    return [super view:view mouseDown:event otherwise:otherwise confirm:^{
        NIVector miv = NIVectorApplyTransform(self.mouseDownLocationVector, view.data.volumeTransform);
        NIMaskIndex mi = {miv.x, miv.y, miv.z};
        
        NIMask* mask = [[[NIMask alloc] initWithIndexes:@[[NSValue valueWithNIMaskIndex:mi]]] autorelease];
        
        NIMaskAnnotation* ma = [[NIMaskAnnotation alloc] initWithMask:mask transform:NIAffineTransformInvert(view.data.volumeTransform)];
        [view.mutableAnnotations addObject:ma];
        
        [self seed:mi volume:view.data annotation:ma];
    }];
}

- (void)seed:(NIMaskIndex)seed volume:(NIVolumeData*)data annotation:(NIMaskAnnotation*)ma {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NIVector dirs[6] = {{1,0,0},{0,1,0},{0,0,1},{-1,0,0},{0,-1,0},{0,0,-1}};
        
        NSMutableArray* queue = [NSMutableArray arrayWithObject:[NSValue valueWithNIMaskIndex:seed]];

        NIMask* visited = [[[NIMask alloc] initWithIndexes:@[queue[0]]] autorelease];
        NIMask* result = [NIMask mask];
        float seedv = [data floatAtPixelCoordinateX:seed.x y:seed.y z:seed.z];
        
        NSTimeInterval lut = [NSDate timeIntervalSinceReferenceDate];
        
        while (queue.count) {
            NIMaskIndex mi = [queue[0] NIMaskIndexValue];
            [queue removeObjectAtIndex:0];
            
            for (size_t i = 0; i < 6; ++i) {
                NIMaskIndex imi = {mi.x+dirs[i].x, mi.y+dirs[i].y, mi.z+dirs[i].z};
                NSValue* vimi = [NSValue valueWithNIMaskIndex:imi];
                if (![visited containsIndex:imi]) {
                    visited = [visited maskByUnioningWithMask:[[[NIMask alloc] initWithIndexes:@[vimi]] autorelease]];
                    float imiv = [data floatAtPixelCoordinateX:imi.x y:imi.y z:imi.z];
                    if (fabs(imiv-seedv) < 100) {
                        result = [result maskByUnioningWithMask:[[[NIMask alloc] initWithIndexes:@[vimi]] autorelease]];
                        [queue addObject:vimi];
                    }
                }
            }
            
            NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
            if (t >= lut+1 || !queue.count) {
                lut = t;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    ma.mask = [[result copy] autorelease];
                });
            }
        }
        
        NSLog(@"done!!!!");
    });
}

@end
