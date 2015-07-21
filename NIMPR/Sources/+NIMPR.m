//
//  NIMPRAdditions.m
//  NIMPR
//
//  Created by Alessandro Volz on 5/27/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "+NIMPR.h"
#include <execinfo.h>

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

//@implementation NSDictionary (NIMPRAdditions)
//
//- (id)valueForKeyPath:(NSString*)keyPath {
//    NSRange r = [keyPath rangeOfString:@"."];
//    if (r.location != NSNotFound)
//        return [[self valueForKey:[keyPath substringToIndex:r.location]] valueForKeyPath:[keyPath substringFromIndex:r.location+r.length]];
//    else return [self valueForKey:keyPath];
//}
//
//@end
//
//@implementation NSMutableDictionary (NIMPRAdditions)
//
//- (void)setValue:(id)value forKeyPath:(NSString*)keyPath {
//    NSRange r = [keyPath rangeOfString:@"."];
//    if (r.location != NSNotFound)
//        [[self valueForKey:[keyPath substringToIndex:r.location]] setValue:value forKeyPath:[keyPath substringFromIndex:r.location+r.length]];
//    else [self setValue:value forKey:keyPath];
//}
//
//@end

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

CGFloat NIMPR_CGFloatMax(CGFloat lha, CGFloat rha) {
    return lha > rha ? lha : rha;
}

CGFloat NIMPR_CGFloatMin(CGFloat lha, CGFloat rha) {
    return lha < rha ? lha : rha;
}

CGFloat NIMPR_CGFloatAbs(CGFloat f) {
    return f >= 0 ? f : -f;
}

CGFloat NIMPR_CGFloatSign(CGFloat f) {
    return f >= 0 ? 1 : -1;
}
