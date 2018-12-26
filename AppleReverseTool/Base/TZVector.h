//
//  TZVector.h
//
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ArrayType(...)\
(((void)((TZArrayVector __VA_ARGS__ *)(nil)), # __VA_ARGS__))

#define MapType(...)\
(((void)((TZMapVector __VA_ARGS__ *)(nil)), # __VA_ARGS__))

NS_ASSUME_NONNULL_BEGIN

@interface TZVectorType : NSObject
@property (readonly) NSUInteger level;
@property (readonly) NSString *string;
@property (readonly) Class typeClass;
@end

@protocol TZVectorProtocol <NSObject>
@property (nonatomic, copy) _Nullable id (^generateVectorBlock)(TZVectorType *type);
- (instancetype)initWithType:(NSString *)type;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

// These classes are used to fool compiler. Forbid inheriting.

#pragma mark - Map

@interface TZMapVector<K, V> : NSMutableDictionary<K, V>
<TZVectorProtocol>
@end

@interface NSCache<K, V> (TZVector)
- (nullable V)objectForKeyedSubscript:(K)key;
- (void)setObject:(nullable V)obj forKeyedSubscript:(K)key;
@end

@interface TZCacheVector<K, V> : NSCache<K, V>
<TZVectorProtocol>
@end

@interface NSMapTable<K, V> (TZVector)
- (nullable V)objectForKeyedSubscript:(K)key;
- (void)setObject:(nullable V)obj forKeyedSubscript:(K)key;
@end

@interface TZMapTableVector<K, V> : NSMapTable<K, V>
<TZVectorProtocol>
@end

#pragma mark - Array

@interface TZArrayVector<T> : NSMutableArray<T>
<TZVectorProtocol>
- (void)sortUsingComparator:(NSComparisonResult (^NS_NOESCAPE)(T obj1, T obj2))cmptr ;
@end

@interface TZOrderedSetVector<T> : NSMutableOrderedSet<T>
<TZVectorProtocol>
@end

#pragma mark - Set

@interface TZSetVector<T> : NSMutableSet<T>
<TZVectorProtocol>
@end

@interface TZCountedSetVector<T> : NSCountedSet<T>
<TZVectorProtocol>
@end

@interface TZHashTableVector<T> : NSHashTable<T>
<TZVectorProtocol>
@end


NS_ASSUME_NONNULL_END
