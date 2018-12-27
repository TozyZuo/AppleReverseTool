//
//  TZDebugUtil.h
//  Rcode
//
//  Created by TozyZuo on 2018/11/14.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TZDebugUtil : NSObject

@property (class) BOOL deallocLogEnable;

+ (NSArray<Class> *)classesInBundle:(NSBundle *)bundle;
// not support for multiple call
+ (void)addDeallocLogToClasses:(NSArray<Class> *)classes;

@end

NS_ASSUME_NONNULL_END
