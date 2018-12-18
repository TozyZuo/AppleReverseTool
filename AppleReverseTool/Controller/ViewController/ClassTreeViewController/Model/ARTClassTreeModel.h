//
//  ARTClassTreeModel.h
//  Rcode
//
//  Created by TozyZuo on 2018/12/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CDOCClass, ARTRichTextController;

@interface ARTClassTreeModel : ARTModel

@property (nonatomic,  assign ) BOOL expanded;
@property (nonatomic,  assign ) BOOL isCategoryExpanded;
@property (nonatomic,  strong ) NSString *filterConditionText;
@property (nonatomic,   weak  ) ARTRichTextController *richTextController;
@property (nonatomic, readonly) NSString *text;

+ (instancetype)modelWithData:(CDOCClass *)data;

@end

NS_ASSUME_NONNULL_END
