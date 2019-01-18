//
//  ARTRichTextController.h
//  TextViewDemo
//
//  Created by TozyZuo on 2018/10/15.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <TZKit/TZRichTextController.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTRichTextController : TZRichTextController

@property (nonatomic, strong) NSString *filterConditionText;

// return value < 0 is invalid
+ (CGFloat)priorityForFilterCondition:(NSString *)conditionText string:(NSString *)string;
+ (nullable NSIndexSet *)fuzzySearchWithString:(NSString *)string conditionText:(NSString *)conditionText;

@end

NS_ASSUME_NONNULL_END
