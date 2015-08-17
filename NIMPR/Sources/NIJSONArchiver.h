//
//  NIJSONCoder.h
//  NIMPR
//
//  Created by Alessandro Volz on 8/17/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NIJSONArchiver : NSKeyedArchiver <NSKeyedArchiverDelegate> {
    NSMutableString* _json;
    NSMutableData* _data;
    NSMutableArray* _stack;
    NSMutableDictionary *_replacements, *_dreplacements; // replacements by the class and by the delegate
    id<NSKeyedArchiverDelegate> _nidelegate;
}

+ (void)setClassName:(NSString *)codedName forClass:(Class)cls;

- (instancetype)initForWritingWithMutableString:(NSMutableString*)string;

@end

@interface NSObject (NIJSONArchiver)

- (id)replacementObjectForJSONArchiver:(NIJSONArchiver*)archiver;
- (NSString*)typeForJSONArchiver:(NIJSONArchiver*)archiver;

@end



//@protocol NICoding <NSObject>
//
//extern NSString* const NICodingClass;
//
//+ (NSDictionary*)objectForJSON;
//
//@end