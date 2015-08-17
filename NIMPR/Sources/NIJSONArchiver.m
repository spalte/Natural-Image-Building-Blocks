//
//  NIJSONCoder.m
//  NIMPR
//
//  Created by Alessandro Volz on 8/17/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIJSONArchiver.h"
#import <objc/runtime.h>

NSString* const NICodingClass = @"class";

@interface NIJSONArchiver ()

@property(retain) NSMutableString* json;
@property(retain) NSMutableArray* stack;
@property(retain) NSMutableDictionary *replacements, *dreplacements;
@property(assign) id<NSKeyedArchiverDelegate> nidelegate;

@end

@implementation NIJSONArchiver

@synthesize json = _json, stack = _stack, replacements = _replacements, dreplacements = _dreplacements;
@synthesize nidelegate = _nidelegate;

- (instancetype)initForWritingWithMutableString:(NSMutableString*)string {
    if ((self = [super initForWritingWithMutableData:[NSMutableData data]])) {
        self.json = string;
        self.stack = [NSMutableArray arrayWithObject:@0];
        self.replacements = [NSMutableDictionary dictionary];
        super.delegate = self;
    }
    
    return self;
}

- (void)dealloc {
    self.replacements = self.dreplacements = nil;
    self.stack = nil;
    self.json = nil;
    [super dealloc];
}

- (void)setDelegate:(id<NSKeyedArchiverDelegate>)delegate {
    self.nidelegate = delegate;
}

- (id<NSKeyedArchiverDelegate>)delegate {
    return self.nidelegate;
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
    if (!objr)
        objr = self.replacements[objrk] = [NSNull either:[obj replacementObjectForJSONArchiver:self]];
    obj = [objr ifn:NSNull.class];
    
    if (obj) {
        objr = self.dreplacements[objrk];
        if (!objr)
            objr = self.dreplacements[objrk] = [NSNull either:[super.delegate archiver:self willEncodeObject:obj]];
        obj = [objr ifn:NSNull.class];
    }
    
    if (!obj) {
        [self.json appendString:@"null"];
    } else if ([obj isKindOfClass:NSString.class]) {
        [self.json appendFormat:@"\"%@\"", [[obj stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
    } else if ([obj isKindOfClass:NSNumber.class]) {
        [self.json appendFormat:@"%@", obj];
    } else if ([obj isKindOfClass:NSArray.class]) {
        [self.json appendString:@"[ "];
        [self.stack addObject:@0];
        [obj enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
            [self encodeObject:obj];
        }];
        [self.stack removeLastObject];
        [self.json appendString:@" ]"];
    } else if ([obj isKindOfClass:NSDictionary.class]) {
        [self.json appendString:@"{ "];
        [self.stack addObject:@0];
        [obj enumerateKeysAndObjectsUsingBlock:^(NSString* key, id obj, BOOL* stop) {
            [self encodeObject:key forKey:key];
        }];
        [self.stack removeLastObject];
        [self.json appendString:@" }"];
    } else if ((objr = [self.class registeredStorageClassForClass:[obj class]])) {
        [self.json appendString:@"{ "];
        [self.stack addObject:@0];
        [self encodeObject:objr forKey:@"class"];
        [obj encodeWithCoder:self];
        [self.stack removeLastObject];
        [self.json appendString:@" }"];
    } else
        [NSException raise:NSInvalidArgumentException format:@"Class %@ is not supported by %@", [obj className], self.className];
    
    [super.delegate archiver:self didEncodeObject:obj];
}

- (void)encodeObject:(id)obj forKey:(NSString*)key {
    [self encodeObject:key];
    [self.json appendString:@": "];
    [self encodeObject:obj commas:NO];
}

static NSMutableDictionary* NIJSONStorageClasses = nil;

+ (void)setClassName:(NSString *)sc forClass:(Class)c {
    if (!NIJSONStorageClasses)
        NIJSONStorageClasses = [[NSMutableDictionary alloc] init];
    
    if (NIJSONStorageClasses[sc])
        NSLog(@"Warning: registering storage class %@ for class %@, already registered for class %@", sc, NSStringFromClass(c), NSStringFromClass(NIJSONStorageClasses[sc]));
    
    NIJSONStorageClasses[sc] = c;
}

+ (NSString*)classNameForClass:(Class)c {
    return [[NIJSONStorageClasses keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return (obj == c);
    }] anyObject];
}

- (id)archiver:(NSKeyedArchiver*)archiver willEncodeObject:(id)obj {
    if ([self.delegate respondsToSelector:@selector(archiver:willEncodeObject:)])
        obj = [self.delegate archiver:archiver willEncodeObject:obj];
    return obj;
}

- (void)archiver:(NSKeyedArchiver *)archiver didEncodeObject:(id)obj {
    if ([self.delegate respondsToSelector:@selector(archiver:didEncodeObject:)])
        [self.delegate archiver:archiver didEncodeObject:obj];
}

- (void)archiver:(NSKeyedArchiver*)archiver willReplaceObject:(id)obj withObject:(id)nobj {
    if ([self.delegate respondsToSelector:@selector(archiver:willReplaceObject:withObject:)])
        [self.delegate archiver:archiver willReplaceObject:obj withObject:nobj];
}

- (void)archiverWillFinish:(NSKeyedArchiver*)archiver {
    if ([self.delegate respondsToSelector:@selector(archiverWillFinish:)])
        [self.delegate archiverWillFinish:archiver];
}

- (void)archiverDidFinish:(NSKeyedArchiver*)archiver {
    if ([self.delegate respondsToSelector:@selector(archiverDidFinish:)])
        [self.delegate archiverDidFinish:archiver];
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

@implementation NSObject (NIJSONArchiver)

- (id)replacementObjectForJSONArchiver:(NIJSONArchiver*)archiver {
    return [self replacementObjectForKeyedArchiver:archiver];
}

- (NSString*)typeForJSONArchiver:(NIJSONArchiver*)archiver {
    return nil;
}

@end
