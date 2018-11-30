//
//  NSObject+ART.m
//  Rcode
//
//  Created by TozyZuo on 2018/10/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "NSObject+ART.h"
#import "ARTWeakObjectWrapper.h"
#import <objc/runtime.h>
#import <KVOController/KVOController.h>

@implementation NSObject (ARTProtocol)

static void *NSObjectAssociatedObjectDictionaryKey = &NSObjectAssociatedObjectDictionaryKey;

+ (NSMutableDictionary *)associatedObjectDictionary
{
    NSMutableDictionary *associatedObjectDictionary = objc_getAssociatedObject(self, NSObjectAssociatedObjectDictionaryKey);
    if (!associatedObjectDictionary) {
        associatedObjectDictionary = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, NSObjectAssociatedObjectDictionaryKey, associatedObjectDictionary, OBJC_ASSOCIATION_RETAIN);
    }
    return associatedObjectDictionary;
}

+ (nullable id)objectForKeyedSubscript:(NSString *)key
{
    return self.associatedObjectDictionary[key];
}

+ (void)setObject:(nullable id)obj forKeyedSubscript:(NSString *)key
{
    self.associatedObjectDictionary[key] = obj;
}

+ (void)setWeakObject:(nullable id)obj forKey:(NSString *)key
{
    if (obj) {
        ((id)self)[key] = [[ARTWeakObjectWrapper alloc] initWithTarget:obj];
    } else {
        ((id)self)[key] = nil;
    }
}

- (NSMutableDictionary *)associatedObjectDictionary
{
    NSMutableDictionary *associatedObjectDictionary = objc_getAssociatedObject(self, NSObjectAssociatedObjectDictionaryKey);
    if (!associatedObjectDictionary) {
        associatedObjectDictionary = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, NSObjectAssociatedObjectDictionaryKey, associatedObjectDictionary, OBJC_ASSOCIATION_RETAIN);
    }
    return associatedObjectDictionary;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    self.associatedObjectDictionary[key] = value;
}

- (id)valueForUndefinedKey:(NSString *)key
{
    return self.associatedObjectDictionary[key];
}

- (id)objectForKeyedSubscript:(NSString *)key
{
    return [self valueForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key
{
    [self setValue:obj forKey:key];
}

- (void)setWeakObject:(id)obj forKey:(NSString *)key
{
    if (obj) {
        self[key] = [[ARTWeakObjectWrapper alloc] initWithTarget:obj];
    } else {
        self[key] = nil;
    }
}

@end

@implementation NSObject (ARTObserve)

- (void)observe:(id)object keyPath:(nonnull NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(nonnull void (^)(id _Nullable, id _Nonnull, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull))block
{
    [self.KVOControllerNonRetaining observe:object keyPath:keyPath options:options block:block];
}

- (void)observe:(id)object keyPaths:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options block:(void (^)(id _Nullable, id _Nonnull, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull))block
{
    [self.KVOControllerNonRetaining observe:object keyPaths:keyPaths options:options block:block];
}
- (void)unobserve:(nullable id)object keyPath:(NSString *)keyPath
{
    [self.KVOControllerNonRetaining unobserve:object keyPath:keyPath];
}

- (void)unobserve:(nullable id)object
{
    [self.KVOControllerNonRetaining unobserve:object];
}

- (void)unobserveAll
{
    [self.KVOControllerNonRetaining unobserveAll];
}

@end
