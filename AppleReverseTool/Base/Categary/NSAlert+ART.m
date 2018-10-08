//
//  NSAlert+ART.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/8.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "NSAlert+ART.h"

@implementation NSAlert (ART)

+ (void)showModalAlertWithTitle:(NSString * _Nullable)title message:(NSString * _Nullable)message
{
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = message;
    [alert runModal];
}

@end
