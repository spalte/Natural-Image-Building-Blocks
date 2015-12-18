//
//  Macros.h
//  NIBuildingBlocks
//
//  Created by Alessandro Volz on 17/12/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#ifndef NIMPR_Macros_h
#define NIMPR_Macros_h

#if __has_feature(nullability)
#   define __ASSUME_NONNULL_BEGIN      NS_ASSUME_NONNULL_BEGIN
#   define __ASSUME_NONNULL_END        NS_ASSUME_NONNULL_END
#   define __NULLABLE                  nullable
#else
#   define __ASSUME_NONNULL_BEGIN
#   define __ASSUME_NONNULL_END
#   define __NULLABLE
#endif

#if __has_feature(objc_generics)
#   define __GENERIC(class, ...)                class<__VA_ARGS__>
#   define __GENERIC_TYPE(type)                 type
#   define __GENERIC_CAST(type, expression)     expression
#   define __KINDOF(type)                       __kindof type
#else
#   define __GENERIC(class, ...)                class
#   define __GENERIC_TYPE(type)                 id
#   define __GENERIC_CAST(type, expression)     ((type)expression)
#   define __KINDOF(type)                       id
#endif

#endif
