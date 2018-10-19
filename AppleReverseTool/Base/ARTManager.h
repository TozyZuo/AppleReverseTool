//
//  ARTManager.h
//  Rcode
//
//  Created by TozyZuo on 2018/10/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTSingleInstance.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTManager : ARTSingleInstance
+ (instancetype)sharedManager;
@end

NS_ASSUME_NONNULL_END
