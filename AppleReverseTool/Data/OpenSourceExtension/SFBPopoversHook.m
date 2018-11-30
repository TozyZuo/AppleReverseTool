//
//  SFBPopoversHook.m
//  Rcode
//
//  Created by TozyZuo on 2018/11/29.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "SFBPopoversHook.h"

@implementation SFBPopoverWindow (ART)

- (BOOL)canBecomeKeyWindow
{
    return NO;
}

@end
