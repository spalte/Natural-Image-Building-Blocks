//
//  NIMPRAdditions.h
//  NIMPR
//
//  Created by Alessandro Volz on 5/27/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (NIMPR)

- (id)if:(Class)c;
- (id)performSelector:(SEL)sel withObjects:(id)obj1 :(id)obj2;
- (id)performSelector:(SEL)sel withObjects:(id)obj1 :(id)obj2 :(id)obj3;

- (void)performBlock:(void (^)())block afterDelay:(NSTimeInterval)delay;

@end

@interface NSNull (NIMPR)

+ (id)either:(id)obj;

@end

//@interface NSDictionary (NIMPRAdditions)
//
//@end
//
//@interface NSMutableDictionary (NIMPRAdditions)
//
//@end

@interface NSWindow (NIMPR)

- (NSPoint)convertPointToScreen:(NSPoint)point;
- (NSPoint)convertPointFromScreen:(NSPoint)point;

@end

@interface NSException (NIMPR)

- (void)log;

@end

@interface NSSet (NIMPR)

- (NSSet*)setByAddingObjects:(id)obj, ... NS_REQUIRES_NIL_TERMINATION;

@end

@interface NSMutableSet (NIMPR)

- (void)set:(id)set; // an object or a NSSet of objects

@end

@interface NSEvent (NIMPR)

- (NSPoint)locationInView:(NSView*)view;

@end

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
