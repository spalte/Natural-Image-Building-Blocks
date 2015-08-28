//
//  NIJSONCoder.h
//  NIMPR
//
//  Created by Alessandro Volz on 8/17/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NIJSONArchiver, NIJSONUnarchiver;

@interface NIJSON : NSObject

+ (void)setName:(NSString*)name forClass:(Class)cls;
+ (void)setName:(NSString*)name forClass:(Class)cls encoder:(void (^)(NIJSONArchiver* archiver, id obj))encoder decoder:(id (^)(NIJSONUnarchiver* unarchiver))decoder;
+ (id)recordForClass:(Class)c;

+ (void)setName:(NSString*)name forValueObjCType:(const char*)objcType encoder:(void (^)(NIJSONArchiver* archiver, NSValue* val))encoder decoder:(NSValue* (^)(NIJSONUnarchiver* unarchiver))decoder;

@end

@protocol NIJSONArchiverDelegate, NIJSONUnarchiverDelegate;

@interface NIJSONArchiver : NSCoder {
    NSMutableString* _json;
    NSMutableArray* _stack;
    NSMutableDictionary *_replacements;
    id<NIJSONArchiverDelegate> _delegate;
}

@property(assign) id<NIJSONArchiverDelegate> delegate;

- (instancetype)initForWritingWithMutableString:(NSMutableString*)string;

- (void)finishEncoding;

- (void)encodeCGFloat:(CGFloat)cgf forKey:(NSString*)key;

- (void)encodeValueOfObjCType:(const char *)type at:(const void *)addr __deprecated; // pass the NSValue directly to encodeObject

@end

@protocol NIJSONArchiverDelegate <NSObject> // inspired by NSKeyedArchiverDelegate
@optional

- (id)archiver:(NIJSONArchiver *)archiver willEncodeObject:(id)object;
- (void)archiver:(NIJSONArchiver *)archiver didEncodeObject:(id)object;
- (void)archiver:(NIJSONArchiver *)archiver willReplaceObject:(id)object withObject:(id)newObject;
- (void)archiverWillFinish:(NIJSONArchiver *)archiver;
- (void)archiverDidFinish:(NIJSONArchiver *)archiver;

@end

@interface NIJSONUnarchiver : NSCoder {
    NSDictionary *_json;
    NSMutableArray* _stack;
    id<NIJSONUnarchiverDelegate> _delegate;
}

@property(assign) id<NIJSONUnarchiverDelegate> delegate;

- (instancetype)initForReadingWithString:(NSString *)string;
- (instancetype)initForReadingWithData:(NSData*)data NS_DESIGNATED_INITIALIZER;

- (NSNumber*)decodeNumberForKey:(NSString *)key;
- (CGFloat)decodeCGFloatForKey:(NSString*)key;

@end

@protocol NIJSONUnarchiverDelegate <NSObject>
@optional

@end

