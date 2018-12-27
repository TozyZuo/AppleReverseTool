//
//  TZDebugUtil.m
//  Rcode
//
//  Created by TozyZuo on 2018/11/14.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZDebugUtil.h"
#import <objc/objc-runtime.h>
#import <dlfcn.h>

//#define TZDebugUtilLogOpen
#ifdef TZDebugUtilLogOpen
#define DULog(format, ...) NSLog(format, ##__VA_ARGS__)
#else
#define DULog(...)
#endif

BOOL DUClassImplementedSelector(Class aClass, SEL aSelector)
{
    if ([aClass instancesRespondToSelector:aSelector]) {
        IMP imp = method_getImplementation(class_getInstanceMethod(aClass, aSelector));
        IMP superIMP = method_getImplementation(class_getInstanceMethod(class_getSuperclass(aClass), aSelector));
        return (!superIMP && imp) || (imp != superIMP);
    }
    return NO;
}

@implementation NSObject (TZDebugUtil)

+ (BOOL)du_implementedSelector:(SEL)aSelector
{
    return DUClassImplementedSelector(object_getClass(self), aSelector);
}

+ (BOOL)du_instancesImplementedSelector:(SEL)aSelector
{
    return DUClassImplementedSelector(self, aSelector);
}

- (BOOL)du_implementedSelector:(SEL)aSelector
{
    return DUClassImplementedSelector(self.class, aSelector);
}

@end

@implementation NSProxy (TZDebugUtil)

+ (BOOL)du_implementedSelector:(SEL)aSelector
{
    return DUClassImplementedSelector(object_getClass(self), aSelector);
}

+ (BOOL)du_instancesImplementedSelector:(SEL)aSelector
{
    return DUClassImplementedSelector(self, aSelector);
}

- (BOOL)du_implementedSelector:(SEL)aSelector
{
    return DUClassImplementedSelector(self.class, aSelector);
}

@end

static NSString * const TZDebugUtilSELPrefix = @"du_";

NSMutableSet<Class> *_classesAddedDeallocLog;

@implementation TZDebugUtil

#pragma mark - Public

static BOOL TZDebugUtilDeallocLogEnable;

+ (BOOL)deallocLogEnable
{
    return TZDebugUtilDeallocLogEnable;
}

+ (void)setDeallocLogEnable:(BOOL)deallocLogEnable
{
    TZDebugUtilDeallocLogEnable = deallocLogEnable;
}

+ (NSArray<Class> *)classesInBundle:(NSBundle *)bundle
{
    NSMutableArray *classes = [[NSMutableArray alloc] init];
    NSString *bundlePath = bundle.bundlePath;
    unsigned count;
    Class *classList = objc_copyClassList(&count);
    for (unsigned i = 0; i < count; i++) {
        Class aClass = classList[i];

        Dl_info info;
        void *addr = (__bridge void *)aClass;
        dladdr(addr, &info);

        if ([@(info.dli_fname) hasPrefix:bundlePath]) {
            [classes addObject:aClass];
        }
    }
    free(classList);

    return classes;
}

+ (void)addDeallocLogToClasses:(NSArray<Class> *)classes
{
    NSMutableSet *handledClasses = [[NSMutableSet alloc] init];
    for (Class aClass in classes) {
        if ([_classesAddedDeallocLog containsObject:aClass]) {
            continue;
        }
        Class superClass = class_getSuperclass(aClass);
        Class topClass = aClass;
        while ([classes containsObject:superClass]) {
            topClass = superClass;
            superClass = class_getSuperclass(superClass);
        }
        if (![handledClasses containsObject:topClass]) {
            DULog(@"implementation %@", topClass);
            [self addDeallocLogToClass:topClass];
            [handledClasses addObject:topClass];
        } else {
            DULog(@"%@ -> %@", aClass, topClass);
        }
    }
    DULog(@"handledClasses %@", handledClasses);

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _classesAddedDeallocLog = [[NSMutableSet alloc] init];
    });
    [_classesAddedDeallocLog unionSet:handledClasses];
}

#pragma mark - Private

+ (void)addDeallocLogToClass:(Class)aClass
{
    static IMP deallocIMP;
    static char *deallocTypes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method deallocMethod = class_getInstanceMethod(self, @selector(_dealloc));
        deallocIMP = method_getImplementation(deallocMethod);
        deallocTypes = (char *)method_getTypeEncoding(deallocMethod);
    });

    SEL dealloc = NSSelectorFromString(@"dealloc");

    if ([aClass du_instancesImplementedSelector:dealloc]) {
        SEL newDealloc = NSSelectorFromString([TZDebugUtilSELPrefix stringByAppendingString:@"dealloc"]);
        if (class_addMethod(aClass, newDealloc, deallocIMP, deallocTypes)) {
            method_exchangeImplementations(class_getInstanceMethod(aClass, newDealloc), class_getInstanceMethod(aClass, dealloc));
            DULog(@"%@ exchange dealloc", aClass);
        } else {
            DULog(@"%@ add custom dealloc failed", aClass);
        }
    } else {
        if (class_addMethod(aClass, dealloc, deallocIMP, deallocTypes)) {
            DULog(@"%@ add dealloc", aClass);
        } else {
            DULog(@"%@ add dealloc failed", aClass);
        }
    }
}

+ (Class)superclassForClassAddedDeallocLog:(Class)aClass
{
    while (aClass && ![_classesAddedDeallocLog containsObject:aClass]) {
        aClass = class_getSuperclass(aClass);
    }
    return class_getSuperclass(aClass);
}

#pragma mark SwizzledMethod

- (void)_dealloc
{
    static SEL newDealloc;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        newDealloc = NSSelectorFromString([TZDebugUtilSELPrefix stringByAppendingString:@"dealloc"]);
    });

    // get all information we needed, self below may be wild
    Class selfClass = object_getClass(self);
    NSString *logString = [NSString stringWithFormat:@"- [%@(%p) _dealloc]", selfClass, self];

    if (TZDebugUtilDeallocLogEnable) {
        NSLog(@"%@", logString);
    }
    if ([self respondsToSelector:newDealloc]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:newDealloc];
#pragma clang diagnostic pop
    } else {
        struct objc_super superStruct;
        superStruct.receiver = self;
        superStruct.super_class = [TZDebugUtil superclassForClassAddedDeallocLog:selfClass];
        ((void(*)(struct objc_super *, SEL))objc_msgSendSuper)(&superStruct, NSSelectorFromString(@"dealloc"));
    }
}

@end

