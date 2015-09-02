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
#import "NSData+zlib.h"
#import "NIAnnotation.h"

//static NSString* const NIJSONClass = @"class";
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
    [self setName:@"rect" forValueObjCType:@encode(NSRect)
          encoder:^(NIJSONArchiver *archiver, NSValue *val) {
              NSRect rect = val.rectValue;
              [archiver encodeObject:@[ @(rect.origin.x), @(rect.origin.y), @(rect.size.width), @(rect.size.height) ] forKey:@"xywh"];
          }
          decoder:^NSValue *(NIJSONUnarchiver *unarchiver) {
              NSArray* values = [unarchiver decodeObjectForKey:@"xywh"];
              return [NSValue valueWithRect:NSMakeRect([values[0] CGFloatValue], [values[1] CGFloatValue], [values[2] CGFloatValue], [values[3] CGFloatValue])];
          }];
    
    [self setName:@"vector" forValueObjCType:@encode(NIVector)
          encoder:^(NIJSONArchiver *archiver, NSValue *val) {
              NIVector vect = val.NIVectorValue;
              [archiver encodeObject:(vect.z? @[ @(vect.x), @(vect.y), @(vect.z) ] : @[ @(vect.x), @(vect.y) ]) forKey:@"components"];
          }
          decoder:^NSValue *(NIJSONUnarchiver *unarchiver) {
              NSArray* values = [unarchiver decodeObjectForKey:@"components"];
              return [NSValue valueWithNIVector:NIVectorMake([values[0] CGFloatValue], [values[1] CGFloatValue], [[values objectAtIndex:2 or:@0] CGFloatValue])];
          }];
    
    [self setName:@"transform" forValueObjCType:@encode(NIAffineTransform)
          encoder:^(NIJSONArchiver *archiver, NSValue *val) {
              NIAffineTransform t = val.NIAffineTransformValue;
              [archiver encodeObject:@[ @(t.m11), @(t.m12), @(t.m13), @(t.m14), @(t.m21), @(t.m22), @(t.m23), @(t.m24), @(t.m31), @(t.m32), @(t.m33), @(t.m34), @(t.m41), @(t.m42), @(t.m43), @(t.m44) ] forKey:@"matrix"];
          }
          decoder:^NSValue *(NIJSONUnarchiver *unarchiver) {
              NSArray* values = [unarchiver decodeObjectForKey:@"matrix"];
              NIAffineTransform t = { [values[0] CGFloatValue], [values[1] CGFloatValue], [values[2] CGFloatValue], [values[3] CGFloatValue],
                  [values[4] CGFloatValue], [values[5] CGFloatValue], [values[6] CGFloatValue], [values[7] CGFloatValue],
                  [values[8] CGFloatValue], [values[9] CGFloatValue], [values[10] CGFloatValue], [values[11] CGFloatValue],
                  [values[12] CGFloatValue], [values[13] CGFloatValue], [values[14] CGFloatValue], [values[15] CGFloatValue] };
              return [NSValue valueWithNIAffineTransform:t];
          }];
    
    [self setName:@"data" forClass:NSData.class // TODO: zlib!
          encoder:^(NIJSONArchiver *archiver, NSData* obj) { // we could encode using base85, but that would make thigs harder for other people trying to read our blobs... so, base64
              NSData* odef = [obj zlibDeflate:NULL];
              if ([odef length] < .9*[obj length])
                  [archiver encodeObject:[[odef base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength|NSDataBase64EncodingEndLineWithLineFeed] stringByReplacingOccurrencesOfString:@"\n" withString:@" "] forKey:@"base64-gzip"];
              else [archiver encodeObject:[[obj base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength|NSDataBase64EncodingEndLineWithLineFeed] stringByReplacingOccurrencesOfString:@"\n" withString:@" "] forKey:@"base64"];
          }
          decoder:^id(NIJSONUnarchiver *unarchiver) {
              if ([unarchiver containsValueForKey:@"base64-gzip"])
                  return [[[[NSData alloc] initWithBase64EncodedString:[unarchiver decodeObjectForKey:@"base64-gzip"] options:NSDataBase64DecodingIgnoreUnknownCharacters] autorelease] zlibInflate:NULL];
              return [[[NSData alloc] initWithBase64EncodedString:[unarchiver decodeObjectForKey:@"base64"] options:NSDataBase64DecodingIgnoreUnknownCharacters] autorelease];
          }];
    
    static NSColorList* colorlist = nil;
    if (!colorlist) {
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
    }
    
    [self setName:@"color" forClass:NSColor.class
          encoder:^(NIJSONArchiver *archiver, NSColor *color) {
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
          }
          decoder:^NSColor *(NIJSONUnarchiver *unarchiver) {
              if ([unarchiver containsValueForKey:@"name"]) {
                  NSColor* color = [colorlist colorWithKey:[unarchiver decodeObjectForKey:@"name"]];
                  if ([unarchiver containsValueForKey:@"alpha"])
                      color = [color colorWithAlphaComponent:[unarchiver decodeCGFloatForKey:@"alpha"]];
                  return color;
              }
              
              NSArray* rgba = [unarchiver decodeObjectForKey:@"rgba"];
              return [NSColor colorWithCalibratedRed:[rgba[0] CGFloatValue] green:[rgba[1] CGFloatValue] blue:[rgba[2] CGFloatValue] alpha:[[rgba objectAtIndex:3 or:@1] CGFloatValue]];
          }];
    
    [self setName:@"mask" forClass:NIMask.class
          encoder:^(NIJSONArchiver *archiver, NIMask *mask) { // [ [ ([ widthLocation, widthLength ]|widthLocation), heightIndex, depthIndex ](, intensity) ] // if width range is specified as an integer, its length defaults to 1; intensity defaults to 1
              NSMutableArray* mras = [NSMutableArray array];
              for (NSValue* mrv in mask.maskRuns) {
                  NIMaskRun mr = mrv.NIMaskRunValue;
                  NSMutableArray* mra = [NSMutableArray array];
                  if (mr.widthRange.length != 1)
                      [mra addObject:@[ @(mr.widthRange.location), @(mr.widthRange.length) ]];
                  else [mra addObject:@(mr.widthRange.location)];
                  [mra addObjectsFromArray:@[ @(mr.heightIndex), @(mr.depthIndex) ]];
                  if (mr.intensity != 1)
                      [mra addObject:@(mr.intensity)];
                  [mras addObject:mra];
              }
              [archiver encodeObject:mras forKey:@"runs"];
          }
          decoder:^NIMask *(NIJSONUnarchiver *unarchiver) {
              id obj = [[unarchiver decodeObjectForKey:@"runs"] requireArrayOfInstancesOfClass:NSArray.class];
              NSMutableArray* mrs = [NSMutableArray array];
              for (NSArray* mra in obj) {
                  NIMaskRun mr;
                  if ([mra[0] isKindOfClass:NSArray.class]) {
                      mr.widthRange.location = [[mra[0][0] requireKindOfClass:NSNumber.class] CGFloatValue];
                      if ([mra[0] count] > 1)
                          mr.widthRange.length = [[mra[0][1] requireKindOfClass:NSNumber.class] CGFloatValue];
                      else mr.widthRange.length = 1;
                  } else mr.widthRange = NSMakeRange([[mra[0] requireKindOfClass:NSNumber.class] CGFloatValue], 1);
                  mr.heightIndex = [[mra[1] requireKindOfClass:NSNumber.class] CGFloatValue];
                  mr.depthIndex = [[mra[2] requireKindOfClass:NSNumber.class] CGFloatValue];
                  if ([mra count] > 3)
                      mr.intensity = [[mra[3] requireKindOfClass:NSNumber.class] CGFloatValue];
                  else mr.intensity = 1;
                  [mrs addObject:[NSValue valueWithNIMaskRun:mr]];
              }
              return [[[NIMask alloc] initWithMaskRuns:mrs] autorelease];
          }];
}

+ (NSMutableArray*)records {
    static NSMutableArray* records = nil;
    if (!records)
        records = [[NSMutableArray alloc] init];
    return records;
}

+ (void)setName:(NSString *)name forClass:(Class)cls {
    [self.class setName:name forClass:cls encoder:nil decoder:nil];
}

+ (void)setName:(NSString *)name forClass:(Class)cls encoder:(void (^)(NIJSONArchiver *, id))encoder decoder:(id (^)(NIJSONUnarchiver *))decoder {
    _NIJSONRecord* rec = [[self.records filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", name]] lastObject];
    if (rec)
        NSLog(@"Warning: registering class type %@ with name %@, already registered with %@", NSStringFromClass(cls), name, rec.type);
    [self.records addObject:[_NIJSONRecord recordWithName:name type:cls encoder:encoder decoder:decoder]];
}

+ (_NIJSONRecord*)_recordForClass:(Class)c {
    NSMutableArray* recScores = [NSMutableArray array];
    for (_NIJSONRecord* rec in self.records)
        if (![rec.type isKindOfClass:NSString.class]) {
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

+ (void)setName:(NSString*)name forValueObjCType:(const char*)objcType encoder:(void (^)(NIJSONArchiver* archiver, NSValue* val))encoder decoder:(NSValue* (^)(NIJSONUnarchiver* unarchiver))decoder {
    _NIJSONRecord* rec = [[self.records filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", name]] lastObject];
    if (rec)
        NSLog(@"Warning: registering obj-c type %s with name %@, already registered with %@", objcType, name, rec.type);
    [self.records addObject:[_NIJSONRecord recordWithName:name type:@(objcType) encoder:encoder decoder:decoder]];
}

+ (_NIJSONRecord*)_recordForValueObjCType:(const char*)objcType {
    return [[self.records filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", @(objcType)]] lastObject];
}

+ (_NIJSONRecord*)_recordForName:(NSString*)name {
    NSArray* recs = [self.records filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", name]];
    if (recs.count > 1)
        NSLog(@"Warning: %lu records with name %@, undefined behaviour", (unsigned long)recs.count, name);
    return recs.lastObject;
}

+ (id)recordForClass:(Class)c {
    return [self.class _recordForClass:c];
}

NSString* const NIJSONAnnotationsFileType = @"ojas";
NSString* const NIJSONDeflatedAnnotationsFileType = @"ojaz";

+ (NSArray*)fileTypes:(NSDictionary**)descriptions {
    if (descriptions)
        *descriptions = @{ NIJSONAnnotationsFileType: NSLocalizedString(@"OJAS: Open JSON Annotations format", nil),
                           NIJSONDeflatedAnnotationsFileType: NSLocalizedString(@"OJAZ: Deflated Open JSON Annotations", nil) };
    return @[ NIJSONAnnotationsFileType, NIJSONDeflatedAnnotationsFileType ];
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

+ (NSString*)archivedStringWithRootObject:(id)obj {
    NSMutableString* ms = [NSMutableString string];
    NIJSONArchiver* archiver = [[[self.class alloc] initForWritingWithMutableString:ms] autorelease];
    [archiver encodeObject:obj];
    return ms;
}

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

- (NSSet*)allowedClasses {
    return [[NSSet setWithObjects: NSNull.class, NSString.class, NSNumber.class, NSValue.class, NSArray.class, NSDictionary.class, nil] setByAddingObjectsFromArray:[[NIJSON.records valueForKey:@"type"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"class = %@", NSString.class]]];
}

- (void)encodeObject:(id)obj {
    return [self encodeObject:obj commas:(self.stack.count > 0)];
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
        if ([objr ifn:NSNull.class] != obj)
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
        else {
            NSString* objd = [obj description];
            if ([objd isEqualToString:@"-0"])
                objd = @"0";
            [self.json appendString:objd];
        }
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
        for (id sobj in obj)
            [self encodeObject:sobj];
        [self.stack removeLastObject];
        [self.json appendString:@" ]"];
    }
    else if ([obj isKindOfClass:NSDictionary.class]) {
        [self.json appendString:@"{ "];
        [self.stack addObject:@0];
        for (NSString* key in obj)
            [self encodeObject:obj[key] forKey:key];
        [self.stack removeLastObject];
        [self.json appendString:@" }"];
    }
    else if ((rec = [NIJSON _recordForClass:[obj class]])) {
        [self.json appendString:@"{ "];
        [self.stack addObject:@0];
        [self encodeObject:rec.name forKey:NIJSONType];
        if (rec.encoder)
            rec.encoder(self, obj);
        else [obj encodeWithCoder:self];
        [self.stack removeLastObject];
        [self.json appendString:@" }"];
    }
    else [NSException raise:NSInvalidArchiveOperationException format:@"Class %@ is not supported by %@", [obj className], self.className];
    
    [self _archiver_didEncodeObject:obj];
}

- (void)finishEncoding {
    [self _archiverWillFinish];
    
    while (self.stack.count) {
        [self.stack removeLastObject];
        [self.json appendString:@" }"];
    }
    
    [self _archiverDidFinish];
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

//- (void)encodeConditionalObject:(id)objv forKey:(NSString *)key {
//    [NSException raise:NSInvalidArchiveOperationException format:@"Unsupported API: -[%@ %@]", self.className, NSStringFromSelector(_cmd)];
//}

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

- (void)encodeInteger:(NSInteger)intv forKey:(NSString *)key {
    [self encodeObject:@(intv) forKey:key];
}

- (BOOL)allowsKeyedCoding {
    return YES;
}

- (void)encodeValueOfObjCType:(const char *)type at:(const void *)addr { // deprecated
    [self encodeObject:[NSValue valueWithBytes:addr objCType:type]];
}

- (void)encodeDataObject:(NSData*)data {
    [self encodeObject:data];
}

- (NSInteger)versionForClassName:(NSString*)className {
    return 0;
}

// calling the delegate....

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

@end

@interface NIJSONUnarchiver ()

@property(retain) NSDictionary* json;
@property(retain) NSMutableArray* stack;

@end

@implementation NIJSONUnarchiver // NSKeyedUnarchiver

@synthesize json = _json;
@synthesize stack = _stack;
@synthesize delegate = _delegate;

+ (id)unarchiveObjectWithString:(NSString*)string {
    NIJSONUnarchiver* unarchiver = [[[self.class alloc] initForReadingWithString:string] autorelease];
    return [unarchiver decodeObject:unarchiver.stack[0]];
}

- (instancetype)initForReadingWithString:(NSString *)string {
    return [self initForReadingWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (instancetype)initForReadingWithData:(NSData*)data {
    if ((self = [super init])) {
        NSError* err = nil;
        self.stack = [NSMutableArray array];
        self.json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        if (!self.json)
            [NSException raise:NSInvalidUnarchiveOperationException format:@"NSJSONSerialization error: %@", err.localizedDescription];
        [self.stack addObject:self.json];
    }
    
    return self;
}

- (void)dealloc {
    self.json = nil;
    [super dealloc];
}

- (id)decodeObject:(id)obj {
    if (!obj)
        return nil;
    
    const NSUInteger oidx = self.stack.count;
    [self.stack addObject:obj];
    @try {
        _NIJSONRecord* rec = nil;
        
        if ([obj isKindOfClass:NSNull.class]) {
            return nil;
        }
        else if ([obj isKindOfClass:NSString.class]) {
            return obj;
        }
        else if ([obj isKindOfClass:NSNumber.class]) {
            return obj;
        }
        else if ([obj isKindOfClass:NSArray.class]) {
            NSMutableArray* r = [NSMutableArray array];
            for (id sobj in obj)
                [r addObject:[self decodeObject:sobj]];
            return r;
        }
        else if ([obj isKindOfClass:NSDictionary.class]) { // JSON objects are used to encode classes, structs and generic dictionaries
            // is this an obj-c object, a struct?
            if ((rec = [NIJSON _recordForName:obj[NIJSONType]])) {
                if (rec.decoder)
                    return rec.decoder(self);
                return [[[rec.type alloc] initWithCoder:self] autorelease];
            }
            // no, this is just a dictionary
            NSMutableDictionary* r = [NSMutableDictionary dictionary];
            for (NSString* key in obj)
                r[key] = [self decodeObject:obj[key]];
            return r;
        }
        
    } @catch (...) {
        @throw;
    } @finally {
        if (oidx != self.stack.count-1)
            NSLog(@"Warning: unbalanced unarchiver stack");
        [self.stack removeObjectsInRange:NSMakeRange(oidx, self.stack.count-oidx)];
    }
        
    [NSException raise:NSInvalidUnarchiveOperationException format:@"Unexpected object class in JSON: %@", [obj className]];
    return nil;
}

- (id)decodeObjectForKey:(NSString*)key {
    return [self decodeObject:[self.stack.lastObject objectForKey:key]];
}

- (BOOL)containsValueForKey:(NSString*)key {
    return ([self.stack.lastObject objectForKey:key] != nil);
}

- (NSNumber*)decodeNumberForKey:(NSString *)key {
    NSNumber* n = [self decodeObjectForKey:key];
    if (n && ![n isKindOfClass:NSNumber.class])
        [NSException raise:NSInvalidUnarchiveOperationException format:@"Value for key %@ is of class %@, can't be decoded as a number", key, n.className];
    return n;
}

- (BOOL)decodeBoolForKey:(NSString *)key {
    return [[self decodeNumberForKey:key] boolValue];
}

- (int)decodeIntForKey:(NSString *)key {
    return [[self decodeNumberForKey:key] intValue];
}

- (int32_t)decodeInt32ForKey:(NSString *)key {
    return [[self decodeNumberForKey:key] intValue];
}

- (int64_t)decodeInt64ForKey:(NSString *)key {
    return [[self decodeNumberForKey:key] longLongValue];
}

- (float)decodeFloatForKey:(NSString *)key {
    return [[self decodeNumberForKey:key] floatValue];
}

- (double)decodeDoubleForKey:(NSString *)key {
    return [[self decodeNumberForKey:key] doubleValue];
}

- (CGFloat)decodeCGFloatForKey:(NSString*)key {
#if CGFLOAT_IS_DOUBLE
    return [self decodeDoubleForKey:key];
#else
    return [self decodeFloatForKey:key];
#endif
}

- (const uint8_t *)decodeBytesForKey:(NSString *)key returnedLength:(NSUInteger *)lengthp NS_RETURNS_INNER_POINTER {
    
    return nil;
}

- (NSInteger)decodeIntegerForKey:(NSString *)key {
    
    return 0;
}

- (id)decodeObjectOfClass:(Class)aClass forKey:(NSString *)key {
    
    return nil;
}

- (id)decodeObjectOfClasses:(NSSet *)classes forKey:(NSString *)key {
    
    return nil;
}


@end
