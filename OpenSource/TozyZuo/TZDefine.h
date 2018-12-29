//
//  TZDefine.h
//
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#ifndef ARTDefine_h
#define ARTDefine_h

NS_INLINE void TZInvokeBlockInMainThread(void (^block)(void))
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

//#define TZInvokeBlockInMainThread(...)\
//if ([NSThread isMainThread]) {\
//    (__VA_ARGS__)();\
//} else {\
//    dispatch_async(dispatch_get_main_queue(), ^{\
//        (__VA_ARGS__)();\
//    });\
//}

#define TZIgnoreWarning(...) TZIgnoreWarnings(__VA_ARGS__, 5, 4, 3, 2, 1)
#define TZIgnoreWarnings(_1, _2, _3, _4, _5, N, ...) _TZIgnoreWarnings(N, _1, _2, _3, _4, _5)
#define _TZIgnoreWarnings(count, args...) TZIgnoreWarning ## count(args)

#define TZIgnoreWarningEnd _Pragma("clang diagnostic pop")

#define TZIgnoreWarningHelper0(x) #x
#define TZIgnoreWarningHelper1(x) TZIgnoreWarningHelper0(clang diagnostic ignored x)
#define TZIgnoreWarningHelper2(y) TZIgnoreWarningHelper1(#y)

#define TZIgnoreWarning1(_1, _2, _3, _4, _5)\
_Pragma("clang diagnostic push")\
_Pragma(TZIgnoreWarningHelper2(_1))

#define TZIgnoreWarning2(_1, _2, _3, _4, _5)\
_Pragma("clang diagnostic push")\
_Pragma(TZIgnoreWarningHelper2(_1))\
_Pragma(TZIgnoreWarningHelper2(_2))

#define TZIgnoreWarning3(_1, _2, _3, _4, _5)\
_Pragma("clang diagnostic push")\
_Pragma(TZIgnoreWarningHelper2(_1))\
_Pragma(TZIgnoreWarningHelper2(_2))\
_Pragma(TZIgnoreWarningHelper2(_3))

#define TZIgnoreWarning4(_1, _2, _3, _4, _5)\
_Pragma("clang diagnostic push")\
_Pragma(TZIgnoreWarningHelper2(_1))\
_Pragma(TZIgnoreWarningHelper2(_2))\
_Pragma(TZIgnoreWarningHelper2(_3))\
_Pragma(TZIgnoreWarningHelper2(_4))

#define TZIgnoreWarning5(_1, _2, _3, _4, _5)\
_Pragma("clang diagnostic push")\
_Pragma(TZIgnoreWarningHelper2(_1))\
_Pragma(TZIgnoreWarningHelper2(_2))\
_Pragma(TZIgnoreWarningHelper2(_3))\
_Pragma(TZIgnoreWarningHelper2(_4))\
_Pragma(TZIgnoreWarningHelper2(_5))


#ifndef weakify
    #if __has_feature(objc_arc)
        #define weakify(object) __weak __typeof__(object) weak##_##object = object;
    #else
        #define weakify(object) __block __typeof__(object) block##_##object = object;
    #endif
#endif

#ifndef strongify
    #if __has_feature(objc_arc)
        #define strongify(object)\
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Wshadow\"") \
        __typeof__(object) object = weak##_##object\
        _Pragma("clang diagnostic pop")
    #else
        #define strongify(object)\
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Wshadow\"") \
        __typeof__(object) object = block##_##object\
        _Pragma("clang diagnostic pop")
    #endif
#endif


#ifndef weakifySelf
    #if __has_feature(objc_arc)
        #define weakifySelf() __weak __typeof__(self) weakSelf = self;
    #else
        #define weakifySelf() __block __typeof__(self) weakSelf = self;
    #endif
#endif

#ifndef strongifySelf
    #define strongifySelf()\
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    __typeof__(weakSelf) self = weakSelf\
    _Pragma("clang diagnostic pop")
#endif


#ifdef DEBUG
    #define keypath(TYPE, PATH) (((void)(((TYPE *)(nil)).PATH), # PATH))
#else
    #define keypath(TYPE, PATH) (# PATH)
#endif


#endif /* ARTDefine_h */
