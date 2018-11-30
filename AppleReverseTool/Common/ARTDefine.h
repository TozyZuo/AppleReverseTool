//
//  ARTDefine.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/30.
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

//#define TZInvokeBlockInMainThread(block)\
//if ([NSThread isMainThread]) {\
//    block();\
//} else {\
//    dispatch_async(dispatch_get_main_queue(), ^{\
//        block();\
//    });\
//}

#define TZWarningIgnoreHelper0(x) #x
#define TZWarningIgnoreHelper1(x) TZWarningIgnoreHelper0(clang diagnostic ignored x)
#define TZWarningIgnoreHelper2(y) TZWarningIgnoreHelper1(#y)

#define TZWarningIgnoreEnd _Pragma("clang diagnostic pop")
#define TZWarningIgnore(x)\
_Pragma("clang diagnostic push")\
_Pragma(TZWarningIgnoreHelper2(x))

#define TZWarningIgnoreTwo(x,y)\
_Pragma("clang diagnostic push")\
_Pragma(TZWarningIgnoreHelper2(x))\
_Pragma(TZWarningIgnoreHelper2(y))


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


#endif /* ARTDefine_h */
