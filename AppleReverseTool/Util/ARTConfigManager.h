//
//  ARTConfigManager.h
//  Rcode
//
//  Created by TozyZuo on 2018/11/19.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTConfigManager : ARTManager
@property (nonatomic, assign) BOOL showClassBundle;
@property (nonatomic, assign) BOOL hideUnexpandedVariables;
@end

@interface ARTConfigManagerController : ARTManagerController

@end

NS_ASSUME_NONNULL_END
