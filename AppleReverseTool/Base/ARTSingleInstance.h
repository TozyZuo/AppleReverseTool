//
//  ARTSingleInstance.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/28.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTSingleInstance : NSObject
+ (instancetype)sharedInstance;
@end

@interface ARTSingleInstanceController : NSObjectController

@end

NS_ASSUME_NONNULL_END
