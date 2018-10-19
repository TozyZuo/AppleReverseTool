//
//  ARTWeakObjectWrapper.h
//  Rcode
//
//  Created by TozyZuo on 2018/10/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTWeakObjectWrapper : NSProxy
@property (nonatomic, weak) id target;
- (instancetype)initWithTarget:(id)target;
@end

NS_ASSUME_NONNULL_END
