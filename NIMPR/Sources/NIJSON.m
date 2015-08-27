//
//  NIJSONCoder.m
//  NIMPR
//
//  Created by Alessandro Volz on 8/17/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIJSON.h"
#import <NIBuildingBlocks/NIGeometry.h>
#import <NIBuildingBlocks/NIMask.h>
#import <objc/runtime.h>

static NSString* const NIJSONClass = @"class";
static NSString* const NIJSONType = @"type";
//static NSString* const NIJSONValues = @"values";

@class NIJSONArchiver, NIJSONUnarchiver;

typedef void (^NIJSONArchiverBlock)(NIJSONArchiver* archiver, id obj);
typedef id (^NIJSONUnarchiverBlock)(NIJSONUnarchiver* unarchiver);

@interface _NIJSONRecord : NSObject {
    NSString* _name;
    id _type;
    NIJSONArchiverBlock _encoder;
    NIJSONUnarchiverBlock _decoder;
}

@property(retain, readwrite) NSString* name;
@property(retain, readwrite) id type;
@property(nonatomic, copy) NIJSONArchiverBlock encoder;
@property(nonatomic, copy) NIJSONUnarchiverBlock decoder;

@end

@implementation _NIJSONRecord

@synthesize name = _name;
@synthesize type = _type;
@synthesize encoder = _encoder;
@synthesize decoder = _decoder;

+ (instancetype)recordWithName:(NSString*)name type:(id)type encoder:(void (^)(NIJSONArchiver* archiver, id obj))encoder decoder:(id (^)(NIJSONUnarchiver* unarchiver))decoder {
    return [[[self.class alloc] initWithName:name type:type encoder:encoder decoder:decoder] autorelease];
}

- (instancetype)initWithName:(NSString*)name type:(id)type encoder:(void (^)(NIJSONArchiver* archiver, id obj))encoder decoder:(id (^)(NIJSONUnarchiver* unarchiver))decoder {
    if ((self = [super init])) {
        self.name = name;
        self.type = type;
        self.encoder = encoder;
        self.decoder = decoder;
    }
    
    return self;
}

- (void)dealloc {
    self.name = nil;
    self.type = nil;
    self.encoder = nil;
    self.decoder = nil;
    [super dealloc];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@ name: \"%@\" type: \"%@\">", self.className, self.name, self.type];
}

@end

@implementation NIJSON

+ (void)load {
    [self setName:@"rect" forValueObjCType:@encode(NSRect) encoder:^(NIJSONArchiver *archiver, NSValue *val) {
        NSRect rect = val.rectValue;
        [archiver encodeObject:@[ @(rect.origin.x), @(rect.origin.y), @(rect.size.width), @(rect.size.height) ] forKey:@"xywh"];
    } decoder:^NSValue *(NIJSONUnarchiver *unarchiver) {
        NSArray* values = [unarchiver decodeObjectForKey:@"xywh"];
        return [NSValue valueWithRect:NSMakeRect([values[0] CGFloatValue], [values[1] CGFloatValue], [values[2] CGFloatValue], [values[3] CGFloatValue])];
    }];
    
    [self setName:@"point" forValueObjCType:@encode(NIVector) encoder:^(NIJSONArchiver *archiver, NSValue *val) {
        NIVector vect = val.NIVectorValue;
        [archiver encodeObject:(vect.z? @[ @(vect.x), @(vect.y), @(vect.z) ] : @[ @(vect.x), @(vect.y) ]) forKey:@"xyz"];
    } decoder:^NSValue *(NIJSONUnarchiver *unarchiver) {
        NSArray* values = [unarchiver decodeObjectForKey:@"xyz"];
        return [NSValue valueWithNIVector:NIVectorMake([values[0] CGFloatValue], [values[1] CGFloatValue], [[values objectAtIndex:2 or:@0] CGFloatValue])];
    }];
    
    [self setName:@"transform" forValueObjCType:@encode(NIAffineTransform) encoder:^(NIJSONArchiver *archiver, NSValue *val) {
        NIAffineTransform t = val.NIAffineTransformValue;
        [archiver encodeObject:@[ @(t.m11), @(t.m12), @(t.m13), @(t.m14), @(t.m21), @(t.m22), @(t.m23), @(t.m24), @(t.m31), @(t.m32), @(t.m33), @(t.m34), @(t.m41), @(t.m42), @(t.m43), @(t.m44) ] forKey:@"matrix"];
    } decoder:^NSValue *(NIJSONUnarchiver *unarchiver) {
        NSArray* values = [unarchiver decodeObjectForKey:@"matrix"];
        NIAffineTransform t = { [values[0] CGFloatValue], [values[1] CGFloatValue], [values[2] CGFloatValue], [values[3] CGFloatValue],
            [values[4] CGFloatValue], [values[5] CGFloatValue], [values[6] CGFloatValue], [values[7] CGFloatValue],
            [values[8] CGFloatValue], [values[9] CGFloatValue], [values[10] CGFloatValue], [values[11] CGFloatValue],
            [values[12] CGFloatValue], [values[13] CGFloatValue], [values[14] CGFloatValue], [values[15] CGFloatValue] };
        return [NSValue valueWithNIAffineTransform:t];
    }];
    
    [self setName:@"data" forClass:NSData.class encoder:^(NIJSONArchiver *archiver, NSData* obj) { // we could encode using base85, but that would make thigs harder for other people trying to read our blobs... so, base64
        [archiver encodeObject:[obj base64EncodedStringWithOptions:0] forKey:@"base64"];
    } decoder:^id(NIJSONUnarchiver *unarchiver) {
        return [[NSData alloc] initWithBase64EncodedString:[unarchiver decodeObjectForKey:@"base64"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }];
    
    static NSColorList* colorlist = nil;
    if (!colorlist)
        colorlist = [[NSColorList alloc] init];
    [colorlist setColor:[NSColor blackColor] forKey:@"black"]; // 0.0 white
    [colorlist setColor:[NSColor darkGrayColor] forKey:@"darkgray"]; // 0.333 white
    [colorlist setColor:[NSColor lightGrayColor] forKey:@"lightgray"]; // 0.667 white
    [colorlist setColor:[NSColor whiteColor] forKey:@"white"]; // 1.0 white
    [colorlist setColor:[NSColor grayColor] forKey:@"gray"]; // 0.5 white
    [colorlist setColor:[NSColor redColor] forKey:@"red"]; // 1.0, 0.0, 0.0 RGB
    [colorlist setColor:[NSColor greenColor] forKey:@"green"]; // 0.0, 1.0, 0.0 RGB
    [colorlist setColor:[NSColor blueColor] forKey:@"blue"]; // 0.0, 0.0, 1.0 RGB
    [colorlist setColor:[NSColor cyanColor] forKey:@"cyan"]; // 0.0, 1.0, 1.0 RGB
    [colorlist setColor:[NSColor yellowColor] forKey:@"yellow"]; // 1.0, 1.0, 0.0 RGB
    [colorlist setColor:[NSColor magentaColor] forKey:@"magenta"]; // 1.0, 0.0, 1.0 RGB
    [colorlist setColor:[NSColor orangeColor] forKey:@"orange"]; // 1.0, 0.5, 0.0 RGB
    [colorlist setColor:[NSColor purpleColor] forKey:@"purple"]; // 0.5, 0.0, 0.5 RGB
    [colorlist setColor:[NSColor brownColor] forKey:@"brown"]; // 0.6, 0.4, 0.2 RGB
    
    [self setName:@"color" forClass:NSColor.class encoder:^(NIJSONArchiver *archiver, NSColor *color) {
        NSColor* color1 = color.alphaComponent != 1 ? [color colorWithAlphaComponent:1] : color;
        NSString* key = [[colorlist.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* key, NSDictionary *bindings) {
            return [[colorlist colorWithKey:key] isEqual:color1];
        }]] lastObject];
        if (key) {
            [archiver encodeObject:key forKey:@"name"];
            if (color.alphaComponent != 1)
                [archiver encodeCGFloat:color.alphaComponent forKey:@"alpha"];
        } else {
            CGFloat components[4]; [[color colorUsingColorSpace:NSColorSpace.genericRGBColorSpace] getComponents:components];
            NSArray* rgba = (components[3] != 1 ? @[ @(components[0]), @(components[1]), @(components[2]), @(components[3]) ] : @[ @(components[0]), @(components[1]), @(components[2]) ]);
            [archiver encodeObject:rgba forKey:@"rgba"];
        }
    } decoder:^NSColor *(NIJSONUnarchiver *unarchiver) {
        if ([unarchiver containsValueForKey:@"name"]) {
            NSColor* color = [colorlist colorWithKey:[unarchiver decodeObjectForKey:@"name"]];
            if ([unarchiver containsValueForKey:@"alpha"])
                color = [color colorWithAlphaComponent:[unarchiver decodeCGFloatForKey:@"alpha"]];
            return color;
        }
        
        NSArray* rgba = [unarchiver decodeObjectForKey:@"rgba"];
        return [NSColor colorWithCalibratedRed:[rgba[0] CGFloatValue] green:[rgba[1] CGFloatValue] blue:[rgba[2] CGFloatValue] alpha:[[rgba objectAtIndex:3 or:@1] CGFloatValue]];
    }];
    
    [self setName:@"mask" forClass:NIMask.class encoder:^(NIJSONArchiver *archiver, NIMask *mask) { // [ [ ([ widthLocation, widthLength ]|widthLocation), heightIndex, depthIndex ](, intensity) ] // if width range is specified as an integer, its length defaults to 1; intensity defaults to 1
        NSMutableArray* mras = [NSMutableArray array];
        for (NSValue* mrv in mask.maskRuns) {
            NIMaskRun mr = mrv.NIMaskRunValue;
            NSMutableArray* mra = [NSMutableArray arrayWithObject:[NSMutableArray array]];
            if (mr.widthRange.length != 1)
                [mra[0] addObject:@[ @(mr.widthRange.location), @(mr.widthRange.length) ]];
            else [mra[0] addObject:@(mr.widthRange.location)];
            [mra[0] addObjectsFromArray:@[ @(mr.heightIndex), @(mr.depthIndex) ]];
            if (mr.intensity != 1)
                [mra addObject:@(mr.intensity)];
            [mras addObject:mra];
        }
        [archiver encodeObject:mras forKey:@"runs"];
    } decoder:^NIMask *(NIJSONUnarchiver *unarchiver) {
        NSArray* mras = [unarchiver decodeObjectForKey:@"runs"];
        NSMutableArray* mrs = [NSMutableArray array];
        for (NSArray* mra in mras) {
            NIMaskRun mr;
            if ([mra[0][0] isKindOfClass:NSArray.class]) {
                mr.widthRange.location = [mra[0][0][0] CGFloatValue];
                if ([mra[0][0] count] > 1)
                    mr.widthRange.length = [mra[0][0][1] CGFloatValue];
                else mr.widthRange.length = 1;
            } else mr.widthRange = NSMakeRange([mra[0][0] CGFloatValue], 1);
            mr.heightIndex = [mra[0][1] CGFloatValue];
            mr.depthIndex = [mra[0][2] CGFloatValue];
            if ([mra[0] count] > 1)
                mr.intensity = [mra[1] CGFloatValue];
            else mr.intensity = 1;
            [mrs addObject:[NSValue valueWithNIMaskRun:mr]];
        }
        return [[[NIMask alloc] initWithMaskRuns:mrs] autorelease];
    }];
}

static NSMutableArray* _NIJSONClassRecords = nil;

+ (void)setName:(NSString *)name forClass:(Class)cls {
    [self.class setName:name forClass:cls encoder:nil decoder:nil];
}

+ (void)setName:(NSString *)name forClass:(Class)cls encoder:(void (^)(NIJSONArchiver *, id))encoder decoder:(id (^)(NIJSONUnarchiver *))decoder {
    if (!_NIJSONClassRecords)
        _NIJSONClassRecords = [[NSMutableArray alloc] init];
    
    _NIJSONRecord* rec = [[_NIJSONClassRecords filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", name]] lastObject];
    if (rec)
        NSLog(@"Warning: registering class name %@ for class %@, name is already registered for class %@", name, NSStringFromClass(cls), NSStringFromClass(rec.type));
    
    [_NIJSONClassRecords addObject:[_NIJSONRecord recordWithName:name type:cls encoder:encoder decoder:decoder]];
}

+ (_NIJSONRecord*)_recordForClass:(Class)c {
    NSMutableArray* recScores = [NSMutableArray array];
    for (_NIJSONRecord* rec in _NIJSONClassRecords) {
        NSUInteger i = 0;
        for (Class ic = c; ic; ic = class_getSuperclass(ic), ++i)
            if (ic == rec.type) {
                [recScores addObject:@[ @(i), rec ]];
                break;
            }
    }
    
    return [[[recScores sortedArrayUsingComparator:^NSComparisonResult(NSArray* a1, NSArray* a2) {
        NSUInteger v1 = [a1[0] unsignedIntegerValue], v2 = [a2[0] unsignedIntegerValue];
        if (v1 > v2) return NSOrderedAscending;
        if (v1 < v2) return NSOrderedDescending;
        return NSOrderedSame;
    }] lastObject] lastObject];
}

static NSMutableArray* _NIJSONValueRecords = nil;

+ (void)setName:(NSString*)name forValueObjCType:(const char*)objcType encoder:(void (^)(NIJSONArchiver* archiver, NSValue* val))encoder decoder:(NSValue* (^)(NIJSONUnarchiver* unarchiver))decoder {
    if (!_NIJSONValueRecords)
        _NIJSONValueRecords = [[NSMutableArray alloc] init];
    
    _NIJSONRecord* rec = [[_NIJSONValueRecords filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", name]] lastObject];
    if (rec)
        NSLog(@"Warning: registering type name %@ for obj-c type %s, name is already registered for obj-c type %@", name, objcType, rec.type);
    
    [_NIJSONValueRecords addObject:[_NIJSONRecord recordWithName:name type:[NSString stringWithUTF8String:objcType] encoder:encoder decoder:decoder]];
}

+ (_NIJSONRecord*)_recordForValueObjCType:(const char*)objCType {
    return [[_NIJSONValueRecords filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", @(objCType)]] lastObject];
}

@end

@interface NIJSONArchiver ()

@property(retain) NSMutableString* json;
@property(retain) NSMutableArray* stack;
@property(retain) NSMutableDictionary *replacements;

@end

@implementation NIJSONArchiver

@synthesize json = _json, stack = _stack, replacements = _replacements;
@synthesize delegate = _delegate;

- (instancetype)initForWritingWithMutableString:(NSMutableString*)string {
    if ((self = [super init])) {
        self.json = string;
        self.stack = [NSMutableArray array];
        self.replacements = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)dealloc {
    self.replacements = nil;
    self.stack = nil;
    self.json = nil;
    [super dealloc];
}

- (void)encodeObject:(id)obj {
    return [self encodeObject:obj commas:YES];
}

- (void)encodeObject:(id)obj commas:(BOOL)commas {
    NSUInteger count = [self.stack.lastObject unsignedIntegerValue];
    if (commas) {
        [self.stack replaceObjectAtIndex:self.stack.count-1 withObject:@(count+1)];
        if (count)
            [self.json appendString:@", "];
    }
    
    NSValue* objrk = [NSValue valueWithPointer:obj];
    id objr = self.replacements[objrk];
    if (!objr) {
        objr = self.replacements[objrk] = [NSNull either:[self _archiver_willEncodeObject:obj]];
        [self _archiver_willReplaceObject:obj withObject:[objr ifn:NSNull.class]];
    }
    obj = [objr ifn:NSNull.class];
    
    _NIJSONRecord* rec;
    
    if (!obj) {
        [self.json appendString:@"null"];
    }
    else if ([obj isKindOfClass:NSString.class]) {
        [self.json appendFormat:@"\"%@\"", [[obj stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
    }
    else if ([obj isKindOfClass:NSNumber.class]) {
        if (strcmp([obj objCType], @encode(BOOL)) == 0)
            [self.json appendString:([obj intValue]? @"true" : @"false")];
        else [self.json appendFormat:@"%@", obj];
    }
    else if ([obj isKindOfClass:NSValue.class]) {
        if (!(rec = [NIJSON _recordForValueObjCType:[obj objCType]]))
            [NSException raise:NSInvalidArgumentException format:@"Value type %s is not supported by %@", [obj objCType], self.className];
        [self.json appendString:@"{ "];
        [self.stack addObject:@0];
        [self encodeObject:rec.name forKey:NIJSONType];
        if (rec.encoder)
            rec.encoder(self, obj);
        [self.stack removeLastObject];
        [self.json appendString:@" }"];
    }
    else if ([obj isKindOfClass:NSArray.class]) {
        [self.json appendString:@"[ "];
        [self.stack addObject:@0];
        [obj enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
            [self encodeObject:obj];
        }];
        [self.stack removeLastObject];
        [self.json appendString:@" ]"];
    }
    else if ([obj isKindOfClass:NSDictionary.class]) {
        [self.json appendString:@"{ "];
        [self.stack addObject:@0];
        [obj enumerateKeysAndObjectsUsingBlock:^(NSString* key, id obj, BOOL* stop) {
            [self encodeObject:obj forKey:key];
        }];
        [self.stack removeLastObject];
        [self.json appendString:@" }"];
    }
    else if ((rec = [NIJSON _recordForClass:[obj class]])) {
        [self.json appendString:@"{ "];
        [self.stack addObject:@0];
        [self encodeObject:rec.name forKey:NIJSONClass];
        if (rec.encoder)
            rec.encoder(self, obj);
        else [obj encodeWithCoder:self];
        [self.stack removeLastObject];
        [self.json appendString:@" }"];
    }
    else
        [NSException raise:NSInvalidArgumentException format:@"Class %@ is not supported by %@", [obj className], self.className];
    
    [self _archiver_didEncodeObject:obj];
}

- (void)encodeObject:(id)obj forKey:(NSString*)key {
    if (!self.stack.count) {
        [self.json appendString:@"{ "];
        [self.stack addObject:@0];
    }
    
    [self encodeObject:key];
    [self.json appendString:@": "];
    [self encodeObject:obj commas:NO];
}

- (void)finishEncoding {
    [self _archiverWillFinish];
    
    while (self.stack.count) {
        [self.stack removeLastObject];
        [self.json appendString:@" }"];
    }
    
    [self _archiverDidFinish];
}

- (void)encodeBool:(BOOL)boolv forKey:(NSString *)key {
    [self encodeObject:@(boolv) forKey:key];
}

- (void)encodeInt:(int)intv forKey:(NSString *)key {
    [self encodeObject:@(intv) forKey:key];
}

- (void)encodeInt32:(int32_t)intv forKey:(NSString *)key {
    [self encodeObject:@(intv) forKey:key];
}

- (void)encodeInt64:(int64_t)intv forKey:(NSString *)key {
    [self encodeObject:@(intv) forKey:key];
}

- (void)encodeFloat:(float)realv forKey:(NSString *)key {
    [self encodeObject:@(realv) forKey:key];
}

- (void)encodeDouble:(double)realv forKey:(NSString *)key {
    [self encodeObject:@(realv) forKey:key];
}

- (void)encodeCGFloat:(CGFloat)cgf forKey:(NSString *)key {
#if CGFLOAT_IS_DOUBLE
    [self encodeDouble:cgf forKey:key];
#else
    [self encodeFloat:cgf forKey:key];
#endif
}

- (void)encodeBytes:(const uint8_t *)bytesp length:(NSUInteger)lenv forKey:(NSString *)key {
    [self encodeObject:[NSData dataWithBytesNoCopy:(void*)bytesp length:lenv] forKey:key];
}


    
- (id)_archiver_willEncodeObject:(id)obj {
    if ([self.delegate respondsToSelector:@selector(archiver:willEncodeObject:)])
        return [self.delegate archiver:self willEncodeObject:obj];
    return obj;
}

- (void)_archiver_didEncodeObject:(id)obj {
    if ([self.delegate respondsToSelector:@selector(archiver:didEncodeObject:)])
        [self.delegate archiver:self didEncodeObject:obj];
}

- (void)_archiver_willReplaceObject:(id)obj withObject:(id)nobj {
    if ([self.delegate respondsToSelector:@selector(archiver:willReplaceObject:withObject:)])
        [self.delegate archiver:self willReplaceObject:obj withObject:nobj];
}

- (void)_archiverWillFinish {
    if ([self.delegate respondsToSelector:@selector(archiverWillFinish:)])
        [self.delegate archiverWillFinish:self];
}

- (void)_archiverDidFinish {
    if ([self.delegate respondsToSelector:@selector(archiverDidFinish:)])
        [self.delegate archiverDidFinish:self];
}






- (void)encodeValueOfObjCType:(const char *)type at:(const void *)addr {
    
}




//- (void)encodeValueOfObjCType:(const char *)type at:(const void *)addr {
//    NSLog(@"encodeValueOfObjCType:%s at:%lX -- %@", type, (unsigned long)addr, [NSObject valueWithBytes:addr objCType:type]);
//    
//    const size_t typelen = strlen(type);
//    
//    // JSON supports the following: Number, String, Boolean, Array, Object, null
//    
//    if (typelen == 0 && type[0] == '@') { // we're asked to encode an object... we only support some classes!
//        id obj = [self.class encodeObject:*(id*)addr];
//    }
//    
//    id obj = [NSObject valueWithBytes:addr objCType:type];
//
//    if ([obj isKindOfClass:NSNumber.class]) { // Numbers and Booleans
//        
//    }
//    
//    
//    if (typelen == 1)
//        switch (type[0]) {
//            case 'B': {
//                
//            } break;
//                
//        }
//    
//}

//+ (NSDictionary*)encodeObject:(id)obj {
//    NSDictionary* ed = nil;
//    if ([obj respondsToSelector:@selector(JSONObject)]) {
//        ed = [obj JSONObject];
//        if (!ed[NICodingClass])
//            [NSException raise:NSInternalInconsistencyException format:@"Implementation of -[%@ JSONObject] must provide a value for the NICodingClass key ('class')"];
//    }
//    
//    
//    [NSException raise:NSInvalidArgumentException format:@"Unsupported class for JSON encoding: %@", [obj className]];
//    return nil;
//}

//- (void)encodeDataObject:(NSData *)data {
//    [NSException raise:NSInternalInconsistencyException format:@"-[%@ %@] is not supported...", self.className, NSStringFromSelector(_cmd)];
//}

//- (void)decodeValueOfObjCType:(const char *)type at:(void *)data {
//    
//}
//
//- (NSData *)decodeDataObject {
//    return nil;
//}

- (NSInteger)versionForClassName:(NSString *)className {
    return 0;
}

- (BOOL)allowsKeyedCoding {
    return YES;
}




@end
