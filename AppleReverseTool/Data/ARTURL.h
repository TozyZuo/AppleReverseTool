//
//  ARTURL.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/6.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTURL : NSObject
@property (readonly) NSString *scheme;
@property (readonly) NSString *host;
@property (readonly) NSString *path;
- (instancetype)initWithString:(NSString *)string;
@end

NS_ASSUME_NONNULL_END
