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

#import "NIGeometry.h"

@class NIBezierPath;
@class NIObliqueSliceGeneratorRequest;

typedef NSInteger NIAnnularPathControlPointID;

@interface NIAnnularPath : NSObject <NSCopying, NSSecureCoding>
{
    NIVector _annularOrigin;
    NIVector _axialDirection;
    NSMutableDictionary<NSNumber*, NSValue*> *_controlPoints;
    NIAnnularPathControlPointID _idCounter;
}

- (instancetype)initWithAnnularOrigin:(NIVector)annularOrigin axialDirection:(NIVector)axialDirection;

@property (nonatomic, readonly, copy) NIBezierPath *bezierpath;
@property (nonatomic, readonly, assign) NIVector annularOrigin;
@property (nonatomic, readonly, assign) NIVector axialDirection;
@property (nonatomic, readonly, assign) NIPlane plane;
@property (nonatomic, readonly, assign) CGFloat perimeter; // in mm
@property (nonatomic, readonly, assign) CGFloat area; // in mm^2

- (NIAnnularPathControlPointID)addControlPointAtPosition:(NIVector)position; // returns the ID of the added control point
- (void)setPosition:(NIVector)position forControlPointID:(NIAnnularPathControlPointID)controlPointID;
- (NIVector)positionForControlPointID:(NIAnnularPathControlPointID)controlPointID;
- (NIAnnularPathControlPointID)controlPointIDForControlPointNearPosition:(NIVector)position; // returns -1 if there is no control point at the position
- (NSArray *)orderedControlPointIDs;
- (NSArray *)orderedControlPointPositions;

- (void)diameterMinStart:(NIVectorPointer)minStart minEnd:(NIVectorPointer)minEnd maxStart:(NIVectorPointer)maxStart maxEnd:(NIVectorPointer)maxEnd;

@end


@interface NSNumber (NIAnnularPath)
+ (NSNumber *)numberWithNIAnnularPathControlPointID:(NIAnnularPathControlPointID)controlPointID;
- (NIAnnularPathControlPointID)NIAnnularPathControlPointIDValue;
@end