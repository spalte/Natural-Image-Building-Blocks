//
//  MPRController.m
//  MPR
//
//  Created by Alessandro Volz on 5/19/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "CPRMPRController.h"
#import <OsiriXAPI/CPRVolumeData.h>
#import "CPRMPRIntersection.h"
#import "CPRMPRQuaternion.hpp"

@interface CPRMPRController ()

//@property N3AffineTransform transform;
@property(retain) CPRMPRQuaternion *x, *y, *z;

@end

@implementation CPRMPRController

@synthesize leftrightSplit = _leftrightSplit;
@synthesize topbottomSplit = _topbottomSplit;
@synthesize topleftView = _topleftView;
@synthesize bottomleftView = _bottomleftView;
@synthesize rightView = _rightView;
@synthesize data = _data;
//@synthesize transform = _transform;
@synthesize point = _point;
@synthesize ww = _ww, wl = _wl;
@synthesize x = _x, y = _y, z = _z;

- (instancetype)initWithData:(CPRVolumeData*)data {
    if ((self = [super initWithWindowNibName:@"CPRMPR" owner:self])) {
        self.data = data;
//        self.transform = transform;
        self.point = N3VectorApplyTransform(N3VectorMake(data.pixelsWide/2, data.pixelsHigh/2, data.pixelsDeep/2), N3AffineTransformInvert(data.volumeTransform));
        self.x = [CPRMPRQuaternion quaternion:N3VectorApplyTransformToDirectionalVector(N3VectorMake(1,0,0), data.volumeTransform)];
        self.y = [CPRMPRQuaternion quaternion:N3VectorApplyTransformToDirectionalVector(N3VectorMake(0,1,0), data.volumeTransform)];
        self.z = [CPRMPRQuaternion quaternion:N3VectorApplyTransformToDirectionalVector(N3VectorMake(0,0,1), data.volumeTransform)];
    }
    
    return self;
}

- (void)awakeFromNib {
    self.topleftView.color = [NSColor orangeColor];
    self.bottomleftView.color = [NSColor purpleColor];
    self.rightView.color = [NSColor blueColor];
    
    [self view:self.topleftView addIntersections:@{ @"bottomleft": self.bottomleftView, @"right": self.rightView }];
    [self view:self.bottomleftView addIntersections:@{ @"topleft": self.topleftView, @"right": self.rightView }];
    [self view:self.rightView addIntersections:@{ @"topleft": self.topleftView, @"bottomleft": self.bottomleftView }];

    [self.topleftView bind:@"volumeData" toObject:self withKeyPath:@"data" options:nil];
    [self.bottomleftView bind:@"volumeData" toObject:self withKeyPath:@"data" options:nil];
    [self.rightView bind:@"volumeData" toObject:self withKeyPath:@"data" options:nil];
    
    [self.topleftView bind:@"point" toObject:self withKeyPath:@"point" options:nil];
    [self.bottomleftView bind:@"point" toObject:self withKeyPath:@"point" options:nil];
    [self.rightView bind:@"point" toObject:self withKeyPath:@"point" options:nil];
    
    [self addObserver:self forKeyPath:@"transform" options:NSKeyValueObservingOptionInitial context:CPRMPRController.class];
    [self addObserver:self forKeyPath:@"data" options:NSKeyValueObservingOptionInitial context:CPRMPRController.class];
}

- (void)view:(CPRMPRView*)view addIntersections:(NSDictionary*)others {
    [others enumerateKeysAndObjectsUsingBlock:^(NSString* key, CPRMPRView* other, BOOL* stop) {
        CPRIntersection* intersection = [[[CPRMPRIntersection alloc] initWithMPRView:other] autorelease];
        intersection.maskAroundMouseRadius = intersection.maskCirclePointRadius = 30;
        [intersection bind:@"color" toObject:other withKeyPath:@"color" options:nil];
        [intersection bind:@"intersectingObject" toObject:other withKeyPath:@"generatorRequest" options:nil];
        [view addIntersection:intersection forKey:key];
    }];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"data" context:CPRMPRController.class];
    [self removeObserver:self forKeyPath:@"transform" context:CPRMPRController.class];
    self.x = nil;
    self.y = nil;
    self.z = nil;
    self.data = nil;
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != CPRMPRController.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"transform"]) {
        [self updateNormals];
    }
    
    if ([keyPath isEqualToString:@"data"]) {
        NSArray* views = @[ self.topleftView, self.bottomleftView, self.rightView ];
        CGFloat pixelSpacing = 0, pixelSpacingSize = 0;
        
        for (CPRMPRView* view in views) {
            CGFloat pss = fmin(NSWidth(view.frame), NSHeight(view.frame)), ps = pss/N3VectorDistance(N3VectorZero, N3VectorMake(self.data.pixelsWide, self.data.pixelsHigh, self.data.pixelsDeep));
            if (!pixelSpacing || ps < pixelSpacing) {
                pixelSpacing = ps;
                pixelSpacingSize = pss;
            }
        }
        
        for (CPRMPRView* view in views)
            view.pixelSpacing = pixelSpacing/pixelSpacingSize*fmin(NSWidth(view.frame), NSHeight(view.frame));
    }
}

- (void)rotate:(CGFloat)rads axis:(N3Vector)axis {
    [self.x rotate:rads axis:axis];
    [self.y rotate:rads axis:axis];
    [self.z rotate:rads axis:axis];
    [self updateNormals];
}

- (void)updateNormals {
    NSLog(@"Updating normals, quaternions: %@, %@, %@", self.x, self.y, self.z);
    N3Vector x = self.x.vector; // N3VectorNormalize(N3VectorApplyTransformToDirectionalVector(self.x.vector, self.data.volumeTransform));
    N3Vector y = self.y.vector; // N3VectorNormalize(N3VectorApplyTransformToDirectionalVector(self.y.vector, self.data.volumeTransform));
    N3Vector z = self.z.vector; // N3VectorNormalize(N3VectorApplyTransformToDirectionalVector(self.z.vector, self.data.volumeTransform));
    [self.topleftView setNormal:x:y:z];
    [self.rightView setNormal:y:x:z];
    [self.bottomleftView setNormal:z:x:y];
}



@end
