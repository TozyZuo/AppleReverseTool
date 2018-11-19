//
//  ARTClassTreeCell.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CDOCClass.h"

NS_ASSUME_NONNULL_BEGIN

@class ARTClassTreeCell, CDOCCategory, ARTRichTextController;

@protocol ARTClassTreeCellDelegate <NSObject>
@optional
- (void)classTreeCell:(ARTClassTreeCell *)classTreeCell didClickLink:(NSString *)link rightMouse:(BOOL)rightMouse;
@end

@interface ARTClassTreeCell : NSView
@property (nonatomic,   weak  ) id<ARTClassTreeCellDelegate> delegate;
@property (nonatomic,   weak  ) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, readonly) __kindof CDOCProtocol *data;
@property (   weak  , readonly) NSTextView *textView;
@property (nonatomic, readonly) CGSize optimumSize;
- (void)updateDataWithClass:(CDOCClass *)class filterConditionText:(NSString *)filterConditionText totalCategoriesCount:(NSUInteger)totalCategoriesCount;
- (void)updateDataWithCategory:(CDOCCategory *)category filterConditionText:(NSString *)filterConditionText;
@end

NS_ASSUME_NONNULL_END
