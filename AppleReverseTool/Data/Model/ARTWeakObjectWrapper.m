//
//  ARTWeakObjectWrapper.m
//  Rcode
//
//  Created by TozyZuo on 2018/10/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTWeakObjectWrapper.h"

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
