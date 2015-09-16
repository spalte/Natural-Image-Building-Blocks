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

@interface NIMaskTests : XCTestCase

@end

@implementation NIMaskTests

//- (void)setUp {
//    [super setUp];
//    // Put setup code here. This method is called before the invocation of each test method in the class.
//}
//
//- (void)tearDown {
//    // Put teardown code here. This method is called after the invocation of each test method in the class.
//    [super tearDown];
//}

- (void)testResamplingWithInterpolationModeNearestNeighbor {
    [self subtestResamplingWithInterpolationMode:NIInterpolationModeNearestNeighbor];
}

- (void)testResamplingWithInterpolationModeLinear {
    [self subtestResamplingWithInterpolationMode:NIInterpolationModeLinear];
}

- (void)testResamplingWithInterpolationModeCubic {
    [self subtestResamplingWithInterpolationMode:NIInterpolationModeCubic];
}

- (void)subtestResamplingWithInterpolationMode:(NIInterpolationMode)im {
    NIMask* mask = [NIMask maskWithBoxWidth:10 height:1 depth:1];
    
    NIAffineTransform t = NIAffineTransformMakeRotation(M_PI/4, 0, 0, 1);
    
    NIMask* tmask = [mask maskByResamplingFromVolumeTransform:NIAffineTransformIdentity toVolumeTransform:t interpolationMode:im];
    NSLog(@"Transformed mask: %@", tmask);
    
    XCTAssert(tmask.maskRunCount > 0, @"Mask resampling result must not be empty");
    
    for (NSValue* mr in tmask.maskRuns)
        XCTAssert(mr.NIMaskRunValue.intensity >= 0 && mr.NIMaskRunValue.intensity <= 1, @"Invalid intensity for mark run %@", NSStringFromNIMaskRun(mr.NIMaskRunValue));
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
