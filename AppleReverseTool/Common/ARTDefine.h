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

#endif /* ARTDefine_h */
