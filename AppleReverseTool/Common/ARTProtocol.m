//
//  ARTProtocol.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/1.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTProtocol.h"
#import <objc/runtime.h>

@interface ARTWeakObjectWrapper : NSProxy
@property (nonatomic, weak) id target;
- (instancetype)initWithTarget:(id)target;
@end

@implementation NSObject (ARTProtocol)

static void *NSObjectAssociatedObjectDictionaryKey = &NSObjectAssociatedObjectDictionaryKey;

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
    self[key] = [[ARTWeakObjectWrapper alloc] initWithTarget:obj];
}

@end

@implementation ARTWeakObjectWrapper

- (instancetype)initWithTarget:(id)target
{
    self.target = target;
    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self.target;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [NSMethodSignature signatureWithObjCTypes:"@:"];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{

}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    return [self.target isEqual:object];
}

- (NSUInteger)hash
{
    return [self.target hash];
}

- (Class)superclass
{
    return [self.target superclass];
}

- (Class)class
{
    return [self.target class];
}

- (instancetype)self
{
    return self.target;
}

- (BOOL)isKindOfClass:(Class)aClass
{
    return [self.target isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass
{
    return [self.target isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return [self.target conformsToProtocol:aProtocol];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [self.target respondsToSelector:aSelector];
}

- (NSString *)description
{
    return [self.target description];
}

@end

NSString * const ARTAssociatedKeyPrefix = @"ART_";
