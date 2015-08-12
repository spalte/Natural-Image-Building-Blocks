//
//  NIThresholdSegmentation.m
//  NIMPR
//
//  Created by Alessandro Volz on 8/5/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIThresholdSegmentation.h"
#import "NSView+NI.h"
#import "NIMaskAnnotation.h"
#import <NIBuildingBlocks/NIGeometry.h>
#import <NIBuildingBlocks/NIVolumeData.h>
#import <NIBuildingBlocks/NIMask.h>

@implementation NIThresholdSegmentation

@synthesize lowerThreshold = _lowerThreshold, higherThreshold = _higherThreshold;

+ (NSSet*)keyPathsForValuesAffectingSegmentationAlgorithm {
    return [NSSet setWithObjects: @"lowerThreshold", @"higherThreshold", nil];
}

- (id)init {
    if ((self = [super init])) {
        self.lowerThreshold = 0;
        self.higherThreshold = 100;
    }
    
    return self;
}

- (NSString*)name {
    return NSLocalizedString(@"Thresholding (upper/lower boundary)", nil);
}

- (NSString*)shortName {
    return NSLocalizedString(@"Thresholding", nil);
}

- (NSViewController*)viewController {
    NIView* view = [[[NIView alloc] initWithFrame:NSZeroRect] autorelease];
    
    NSTextField* lbetween = [NIView labelWithControlSize:NSSmallControlSize];
    lbetween.stringValue = NSLocalizedString(@"Between", nil);
    [view addSubview:lbetween];
    
    NSTextField* t1 = [NIView fieldWithControlSize:NSSmallControlSize];
    [view addSubview:t1];
    
    NSTextField* land = [NIView labelWithControlSize:NSSmallControlSize];
    land.stringValue = NSLocalizedString(@"and", nil);
    [view addSubview:land];
    
    NSTextField* t2 = [NIView fieldWithControlSize:NSSmallControlSize];
    [view addSubview:t2];
    
    t1.nextResponder = t2;
    
    [t1 addConstraint:[NSLayoutConstraint constraintWithItem:t1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:40]];
    [t2 addConstraint:[NSLayoutConstraint constraintWithItem:t2 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:40]];
    
    [t1 bind:@"value" toObject:self withKeyPath:@"lowerThreshold" options:nil];
    [t2 bind:@"value" toObject:self withKeyPath:@"higherThreshold" options:nil];

    return [[[NIViewController alloc] initWithView:view updateConstraints:^{
        [view removeAllConstraints];
        NSDictionary* m = @{ @"s": @4 };
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[lbetween]-s-[t1]-s-[land]-s-[t2]|" options:NSLayoutFormatAlignAllBaseline metrics:m views:NSDictionaryOfVariableBindings(lbetween, t1, land, t2)]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[t1]|" options:0 metrics:m views:NSDictionaryOfVariableBindings(t1)]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:t1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:t2 attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:view.fittingSize.width]];
    }] autorelease];
}

- (void)processWithSeeds:(NSArray*)seeds volume:(NIVolumeData*)data annotation:(NIMaskAnnotation*)ma operation:(NSOperation*)op {
    [self processWithSeeds:seeds volume:data annotation:ma operation:op thresholds:self.lowerThreshold:self.higherThreshold];
}

- (void)processWithSeeds:(NSArray*)seeds volume:(NIVolumeData*)data annotation:(NIMaskAnnotation*)ma operation:(NSOperation*)op thresholds:(CGFloat)lowert :(CGFloat)highert {
    static const NIVector dirs[6] = {{1,0,0},{0,1,0},{0,0,1},{-1,0,0},{0,-1,0},{0,0,-1}};
    const size_t xd = data.pixelsWide, yd = data.pixelsHigh, zd = data.pixelsDeep, xyd = xd*yd, xyzd = xyd*zd;
    
    NSMutableArray* queue = [[seeds mutableCopy] autorelease];
    
    NSMutableData* visitedd = [[[NSMutableData alloc] initWithLength:sizeof(bool)*xyzd] autorelease];
    bool* visiteddf = (bool*)visitedd.mutableBytes;
#define visited(i) visiteddf[i.x+i.y*xd+i.z*xyd]
    NSMutableData* voxeld = [[[NSMutableData alloc] initWithLength:sizeof(float)*xyzd] autorelease];
    float* voxeldf = (float*)voxeld.mutableBytes;
#define voxel(i) voxeldf[i.x+i.y*xd+i.z*xyd]
    NIVolumeData* result = [[[NIVolumeData alloc] initWithData:voxeld pixelsWide:data.pixelsWide pixelsHigh:data.pixelsHigh pixelsDeep:data.pixelsDeep volumeTransform:NIAffineTransformIdentity outOfBoundsValue:0] autorelease];
    
    if (lowert > highert) {
        CGFloat temp = lowert;
        lowert = highert;
        highert = temp;
    }
    
    for (NSValue* seed in seeds) {
        NIMaskIndex s = [seed NIMaskIndexValue];
        visited(s) = 1; voxel(s) = 1;
    }
    
    NSTimeInterval lut = [NSDate timeIntervalSinceReferenceDate]; // last update time
    
    while (queue.count && !op.isCancelled) {
        NIMaskIndex mi = [queue[0] NIMaskIndexValue];
        [queue removeObjectAtIndex:0];
        
        for (size_t i = 0; i < 6; ++i) {
            NIMaskIndex imi = {mi.x+dirs[i].x, mi.y+dirs[i].y, mi.z+dirs[i].z};
            
            if (imi.x == NSUIntegerMax || imi.y == NSUIntegerMax || imi.z == NSUIntegerMax || imi.x >= data.pixelsWide || imi.y >= data.pixelsHigh || imi.z >= data.pixelsDeep)
                continue;
            if (visited(imi))
                continue;
            
            visited(imi) = true;
            
            float imiv = [data floatAtPixelCoordinateX:imi.x y:imi.y z:imi.z];
            if (imiv >= lowert && imiv <= highert) {
                voxel(imi) = 1;
                [queue addObject:[NSValue valueWithNIMaskIndex:imi]];
            }
        }
        
        NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
        if ((t >= lut+1 || !queue.count) && !op.isCancelled) {
            lut = t;
            NSData* voxeldc = [voxeld.copy autorelease];
            dispatch_async(dispatch_get_main_queue(), ^{
                ma.volume = [[[NIVolumeData alloc] initWithData:voxeldc pixelsWide:result.pixelsWide pixelsHigh:result.pixelsHigh pixelsDeep:result.pixelsDeep volumeTransform:NIAffineTransformIdentity outOfBoundsValue:0] autorelease];
            });
        }
    }
    
#undef visited
#undef rvoxel
}

@end

@implementation NIThresholdIntervalSegmentation

- (CGFloat)interval {
    return CGFloatAbs(self.higherThreshold-self.lowerThreshold);
}

- (void)setInterval:(CGFloat)interval {
    self.higherThreshold = self.lowerThreshold + interval;
}

- (NSString*)name {
    return NSLocalizedString(@"Thresholding (interval)", nil);
}

- (NSViewController*)viewController {
    NIView* view = [[[NIView alloc] initWithFrame:NSZeroRect] autorelease];
    
    NSTextField* linterval = [NIView labelWithControlSize:NSSmallControlSize];
    linterval.stringValue = NSLocalizedString(@"Interval:", nil);
    [view addSubview:linterval];
    
    NSTextField* finterval = [NIView fieldWithControlSize:NSSmallControlSize];
    [view addSubview:finterval];
    
    [finterval addConstraint:[NSLayoutConstraint constraintWithItem:finterval attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:40]];
    
    [finterval bind:@"value" toObject:self withKeyPath:@"interval" options:nil];

    return [[[NIViewController alloc] initWithView:view updateConstraints:^{
        [view removeAllConstraints];
        NSDictionary* m = @{ @"s": @4 };
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[linterval]-s-[finterval]|" options:NSLayoutFormatAlignAllBaseline metrics:m views:NSDictionaryOfVariableBindings(linterval, finterval)]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[finterval]|" options:0 metrics:m views:NSDictionaryOfVariableBindings(finterval)]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:view.fittingSize.width]];
    }] autorelease];
}

- (void)processWithSeeds:(NSArray*)seeds volume:(NIVolumeData*)data annotation:(NIMaskAnnotation*)ma operation:(NSOperation*)op {
    NIMaskIndex seed = [seeds[0] NIMaskIndexValue];
    CGFloat seedv = [data floatAtPixelCoordinateX:seed.x y:seed.y z:seed.z], interval = self.interval;
    [super processWithSeeds:seeds volume:data annotation:ma operation:op thresholds:seedv-interval/2 :seedv+interval/2];
}

@end
