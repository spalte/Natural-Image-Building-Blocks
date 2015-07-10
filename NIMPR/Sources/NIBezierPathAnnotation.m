//
//  NIBezierPathAnnotation.m
//  NIMPR
//
//  Created by Alessandro Volz on 7/9/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIBezierPathAnnotation.h"

@implementation NIBezierPathAnnotation

- (NIBezierPath*)NIBezierPath {
    [NSException raise:NSInvalidArgumentException format:@"Method -[%@ NIBezierPath] must be implemented for all NIBezierPathAnnotation subclasses", self.className];
    return nil;
}

+ (NSSet*)keyPathsForValuesAffectingAnnotation {
    return [[super keyPathsForValuesAffectingAnnotation] setByAddingObject:@"NIBezierPath"];
}

- (void)drawInView:(NIAnnotatedGeneratorRequestView*)view {
    NIObliqueSliceGeneratorRequest* req = (id)view.presentedGeneratorRequest;
    NIAffineTransform dicomToSliceTransform = NIAffineTransformInvert(req.sliceToDicomTransform);
    
    NIBezierPath* path = [self.NIBezierPath bezierPathByApplyingTransform:dicomToSliceTransform];
    
    [[[NSColor greenColor] colorWithAlphaComponent:0.2] setStroke];
    [path.NSBezierPath stroke];
    
    // TODO: The next line is 100% wrong! I misinterpreted the bezierPathByClippingFromRelativePosition:toRelativePosition: for bezierPathByClippingZValuesBetween:and: ... so how can we do that?
    NIBezierPath* clips = [path bezierPathByClippingFromRelativePosition:req.slabWidth/2 toRelativePosition:-req.slabWidth/2];

    [[[NSColor greenColor] colorWithAlphaComponent:0.8] setStroke];
    [clips.NSBezierPath stroke];
    
    // points
    
}

@end

@implementation NINSBezierPathAnnotation

@synthesize sliceToDicomTransform = _sliceToDicomTransform;

- (instancetype)initWithTransform:(NIAffineTransform)sliceToDicomTransform {
    if ((self = [super init])) {
        self.sliceToDicomTransform = sliceToDicomTransform;
    }
    
    return self;
}

- (NIBezierPath*)NIBezierPath {
    NIMutableBezierPath* p = [NIMutableBezierPath bezierPath];
    NIAffineTransform transform = self.sliceToDicomTransform;
    
    NSBezierPath* nsp = self.NSBezierPath;
    NSInteger elementCount = nsp.elementCount;
    NSPoint points[3];
    
    for (NSInteger i = 0; i < elementCount; ++i)
        switch ([nsp elementAtIndex:i associatedPoints:points]) {
            case NSMoveToBezierPathElement: {
                [p moveToVector:NIVectorApplyTransform(NIVectorMakeFromNSPoint(points[0]), transform)];
            } break;
            case NSLineToBezierPathElement: {
                [p lineToVector:NIVectorApplyTransform(NIVectorMakeFromNSPoint(points[0]), transform)];
            } break;
            case NSCurveToBezierPathElement: {
                [p curveToVector:NIVectorApplyTransform(NIVectorMakeFromNSPoint(points[2]), transform) controlVector1:NIVectorApplyTransform(NIVectorMakeFromNSPoint(points[0]), transform) controlVector2:NIVectorApplyTransform(NIVectorMakeFromNSPoint(points[1]), transform)];
            } break;
            case NSClosePathBezierPathElement: {
                [p close];
            } break;
        }
    
    return p;
}

+ (NSSet*)keyPathsForValuesAffectingNIBezierPath {
    return [NSSet setWithObject:@"NSBezierPath"];
}

- (NSBezierPath*)NSBezierPath {
    [NSException raise:NSInvalidArgumentException format:@"Method -[%@ NSBezierPath] must be implemented for all NINSBezierPathAnnotation subclasses", self.className];
    return nil;
}

@end