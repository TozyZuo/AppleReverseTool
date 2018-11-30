//
//  ARTClassPickerCell.h
//  Rcode
//
//  Created by TozyZuo on 2018/11/29.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTRichTextCell.h"

NS_ASSUME_NONNULL_BEGIN

@class CDOCClass;

@interface ARTClassPickerCell : ARTRichTextCell
@property (nonatomic) CDOCClass *aClass;
@end

NS_ASSUME_NONNULL_END
