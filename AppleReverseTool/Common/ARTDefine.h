//
//  ARTDefine.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/30.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#ifndef ARTDefine_h
#define ARTDefine_h

#ifndef weakifySelf
    #if __has_feature(objc_arc)
        #define weakifySelf() __weak __typeof__(self) weakSelf = self;
    #else
        #define weakifySelf() __block __typeof__(self) weakSelf = self;
    #endif
#endif

#endif /* ARTDefine_h */
