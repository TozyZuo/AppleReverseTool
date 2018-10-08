//
//  NSAlert+ART.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/8.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAlert (ART)
+ (void)showModalAlertWithTitle:(NSString * _Nullable)title message:(NSString * _Nullable)message;
@end

NS_ASSUME_NONNULL_END
