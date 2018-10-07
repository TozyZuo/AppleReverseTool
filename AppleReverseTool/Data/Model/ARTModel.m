//
//  ARTModel.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/30.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTModel.h"

@interface ARTModel ()
@property (nonatomic, strong) NSMutableSet *keys;
@end

@implementation ARTModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.keys = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)setNilValueForKey:(NSString *)key
{

}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    [self.keys addObject:key];
    [super setValue:value forUndefinedKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    if ([self.keys containsObject:key]) {
        return [super valueForUndefinedKey:key];
    }
    return nil;
}
/*
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{

}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return nil;
}
*/
- (NSString *)description
{
    return self.toDictionary.description;
}

- (NSArray *)allKeys
{
    return self.keys.allObjects;
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    for (NSString *key in self.allKeys) {
        dic[key] = self[key];
    }
    return dic;
}

@end
