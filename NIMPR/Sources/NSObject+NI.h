//
//  NIMPRAdditions.h
//  NIMPR
//
//  Created by Alessandro Volz on 5/27/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NIRetainer : NSObject {
    NSMutableDictionary* _retains;
}

- (void)retain:(id)obj;
- (void)retain:(id)obj forKey:(id)key;

@end

@interface NIObject : NSObject {
    void (^_deallocBlock)();
}

@property(copy) void (^deallocBlock)();

+ (instancetype)dealloc:(void (^)())deallocBlock;

@end


typedef NS_OPTIONS(NSUInteger, NINotificationObservingOptions) {
    NINotificationObservingOptionInitial = 0x01,
};

@interface NSObject (NIMPR)

+ (id)valueWithBytes:(const void*)bytes objCType:(const char*)type;

+ (id)either:(id)obj1 or:(id)obj2;
+ (id)either:(id)obj1 or:(id)obj2 or:obj3;

- (id)if:(Class)c;
- (id)ifn:(Class)c;
- (id)performSelector:(SEL)sel withObjects:(id)obj1 :(id)obj2;
- (id)performSelector:(SEL)sel withObjects:(id)obj1 :(id)obj2 :(id)obj3;

- (void)performBlock:(void (^)())block afterDelay:(NSTimeInterval)delay;

- (id)observeKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)opt block:(void (^)(NSDictionary* change))block; // retain the returned object until you want to stop observing
- (id)observeKeyPaths:(NSArray*)keyPaths options:(NSKeyValueObservingOptions)options block:(void (^)(NSDictionary*))block; // retain the returned object until you want to stop observing
- (id)observeNotification:(NSString*)name block:(void (^)(NSNotification* notification))block;
- (id)observeNotification:(NSString*)name options:(NINotificationObservingOptions)options block:(void (^)(NSNotification* notification))block; // retain the returned object until you want to stop observing
- (id)observeNotifications:(NSArray*)names options:(NINotificationObservingOptions)options block:(void (^)(NSNotification* notification))block; // retain the returned object until you want to stop observing

- (void)retain:(id)obj;
- (void)retain:(id)obj forKey:(id)key;
- (NIRetainer*)retainer;

@end

@interface NSNull (NIMPR)

+ (id)either:(id)obj;

@end

@interface NSDictionary (NIMPR)

- (NSDictionary*)dictionaryByAddingObject:(id)obj forKey:(id)key;

@end

@interface NSMutableDictionary (NIMPR)

- (void)set:(NSDictionary*)set;

@end

@interface NSWindow (NIMPR)

- (NSPoint)convertPointToScreen:(NSPoint)point;
- (NSPoint)convertPointFromScreen:(NSPoint)point;

@end

@interface NSException (NIMPR)

- (void)log;

@end

@interface NSSet (NIMPR)

- (NSSet*)setByAddingObjects: (id)obj, ... NS_REQUIRES_NIL_TERMINATION;

@end

@interface NSMutableSet (NIMPR)

- (void)set:(id)set; // an object or a NSSet of objects

@end

@interface NSEvent (NIMPR)

- (NSPoint)locationInView:(NSView*)view;

@end

//@interface NIOperation : NSBlockOperation {
//    id _object;
//}
//
//@property(retain) id object;
//
//+ (NIOperation*)operationWithObject:(id)object block:(void (^)())block;
//
//@end

#ifndef CGFloatMax
#if CGFLOAT_IS_DOUBLE
#define CGFloatMax fmax
#else
#define CGFloatMax fmaxf
#endif
#endif

#ifndef CGFloatMin
#if CGFLOAT_IS_DOUBLE
#define CGFloatMin fmin
#else
#define CGFloatMin fminf
#endif
#endif

#define CGFloatAbs NIMPR_CGFloatAbs
extern CGFloat NIMPR_CGFloatAbs(CGFloat f);
#define CGFloatSign NIMPR_CGFloatSign
extern CGFloat NIMPR_CGFloatSign(CGFloat f);

// from https://gist.github.com/Kentzo/1985919
#ifndef CGFLOAT_EPSILON
#if CGFLOAT_IS_DOUBLE
#define CGFLOAT_EPSILON DBL_EPSILON
#else
#define CGFLOAT_EPSILON FLT_EPSILON
#endif
#endif

#if CGFLOAT_IS_DOUBLE
#define valueWithCGFloat numberWithDouble
#define CGFloatValue doubleValue
#else
#define valueWithCGFloat numberWithFloat
#define CGFloatValue floatValue
#endif
