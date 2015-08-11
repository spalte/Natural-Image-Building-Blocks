//
//  NIMPRAdditions.m
//  NIMPR
//
//  Created by Alessandro Volz on 5/27/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NSObject+NI.h"
#include <execinfo.h>

@implementation NIObject

@synthesize deallocBlock = _deallocBlock;

+ (instancetype)dealloc:(void (^)())deallocBlock {
    NIObject* r = [[[self.class alloc] init] autorelease];
    r.deallocBlock = deallocBlock;
    return r;
}

- (void)dealloc {
    if (self.deallocBlock)
        self.deallocBlock();
    self.deallocBlock = nil;
    [super dealloc];
}

@end

@interface NIKeyValueObserver : NSObject {
    id _object;
    NSString* _keyPath;
    void (^_block)(NSDictionary*);
}

@property(assign) id object;
@property(retain) NSString* keyPath;
@property(copy) void (^block)(NSDictionary*);

@end

@implementation NIKeyValueObserver

@synthesize object = _object;
@synthesize keyPath = _keyPath;
@synthesize block = _block;

- (id)initWithObject:(id)object keyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options block:(void (^)(NSDictionary*))block {
    if ((self = [super init])) {
        self.object = object;
        self.keyPath = keyPath;
        self.block = block;
        [object addObserver:self forKeyPath:keyPath options:options context:self];
    }
        
    return self;
}

- (void)dealloc {
    [self.object removeObserver:self forKeyPath:self.keyPath context:self];
    self.keyPath = nil;
    self.block = nil;
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    self.block(change);
}

@end

@interface NINotificationObserver : NSObject {
    id _object;
    NSString* _name;
    void (^_block)(NSNotification*);
}

@property(assign) id object;
@property(retain) NSString* name;
@property(copy) void (^block)(NSNotification*);

@end

@implementation NINotificationObserver

@synthesize object = _object, name = _name, block = _block;

- (id)initWithObject:(id)object name:(NSString*)name options:(NINotificationObservingOptions)options block:(void (^)(NSNotification*))block {
    if ((self = [super init])) {
        self.object = object;
        self.name = name;
        self.block = block;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_observeNotification:) name:name object:object];
        
        @try {
            if (options&NINotificationObservingOptionInitial)
                block(nil);
        } @catch (...) {
        }
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:self.name object:self.object];
    self.name = nil;
    self.block = nil;
    [super dealloc];
}

- (void)_observeNotification:(NSNotification*)notification {
    self.block(notification);
}

@end

@implementation NSObject (NIMPR)

- (id)if:(Class)class {
    if (![self isKindOfClass:class])
        return nil;
    return self;
}

- (id)performSelector:(SEL)sel withObjects:(id)obj1 :(id)obj2 {
    NSMethodSignature* signature = [self methodSignatureForSelector:sel];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.selector = sel;
    if (obj1) [invocation setArgument:&obj1 atIndex:2];
    if (obj2) [invocation setArgument:&obj2 atIndex:3];
    
    [invocation invokeWithTarget:self];
    
    id rv = nil;
    NSUInteger rs = [signature methodReturnLength];
    if (rs > 0) {
        NSMutableData* rb = [NSMutableData dataWithLength:rs];
        [invocation getReturnValue:rb.mutableBytes];
        rv = [NSObject valueWithBytes:rb.bytes objCType:signature.methodReturnType];
    }
    
    return rv;
}

- (id)performSelector:(SEL)sel withObjects:(id)obj1 :(id)obj2 :(id)obj3 {
    NSMethodSignature* signature = [self methodSignatureForSelector:sel];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.selector = sel;
    if (obj1) [invocation setArgument:&obj1 atIndex:2];
    if (obj2) [invocation setArgument:&obj2 atIndex:3];
    if (obj3) [invocation setArgument:&obj3 atIndex:4];
    
    [invocation invokeWithTarget:self];
    
    id rv = nil;
    NSUInteger rs = [signature methodReturnLength];
    if (rs > 0) {
        NSMutableData* rb = [NSMutableData dataWithLength:rs];
        [invocation getReturnValue:rb.mutableBytes];
        rv = [NSObject valueWithBytes:rb.bytes objCType:signature.methodReturnType];
    }
    
    return rv;
}

- (void)performBlock:(void (^)())block afterDelay:(NSTimeInterval)delay {
    [self performSelector:@selector(_performBlock:) withObject:[block copy] afterDelay:delay];
}

- (void)_performBlock:(void (^)())block {
    block();
    [block release];
}

- (id)observeKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options block:(void (^)(NSDictionary*))block {
    return [[[NIKeyValueObserver alloc] initWithObject:self keyPath:keyPath options:options block:block] autorelease];
}

- (id)observeKeyPaths:(NSArray*)keyPaths options:(NSKeyValueObservingOptions)options block:(void (^)(NSDictionary*))block {
    NSMutableArray* r = [NSMutableArray array];
    for (NSString* keyPath in keyPaths)
        [r addObject:[self observeKeyPath:keyPath options:options block:block]];
    return r;
}

- (id)observeNotification:(NSString*)name block:(void (^)(NSNotification* notification))block {
    return [self observeNotification:name options:0 block:block];
}

- (id)observeNotification:(NSString*)name options:(NINotificationObservingOptions)options block:(void (^)(NSNotification* notification))block {
    return [[[NINotificationObserver alloc] initWithObject:self name:name options:options block:block] autorelease];
}

- (id)observeNotifications:(NSArray*)names options:(NINotificationObservingOptions)options block:(void (^)(NSNotification* notification))block {
    NSMutableArray* r = [NSMutableArray array];
    for (NSString* name in names)
        [r addObject:[self observeNotification:name options:options block:block]];
    return r;
}

+ (id)valueWithBytes:(const void*)bytes objCType:(const char*)type {
    if (strlen(type) == 1)
        switch (type[0]) {
            case '@':
                return *(id*)bytes;
            case 'c':
                return [NSNumber numberWithChar:*(char*)bytes];
            case 'i':
                return [NSNumber numberWithInt:*(int*)bytes];
            case 's':
                return [NSNumber numberWithShort:*(short*)bytes];
            case 'l':
                return [NSNumber numberWithLong:*(long*)bytes];
            case 'q':
                return [NSNumber numberWithLongLong:*(long long*)bytes];
            case 'C':
                return [NSNumber numberWithUnsignedChar:*(unsigned char*)bytes];
            case 'I':
                return [NSNumber numberWithUnsignedInt:*(unsigned int*)bytes];
            case 'S':
                return [NSNumber numberWithUnsignedShort:*(unsigned short*)bytes];
            case 'L':
                return [NSNumber numberWithUnsignedLong:*(unsigned long*)bytes];
            case 'Q':
                return [NSNumber numberWithUnsignedLongLong:*(unsigned long long*)bytes];
            case 'f':
                return [NSNumber numberWithFloat:*(float*)bytes];
            case 'd':
                return [NSNumber numberWithDouble:*(double*)bytes];
            case 'B':
                return [NSNumber numberWithBool:*(bool*)bytes];
            case 'v':
                return nil;
            case '*':
                return [NSString stringWithCString:*(char**)bytes encoding:NSUTF8StringEncoding];
        }
    
    return [NSValue valueWithBytes:bytes objCType:type];
}

- (NSUInteger)count {
    return 0;
}

@end

@implementation NSNull (NIMPR)

+ (id)either:(id)obj {
    if (obj)
        return obj;
    return [NSNull null];
}

@end

@implementation NSDictionary (NIMPR)

- (NSDictionary*)dictionaryByAddingObject:(id)obj forKey:(id)key {
    NSMutableDictionary* r = [NSMutableDictionary dictionaryWithDictionary:self];
    r[key] = obj;
    return r;
}

//
//- (id)valueForKeyPath:(NSString*)keyPath {
//    NSRange r = [keyPath rangeOfString:@"."];
//    if (r.location != NSNotFound)
//        return [[self valueForKey:[keyPath substringToIndex:r.location]] valueForKeyPath:[keyPath substringFromIndex:r.location+r.length]];
//    else return [self valueForKey:keyPath];
//}
//
@end

@implementation NSMutableDictionary (NIMPR)

- (void)set:(NSDictionary*)set {
    for (id key in self.allKeys)
        if (!set[key])
            [self removeObjectForKey:key];
    for (id key in set)
        self[key] = set[key];
}

//- (void)setValue:(id)value forKeyPath:(NSString*)keyPath {
//    NSRange r = [keyPath rangeOfString:@"."];
//    if (r.location != NSNotFound)
//        [[self valueForKey:[keyPath substringToIndex:r.location]] setValue:value forKeyPath:[keyPath substringFromIndex:r.location+r.length]];
//    else [self setValue:value forKey:keyPath];
//}

@end

@implementation NSWindow (NIMPR)

- (NSPoint)convertPointToScreen:(NSPoint)point {
    return [self convertRectToScreen:NSMakeRect(point.x, point.y, 0, 0)].origin;
}

- (NSPoint)convertPointFromScreen:(NSPoint)point {
    return [self convertRectFromScreen:NSMakeRect(point.x, point.y, 0, 0)].origin;
}

@end

@implementation NSException (NIMPR)

- (NSString*)stackTrace {
    NSMutableString* stackTrace = [NSMutableString string];
    
    @try {
        NSArray* addresses = [self callStackReturnAddresses];
        if (addresses.count) {
            void* backtrace_frames[addresses.count];
            for (NSInteger i = (long)addresses.count-1; i >= 0; --i)
                backtrace_frames[i] = (void *)[[addresses objectAtIndex:i] unsignedLongValue];
            
            char** frameStrings = backtrace_symbols(backtrace_frames, (int)addresses.count);
            if (frameStrings) {
                for (int x = 0; x < addresses.count; ++x) {
                    if (x) [stackTrace appendString:@"\r"];
                    [stackTrace appendString:[NSString stringWithUTF8String:frameStrings[x]]];
                }
                free(frameStrings);
            }
        }
    } @catch (NSException* e)  {
        NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
    }
    
    return stackTrace;	
}

- (void)log {
    NSLog(@"%@", [self stackTrace]);
}

@end

@implementation NSSet (NIMPR)

- (NSSet*)setByAddingObjects:(id)obj, ... {
    NSMutableSet* r = [[self mutableCopy] autorelease];
    
    va_list args;
    va_start(args, obj);
    for (id arg = obj; arg != nil; arg = va_arg(args, id))
        [r addObject:arg];
    va_end(args);
    
    return r;
}

@end

@implementation NSMutableSet (NIMPR)

- (void)set:(id)set {
    if (!set)
        set = [NSSet set];
    if ([set isKindOfClass:NSArray.class])
        set = [NSSet setWithArray:set];
    if (![set isKindOfClass:NSSet.class])
        set = [NSSet setWithObject:set];
    [self intersectSet:set];
    [self unionSet:set];
}

@end

@implementation NSEvent (NIMPR)

- (NSPoint)locationInView:(NSView*)view {
    switch (self.type) {
        case NSLeftMouseDown:
        case NSLeftMouseUp:
        case NSRightMouseDown:
        case NSRightMouseUp:
        case NSMouseMoved:
        case NSLeftMouseDragged:
        case NSRightMouseDragged:
        case NSMouseEntered:
        case NSMouseExited:
        case NSOtherMouseDown:
        case NSOtherMouseUp:
        case NSOtherMouseDragged:
        case NSCursorUpdate:
        case NSScrollWheel:
        case NSTabletPoint:
        case NSTabletProximity: {
            NSPoint location = self.locationInWindow;
            
            if (self.window != view.window)
                location = [view.window convertPointFromScreen:[self.window convertPointToScreen:location]];
            
            return [view convertPoint:location fromView:nil];
        } break;
        default: {
        } break;
    }
    
    return [view convertPoint:[view.window convertPointFromScreen:[NSEvent mouseLocation]] fromView:nil];
}

@end

//@implementation NIOperation
//
//@synthesize object = _object;
//
//+ (instancetype)operationWithObject:(id)object block:(void (^)())block {
//    return [[[self.class alloc] initWithObject:object block:block] autorelease];
//}
//
//- (id)initWithObject:(id)object block:(void (^)())block {
//    if ((self = [super init])) {
//        self.object = object;
//        [self addExecutionBlock:block];
//    }
//    
//    return self;
//}
//
//- (void)dealloc {
//    self.object = nil;
//    [super dealloc];
//}
//
//@end

CGFloat NIMPR_CGFloatAbs(CGFloat f) {
    return f >= 0 ? f : -f;
}

CGFloat NIMPR_CGFloatSign(CGFloat f) {
    return f >= 0 ? 1 : -1;
}
