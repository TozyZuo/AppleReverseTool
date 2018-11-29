//
//  ARTClassTreeCell.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTRichTextCell.h"

NS_ASSUME_NONNULL_BEGIN

@class CDOCCategory, CDOCClass, CDOCProtocol;

@interface ARTClassTreeCell : ARTRichTextCell
@property (nonatomic,   weak  ) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, readonly) __kindof CDOCProtocol *data;
@property (nonatomic, readonly) CGSize optimumSize;
- (void)updateDataWithClass:(CDOCClass *)aClass filterConditionText:(NSString *)filterConditionText totalCategoriesCount:(NSUInteger)totalCategoriesCount;
- (void)updateDataWithCategory:(CDOCCategory *)category filterConditionText:(NSString *)filterConditionText;
@end

NS_ASSUME_NONNULL_END
