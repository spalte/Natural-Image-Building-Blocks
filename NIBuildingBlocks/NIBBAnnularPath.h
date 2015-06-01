//  Created by Joël Spaltenstein on 4/29/15.
//  Copyright (c) 2015 Spaltenstein Natural Image
//  Copyright (c) 2015 Michael Hilker and Andreas Holzamer
//  Copyright (c) 2015 volz io
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>

#import "NIBBGeometry.h"

@class NIBBBezierPath;
@class NIBBObliqueSliceGeneratorRequest;

typedef NSInteger NIBBAnnularPathControlPointID;

@interface NIBBAnnularPath : NSObject <NSCopying>
{
    NIBBVector _annularOrigin;
    NIBBVector _axialDirection;
    NSMutableDictionary *_controlPoints;
    NIBBAnnularPathControlPointID _idCounter;
}

- (instancetype)initWithAnnularOrigin:(NIBBVector)annularOrigin axialDirection:(NIBBVector)axialDirection;

@property (nonatomic, readonly, copy) NIBBBezierPath *bezierpath;
@property (nonatomic, readonly, assign) NIBBVector annularOrigin;
@property (nonatomic, readonly, assign) NIBBVector axialDirection;
@property (nonatomic, readonly, assign) NIBBPlane plane;
@property (nonatomic, readonly, assign) CGFloat perimeter; // in mm
@property (nonatomic, readonly, assign) CGFloat area; // in mm^2

- (NIBBAnnularPathControlPointID)addControlPointAtPosition:(NIBBVector)position; // returns the ID of the added control point
- (void)setPosition:(NIBBVector)position forControlPointID:(NIBBAnnularPathControlPointID)controlPointID;
- (NIBBVector)positionForControlPointID:(NIBBAnnularPathControlPointID)controlPointID;
- (NIBBAnnularPathControlPointID)controlPointIDForControlPointNearPosition:(NIBBVector)position; // returns -1 if there is no control point at the position
- (NSArray *)orderedControlPointIDs;
- (NSArray *)orderedControlPointPositions;

- (void)diameterMinStart:(NIBBVectorPointer)minStart minEnd:(NIBBVectorPointer)minEnd maxStart:(NIBBVectorPointer)maxStart maxEnd:(NIBBVectorPointer)maxEnd;

@end


@interface NSNumber (NIBBAnnularPath)
+ (NSNumber *)numberWithNIBBAnnularPathControlPointID:(NIBBAnnularPathControlPointID)controlPointID;
- (NIBBAnnularPathControlPointID)NIBBAnnularPathControlPointIDValue;
@end