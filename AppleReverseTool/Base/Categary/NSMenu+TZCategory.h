//
//  NSMenu+TZCategory.h
//  Rcode
//
//  Created by TozyZuo on 2018/11/14.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMenu (TZCategory)
+ (NSMenu *)menuWithTitle:(NSString *)title itemsUsingBlock:(id)firstArg, ... NS_REQUIRES_NIL_TERMINATION;
+ (instancetype)menuWithTitle:(NSString *)title items:(NSArray<NSMenuItem *> *)items;
- (void)addItems:(NSArray<NSMenuItem *> *)items;
@end

extern NSString * const NSMenuSeparatorItem;
extern NSString * const NSMenuAlternateMark;

@interface NSMenuItem (TZCategory)
- (instancetype)initWithTitle:(NSString *)title userInfo:(nullable id)userInfo block:(nullable void (^)(NSMenuItem *item))block;
@end

NS_ASSUME_NONNULL_END
