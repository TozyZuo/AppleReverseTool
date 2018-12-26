//
//  ARTStackController.h
//  Rcode
//
//  Created by TozyZuo on 2018/12/18.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTStackController<T> : ARTController
<NSFastEnumeration>
@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward;
@property (nonatomic, readonly) NSInteger index;
@property (nonatomic, readonly) T currentObject;
@property (nonatomic, readonly) NSArray<T> *menuStack;
@property (nonatomic,  assign ) NSUInteger maxCount;

- (void)push:(T)object;
- (T)goBack;
- (T)goForward;
- (T)goToIndex:(NSInteger)index;
- (T)objectAtIndexedSubscript:(NSUInteger)idx;

@end

NS_ASSUME_NONNULL_END
