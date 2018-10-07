//
//  ARTModel.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/30.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTModel : NSObject
@property (nonatomic, readonly) NSArray *allKeys;
@property (nonatomic, readonly) NSDictionary *toDictionary;
@end

NS_ASSUME_NONNULL_END
