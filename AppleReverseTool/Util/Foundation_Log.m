//
//  Foundation_Log.m
//  HomeassistantHelper
//
//  Created by TozyZuo on 2017/7/15.
//  Copyright © 2017年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSInteger __depth = 0;

@implementation NSArray(HAHLog)

- (NSString *)descriptionWithLocale:(id)locale
{
    NSString *logStr = [self descriptionWithDepth:++__depth];
    __depth--;
    return logStr;
}

- (NSString *)descriptionWithLocale:(nullable id)locale indent:(NSUInteger)level
{
    NSString *logStr = [self descriptionWithDepth:++__depth];
    __depth--;
    return logStr;
}

- (NSString *)descriptionWithDepth:(NSInteger)depth
{
    NSMutableString *logStr = [NSMutableString string];

    [logStr appendFormat:@"(\n"];

    NSInteger count = self.count;
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        for (NSInteger i = 0; i < depth; i++) {
            [logStr appendString:@"\t"];
        }

        if (idx != count - 1) {
            [logStr appendFormat:@"%@,\n", obj];
        } else {
            [logStr appendFormat:@"%@\n", obj];
        }
    }];

    for (NSInteger i = 1; i < depth; ++i) {
        [logStr appendString:@"\t"];
    }

    [logStr appendFormat:@")"];

    return logStr;
}

@end;

@implementation NSDictionary(HAHLog)

- (NSString *)descriptionWithLocale:(id)locale
{
    NSString *logStr = [self descriptionWithDepth:++__depth];
    __depth--;
    return logStr;
}

- (NSString *)descriptionWithLocale:(nullable id)locale indent:(NSUInteger)level
{
    NSString *logStr = [self descriptionWithDepth:++__depth];
    __depth--;
    return logStr;
}

- (NSString *)descriptionWithDepth:(NSInteger)depth
{
    NSMutableString *logStr = [NSMutableString string];

    [logStr appendFormat:@"{\n"];

    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        for (NSInteger i = 0; i < depth; i++) {
            [logStr appendString:@"\t"];
        }

        [logStr appendFormat:@"%@ = %@;\n", key, obj];
    }];

    for (NSInteger i = 1; i < depth; ++i) {
        [logStr appendString:@"\t"];
    }

    [logStr appendFormat:@"}"];

    return logStr;
}

@end

@implementation NSSet(HAHLog)

- (NSString *)descriptionWithLocale:(id)locale
{
    NSString *logStr = [self descriptionWithDepth:++__depth];
    __depth--;
    return logStr;
}

- (NSString *)descriptionWithLocale:(nullable id)locale indent:(NSUInteger)level
{
    NSString *logStr = [self descriptionWithDepth:++__depth];
    __depth--;
    return logStr;
}

- (NSString *)descriptionWithDepth:(NSInteger)depth
{
    NSMutableString *logStr = [NSMutableString string];

    [logStr appendFormat:@"{(\n"];

    NSInteger count = self.count;

    __block NSInteger idx = 0;
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop)
     {
         for (NSInteger i = 0; i < depth; i++) {
             [logStr appendString:@"\t"];
         }

         if (idx != count - 1) {
             [logStr appendFormat:@"%@,\n", obj];
         } else {
             [logStr appendFormat:@"%@\n", obj];
         }

         ++idx;
     }];

    for (NSInteger i = 1; i < depth; ++i) {
        [logStr appendString:@"\t"];
    }

    [logStr appendFormat:@")}"];
    
    return logStr;
}

@end

typedef struct NSSlice_ {
    __unsafe_unretained id *items; // 8
    BOOL wantsStrong;
    BOOL wantsWeak;
    BOOL wantsARC;
    BOOL shouldCopyIn;
    BOOL usesStrong;
    BOOL usesWeak;
    BOOL usesARC;
    BOOL usesSentinel;
    BOOL pointerPersonality;
    BOOL integerPersonality;
    BOOL simpleReadClear; // 19
    void *sizeFunction; // 24
    void *hashFunction; // 32
    void *isEqualFunction; // 40
    void *describeFunction;// 48
    void *acquireFunction; // 56
    void *relinquishFunction; // 64
    void *allocateFunction; // 72
    void *freeFunction; // 80
    id (*readAt)(__unsafe_unretained id *arg0, id arg1);// void *readAt; // 88
    void *clearAt; // 96
    void *storeAt; // 114
} NSSlice_;

@implementation NSMapTable (HAHLog)

- (NSString *)descriptionWithLocale:(id)locale
{
    NSString *logStr = [self descriptionWithDepth:++__depth];
    __depth--;
    return logStr;
}

- (NSString *)descriptionWithDepth:(NSInteger)depth
{
    NSMutableString *logStr = [NSMutableString string];

    [logStr appendString:@"NSMapTable {\n"];

    NSUInteger capacity = [[self valueForKey:@"capacity"] unsignedIntegerValue];

    if (capacity) {

        NSUInteger idx = 0;

        NSSlice_ keys;
        NSSlice_ values;

        NSValue *v = [self valueForKey:@"keys"];
        [v getValue:&keys];
        v = [self valueForKey:@"values"];
        [v getValue:&values];

        do {
            id key = keys.readAt(&keys.items[idx], nil);
            id value = values.readAt(&values.items[idx], nil);

            if (key && value) {

                for (NSInteger i = 0; i < depth; i++) {
                    [logStr appendString:@"\t"];
                }

                [logStr appendFormat:@"[%lu] %@ -> %@\n", idx, key, value];
            }
        } while (++idx < capacity);
    }

    for (NSInteger i = 1; i < depth; ++i) {
        [logStr appendString:@"\t"];
    }

    [logStr appendFormat:@"}"];
    
    return logStr;
}

@end

@implementation NSHashTable (HAHLog)

- (NSString *)descriptionWithLocale:(id)locale
{
    NSString *logStr = [self descriptionWithDepth:++__depth];
    __depth--;
    return logStr;
}

- (NSString *)descriptionWithDepth:(NSInteger)depth
{
    NSMutableString *logStr = [NSMutableString string];

    [logStr appendString:@"NSHashTable {\n"];

    NSUInteger capacity = [[self valueForKey:@"capacity"] unsignedIntegerValue];

    if (capacity) {

        NSUInteger idx = 0;

        NSSlice_ slice;

        NSValue *v = [self valueForKey:@"slice"];
        [v getValue:&slice];

        do {

            id object = slice.readAt(&slice.items[idx], nil);

            if (object) {

                for (NSInteger i = 0; i < depth; i++) {
                    [logStr appendString:@"\t"];
                }

                [logStr appendFormat:@"[%lu] %@\n", idx, object];
            }
        } while (++idx < capacity);
    }

    for (NSInteger i = 1; i < depth; ++i) {
        [logStr appendString:@"\t"];
    }

    [logStr appendFormat:@"}"];
    
    return logStr;
}

@end

#if (TARGET_OS_MAC && !TARGET_OS_SIMULATOR)

NSString *HAHLogDescription(id self, SEL _cmd)
{
    NSString *logStr = [self descriptionWithDepth:++__depth];
    __depth--;
    return logStr;
}

static void __attribute__((constructor)) initialize(void)
{
    method_setImplementation(class_getInstanceMethod(object_getClass([NSMapTable weakToWeakObjectsMapTable]), @selector(description)), (IMP)HAHLogDescription);
    method_setImplementation(class_getInstanceMethod(object_getClass([NSHashTable weakObjectsHashTable]), @selector(description)), (IMP)HAHLogDescription);
}

#endif
