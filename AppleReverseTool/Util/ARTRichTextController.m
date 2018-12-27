//
//  ARTRichTextController.m
//  TextViewDemo
//
//  Created by TozyZuo on 2018/10/15.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTRichTextController.h"

@interface TZRichTextController (ARTRichTextController)
- (NSColor *)colorFromAttributesValue:(NSString *)value;
@end

@interface ARTRichTextController ()

@end

@implementation ARTRichTextController

#pragma mark - Public

+ (CGFloat)priorityForFilterCondition:(NSString *)conditionText string:(NSString *)string
{
    if (!(string.length && conditionText.length)) {
        return -1;
    }

    NSInteger index = 0;

    for (int i = 0; i < conditionText.length; i++) {
        NSRange range = [string rangeOfString:[conditionText substringWithRange:NSMakeRange(i, 1)] options:NSCaseInsensitiveSearch range:NSMakeRange(index, string.length - index)];
        index = NSMaxRange(range);
        if (range.location == NSNotFound) {
            return -1;
        }
    }

    return conditionText.length/(CGFloat)string.length;
}

+ (NSIndexSet *)fuzzySearchWithString:(NSString *)string conditionText:(NSString *)conditionText
{
    if (!(string.length && conditionText.length)) {
        return nil;
    }

    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];

    NSInteger index = 0;

    for (int i = 0; i < conditionText.length; i++) {
        NSRange range = [string rangeOfString:[conditionText substringWithRange:NSMakeRange(i, 1)] options:NSCaseInsensitiveSearch range:NSMakeRange(index, string.length - index)];
        index = NSMaxRange(range);
        if (range.location != NSNotFound) {
            [indexSet addIndex:range.location];
//            NSString *tempStr = [string substringWithRange:NSMakeRange(0, range.location + 1)];
//            NSLog(@"%d %@", i, tempStr);
        }
    }

    return indexSet.count == conditionText.length ? indexSet : nil;
}

- (void)setFilterConditionText:(NSString *)filterConditionText
{
    if ((filterConditionText || _filterConditionText) &&
        ![_filterConditionText isEqualToString:filterConditionText])
    {
        NSMutableAttributedString *attributedText = self.attributedText.mutableCopy;

        [[ARTRichTextController fuzzySearchWithString:self.attributedText.string conditionText:_filterConditionText] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop)
        {
            [attributedText removeAttribute:NSBackgroundColorAttributeName range:NSMakeRange(idx, 1)];
        }];

        _filterConditionText = nil;

        if ([ARTRichTextController priorityForFilterCondition:filterConditionText string:self.attributedText.string] > 0)
        {
            _filterConditionText = filterConditionText;

            [[ARTRichTextController fuzzySearchWithString:self.attributedText.string conditionText:_filterConditionText] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop)
             {
                 [attributedText addAttribute:NSBackgroundColorAttributeName value:[self colorFromAttributesValue:@"filteredCharacterBackground"] range:NSMakeRange(idx, 1)];
             }];
        }

        self.attributedText = attributedText;
    }
}

- (void)setText:(NSString *)text
{
    if (![self.text isEqualToString:text]) {
        _filterConditionText = nil;
        [super setText:text];
    }
}

@end
