//
//  ARTRichTextCell.h
//  Rcode
//
//  Created by TozyZuo on 2018/11/29.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTView.h"
#import "ARTRichTextController.h"

NS_ASSUME_NONNULL_BEGIN

@class ARTRichTextCell;

@protocol ARTRichTextCellDelegate <NSObject>
@optional
- (void)richTextCell:(ARTRichTextCell *)cell didClickLink:(NSString *)link rightMouse:(BOOL)rightMouse;
@end

@interface ARTRichTextCell : ARTView
@property (weak) IBOutlet NSTextView *textView;
@property (nonatomic, readonly) ARTRichTextController *richTextController;
@property (nonatomic, readonly) CGSize optimumSize;
@property (nonatomic,   weak  ) id<ARTRichTextCellDelegate> delegate;
- (void)initialize;
@end

NS_ASSUME_NONNULL_END
