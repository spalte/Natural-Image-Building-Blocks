//  Copyright (c) 2016 Spaltenstein Natural Image
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

#import "NIStorageBox.h"

#import "NIGeometry.h"

@interface NIStorageBox ()
@property (nonatomic, readwrite, assign) NIStorageBoxType type;
@property (nonatomic, readwrite, assign) NIVector vector;
@property (nonatomic, readwrite, assign) NIAffineTransform transform;
@property (nonatomic, readwrite, assign) NIPlane plane;
@property (nonatomic, readwrite, assign) NILine line;
@property (nonatomic, readwrite, assign) NSPoint point;
@property (nonatomic, readwrite, assign) NSSize size;
@property (nonatomic, readwrite, assign) NSRect rect;

@end


@implementation NIStorageBox
@synthesize type = _type;
@synthesize vector = _vector;
@synthesize transform = _transform;
@synthesize plane = _plane;
@synthesize line = _line;
@synthesize point = _point;
@synthesize size = _size;
@synthesize rect = _rect;

+ (BOOL)supportsSecureCoding
{
    return YES;
}

+ (instancetype)storageBoxWithVector:(NIVector)vector
{
    NIStorageBox *box = [[[NIStorageBox alloc] init] autorelease];
    box.type = NIStorageBoxVector;
    box.vector = vector;
    return box;
}

+ (instancetype)storageBoxWithAffineTransform:(NIAffineTransform)transform
{
    NIStorageBox *box = [[[NIStorageBox alloc] init] autorelease];
    box.type = NIStorageBoxAffineTransform;
    box.transform = transform;
    return box;
}

+ (instancetype)storageBoxWithPlane:(NIPlane)plane
{
    NIStorageBox *box = [[[NIStorageBox alloc] init] autorelease];
    box.type = NIStorageBoxPlane;
    box.plane = plane;
    return box;
}

+ (instancetype)storageBoxWithLine:(NILine)line
{
    NIStorageBox *box = [[[NIStorageBox alloc] init] autorelease];
    box.type = NIStorageBoxLine;
    box.line = line;
    return box;
}

+ (instancetype)storageBoxWithPoint:(NSPoint)point
{
    NIStorageBox *box = [[[NIStorageBox alloc] init] autorelease];
    box.type = NIStorageBoxPoint;
    box.point = point;
    return box;
}

+ (instancetype)storageBoxWithSize:(NSSize)size
{
    NIStorageBox *box = [[[NIStorageBox alloc] init] autorelease];
    box.type = NIStorageBoxSize;
    box.size = size;
    return box;
}

+ (instancetype)storageBoxWithRect:(NSRect)rect
{
    NIStorageBox *box = [[[NIStorageBox alloc] init] autorelease];
    box.type = NIStorageBoxRect;
    box.rect = rect;
    return box;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ( (self = [super init]) ) {
        self.type = [aDecoder decodeIntegerForKey:@"type"];

        switch (self.type) {
            case NIStorageBoxVector:
            {
                self.vector = [aDecoder decodeNIVectorForKey:@"vector"];
                break;
            }
            case NIStorageBoxAffineTransform:
            {
                self.transform = [aDecoder decodeNIAffineTransformForKey:@"affineTransform"];
                break;
            }
            case NIStorageBoxPlane:
            {
                self.plane = [aDecoder decodeNIPlaneForKey:@"plane"];
                break;
            }
            case NIStorageBoxLine:
            {
                self.line = [aDecoder decodeNILineForKey:@"line"];
                break;
            }
            case NIStorageBoxPoint:
            {
                self.point = [aDecoder decodePointForKey:@"point"];
                break;
            }
            case NIStorageBoxSize:
            {
                self.size = [aDecoder decodeSizeForKey:@"size"];
                break;
            }
            case NIStorageBoxRect:
            {
                self.rect = [aDecoder decodeRectForKey:@"rect"];
                break;
            }
        }
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.type forKey:@"type"];

    switch (self.type) {
        case NIStorageBoxVector:
        {
            [aCoder encodeNIVector:self.vector forKey:@"vector"];
            break;
        }
        case NIStorageBoxAffineTransform:
        {
            [aCoder encodeNIAffineTransform:self.transform forKey:@"affineTransform"];
            break;
        }
        case NIStorageBoxPlane:
        {
            [aCoder encodeNIPlane:self.plane forKey:@"plane"];
            break;
        }
        case NIStorageBoxLine:
        {
            [aCoder encodeNILine:self.line forKey:@"line"];
            break;
        }
        case NIStorageBoxPoint:
        {
            [aCoder encodePoint:self.point forKey:@"point"];
            break;
        }
        case NIStorageBoxSize:
        {
            [aCoder encodeSize:self.size forKey:@"size"];
            break;
        }
        case NIStorageBoxRect:
        {
            [aCoder encodeRect:self.rect forKey:@"rect"];
            break;
        }
    }
}

- (id)value
{
    switch (self.type) {
        case NIStorageBoxVector:
            return [NSValue valueWithNIVector:self.vector];
        case NIStorageBoxAffineTransform:
            return [NSValue valueWithNIAffineTransform:self.transform];
        case NIStorageBoxPlane:
            return [NSValue valueWithNIPlane:self.plane];
        case NIStorageBoxLine:
            return [NSValue valueWithNILine:self.line];
        case NIStorageBoxPoint:
            return [NSValue valueWithPoint:self.point];
        case NIStorageBoxSize:
            return [NSValue valueWithSize:self.size];
        case NIStorageBoxRect:
            return [NSValue valueWithRect:self.rect];
    }
    return nil;
}

- (NSString *)stringValue
{
    switch (self.type) {
        case NIStorageBoxVector:
            return NSStringFromNIVector(self.vector);
        case NIStorageBoxAffineTransform:
            return NSStringFromNIAffineTransform(self.transform);
        case NIStorageBoxPlane:
            return NSStringFromNIPlane(self.plane);
        case NIStorageBoxLine:
            return NSStringFromNILine(self.line);
        case NIStorageBoxPoint:
            return NSStringFromPoint(self.point);
        case NIStorageBoxSize:
            return NSStringFromSize(self.size);
        case NIStorageBoxRect:
            return NSStringFromRect(self.rect);
    }
    return nil;
}

@end
