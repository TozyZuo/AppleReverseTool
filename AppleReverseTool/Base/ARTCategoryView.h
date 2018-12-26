//
//  ARTCategoryView.h
//  Rcode
//
//  Created by TozyZuo on 2018/12/11.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTCategoryView : ARTView
@property (nonatomic, strong) NSColor *strokeColor;
@property (nonatomic, strong) NSColor *color;
@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, strong) NSAttributedString *character;
@end

NS_ASSUME_NONNULL_END
