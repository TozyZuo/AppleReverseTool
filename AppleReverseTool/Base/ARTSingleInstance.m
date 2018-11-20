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
    id instance = ((id)self)[ARTAssociatedKeyForSelector(_cmd)];
    if (!instance) {
        instance = [[self alloc] init];
        ((id)self)[ARTAssociatedKeyForSelector(_cmd)] = instance;
    }
    return instance;
}

@end

@implementation ARTSingleInstanceController

@end
