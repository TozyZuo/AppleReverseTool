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
