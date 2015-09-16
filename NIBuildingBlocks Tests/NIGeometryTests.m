//  Copyright (c) 2015 OsiriX Foundation
//  Copyright (c) 2015 Spaltenstein Natural Image
//  Copyright (c) 2015 volz.io
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

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <NIBuildingBlocks/NIMask.h>

@interface NIGeometryTests : XCTestCase

@end

@implementation NIGeometryTests

- (void)testNIPlaneLeastSquaresPlaneFromPoints0 {
    NIVector vectors[] = {};
    [self subtestNIPlaneLeastSquaresPlaneFromPoints:vectors count:0 expect:NIPlaneInvalid];
}

- (void)testNIPlaneLeastSquaresPlaneFromPoints1 {
    NIVector vectors[] = {
        NIVectorMake(0, 0, 0)
    };
    [self subtestNIPlaneLeastSquaresPlaneFromPoints:vectors count:1 expect:NIPlaneInvalid];
}

- (void)testNIPlaneLeastSquaresPlaneFromPoints2 {
    NIVector vectors[] = {
        NIVectorMake(0, 0, 0),
        NIVectorMake(1, 1, 1)
    };
    [self subtestNIPlaneLeastSquaresPlaneFromPoints:vectors count:2 expect:NIPlaneInvalid];
}

- (void)testNIPlaneLeastSquaresPlaneFromPoints3X {
    NIVector vectors[] = {
        NIVectorMake(0, 0, 0),
        NIVectorMake(0, 2, 1),
        NIVectorMake(0, 1, 1)
    };
    [self subtestNIPlaneLeastSquaresPlaneFromPoints:vectors count:3 expect:NIPlaneXZero];
}

- (void)testNIPlaneLeastSquaresPlaneFromPoints3Y {
    NIVector vectors[] = {
        NIVectorMake(0, 0, 0),
        NIVectorMake(1, 0, 1),
        NIVectorMake(2, 0, 1)
    };
    [self subtestNIPlaneLeastSquaresPlaneFromPoints:vectors count:3 expect:NIPlaneYZero];
}

- (void)testNIPlaneLeastSquaresPlaneFromPoints3Z {
    NIVector vectors[] = {
        NIVectorMake(0, 0, 0),
        NIVectorMake(2, 1, 0),
        NIVectorMake(1, 1, 0)
    };
    [self subtestNIPlaneLeastSquaresPlaneFromPoints:vectors count:3 expect:NIPlaneZZero];
}

- (void)testNIPlaneLeastSquaresPlaneFromPoints3N { // three nil (zero) points
    NIVector vectors[] = {
        NIVectorMake(0, 0, 0),
        NIVectorMake(0, 0, 0),
        NIVectorMake(0, 0, 0)
    };
    [self subtestNIPlaneLeastSquaresPlaneFromPoints:vectors count:3 expect:NIPlaneInvalid];
}

- (void)testNIPlaneLeastSquaresPlaneFromPoints3A { // three aligned points
    NIVector vectors[] = {
        NIVectorMake(0, 0, 0),
        NIVectorMake(1, 1, 1),
        NIVectorMake(2, 2, 2)
    };
    [self subtestNIPlaneLeastSquaresPlaneFromPoints:vectors count:3 expect:NIPlaneInvalid];
}

- (void)testNIPlaneLeastSquaresPlaneFromPoints4X {
    NIVector vectors[] = {
        NIVectorMake(0, 0, 0),
        NIVectorMake(0, 1, 1),
        NIVectorMake(0, 1, 2),
        NIVectorMake(0, 2, 1)
    };
    [self subtestNIPlaneLeastSquaresPlaneFromPoints:vectors count:3 expect:NIPlaneXZero];
}

- (void)testNIPlaneLeastSquaresPlaneFromPoints4Y {
    NIVector vectors[] = {
        NIVectorMake(0, 0, 0),
        NIVectorMake(1, 0, 2),
        NIVectorMake(1, 0, 1),
        NIVectorMake(2, 0, 1)
    };
    [self subtestNIPlaneLeastSquaresPlaneFromPoints:vectors count:3 expect:NIPlaneYZero];
}

- (void)testNIPlaneLeastSquaresPlaneFromPoints4Z {
    NIVector vectors[] = {
        NIVectorMake(0, 0, 0),
        NIVectorMake(1, 1, 0),
        NIVectorMake(1, 2, 0),
        NIVectorMake(2, 1, 0)
    };
    [self subtestNIPlaneLeastSquaresPlaneFromPoints:vectors count:3 expect:NIPlaneZZero];
}

- (void)testNIPlaneLeastSquaresPlaneFromPoints4N { // four nil (zero) points
    NIVector vectors[] = {
        NIVectorMake(0, 0, 0),
        NIVectorMake(0, 0, 0),
        NIVectorMake(0, 0, 0),
        NIVectorMake(0, 0, 0)
    };
    [self subtestNIPlaneLeastSquaresPlaneFromPoints:vectors count:4 expect:NIPlaneInvalid];
}

- (void)testNIPlaneLeastSquaresPlaneFromPoints4A { // four aligned points
    NIVector vectors[] = {
        NIVectorMake(0, 0, 0),
        NIVectorMake(1, 1, 1),
        NIVectorMake(2, 2, 2),
        NIVectorMake(3, 3, 3)
    };
    [self subtestNIPlaneLeastSquaresPlaneFromPoints:vectors count:4 expect:NIPlaneInvalid];
}

- (void)subtestNIPlaneLeastSquaresPlaneFromPoints:(NIVectorArray)points count:(NSUInteger)count expect:(NIPlane)ep {
    NIPlane p = NIPlaneLeastSquaresPlaneFromPoints(points, count);
    XCTAssert(NIPlaneEqualToPlane(p, ep), @"Returned least squares plane %@ is not equal to expected plane %@", NSStringFromNIPlane(p), NSStringFromNIPlane(ep));
}

@end
