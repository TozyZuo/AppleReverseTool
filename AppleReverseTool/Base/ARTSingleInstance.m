//
//  ARTSingleInstance.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/28.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTSingleInstance.h"
#import <objc/runtime.h>

@implementation ARTSingleInstance

void *ARTSingleInstanceKey = &ARTSingleInstanceKey;

+ (instancetype)sharedInstance
{
    id instance = objc_getAssociatedObject(self, ARTSingleInstanceKey);
    if (!instance) {
        instance = [[self alloc] init];
        objc_setAssociatedObject(self, ARTSingleInstanceKey, instance, OBJC_ASSOCIATION_RETAIN);
    }
    return instance;
}

@end
