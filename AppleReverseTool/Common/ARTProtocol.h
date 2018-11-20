//
//  ARTProtocol.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/1.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const ARTAssociatedKeyPrefix;
NS_INLINE NSString *ARTAssociatedKeyForSelector(SEL sel)
{
    return [ARTAssociatedKeyPrefix stringByAppendingString:NSStringFromSelector(sel)];
}

@protocol ARTProtocol <NSObject>
+ (nullable id)objectForKeyedSubscript:(NSString *)key;
+ (void)setObject:(nullable id)obj forKeyedSubscript:(NSString *)key;
+ (void)setWeakObject:(nullable id)obj forKey:(NSString *)key;
- (nullable id)objectForKeyedSubscript:(NSString *)key;
- (void)setObject:(nullable id)obj forKeyedSubscript:(NSString *)key;
- (void)setWeakObject:(nullable id)obj forKey:(NSString *)key;
@end


NS_ASSUME_NONNULL_END
