//
//  NSObject+ART.h
//  Rcode
//
//  Created by TozyZuo on 2018/10/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ARTProtocol)
<ARTProtocol>
@end

@interface NSObject (ARTObserve)

- (void)observe:(nullable id)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(void (^)(id _Nullable observer, id object, NSDictionary<NSKeyValueChangeKey, id> *change))block;
- (void)observe:(nullable id)object keyPaths:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options block:(void (^)(id _Nullable observer, id object, NSDictionary<NSKeyValueChangeKey, id> *change))block;

- (void)unobserve:(nullable id)object keyPath:(NSString *)keyPath;
- (void)unobserve:(nullable id)object;
- (void)unobserveAll;

@end

NS_ASSUME_NONNULL_END
