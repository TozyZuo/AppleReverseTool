//
//  ARTConfigManager.m
//  Rcode
//
//  Created by TozyZuo on 2018/11/19.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTConfigManager.h"
#import <objc/objc-runtime.h>

@interface TZProperty : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *classString;
@property (nonatomic, assign) BOOL isReadOnly;
@property (nonatomic, assign) objc_property_t property;
- (instancetype)initWithProperty:(objc_property_t)property;
@end

@implementation TZProperty

- (instancetype)initWithProperty:(objc_property_t)p
{
    if (self = [super init]) {
        self.property = p;

        self.name = [NSString stringWithUTF8String:property_getName(p)];

        for (NSString *attribute in [@(property_getAttributes(p)) componentsSeparatedByString:@","]) {
            if ([attribute hasPrefix:@"T"]) {
                NSString *classString = [attribute substringFromIndex:1];
                if ([classString hasPrefix:@"@"]) {
                    classString = [classString substringWithRange:NSMakeRange(2, classString.length - 3)];
                }
                self.classString = classString;
            } else if ([attribute hasPrefix:@"R"]) {
                self.isReadOnly = YES;
            }
        }
    }
    return self;
}

@end

@protocol TZObjectInfoProtocol <NSObject>
@property (readonly) NSArray *ignoredProperties;
@end

@interface TZObjectInfo : NSObject
@property (nonatomic, copy) NSDictionary<NSString */*name*/, TZProperty */*property*/> *propertyDictionary;
@property (nonatomic, copy) NSArray *properties;
- (instancetype)initWithObject:(NSObject<TZObjectInfoProtocol> *)object;
- (NSString *)classStringForProperty:(NSString *)property;
@end

@implementation TZObjectInfo

- (instancetype)initWithObject:(NSObject<TZObjectInfoProtocol> *)object
{
    if (self = [super init]) {

        NSMutableArray *properties = [[NSMutableArray alloc] init];
        NSMutableDictionary *propertyDictionary = [[NSMutableDictionary alloc] init];

        Class class = object.class;

        while (class != [NSObject class]) {

            objc_property_t *pList;
            unsigned count;
            pList = class_copyPropertyList(class, &count);

            for (int i = 0; i < count; i++) {

                objc_property_t p = pList[i];

                if ([object.ignoredProperties containsObject:@(property_getName(p))]) {
                    continue;
                }

                TZProperty *property = [[TZProperty alloc] initWithProperty:p];
                [properties addObject:property];
                propertyDictionary[@(property_getName(p))] = property;
            }
            free(pList);
            class = class_getSuperclass(class);
        }
        self.properties = properties.reverseObjectEnumerator.allObjects;
        self.propertyDictionary = propertyDictionary;
    }
    return self;
}

- (NSString *)classStringForProperty:(NSString *)property
{
    return self.propertyDictionary[property].classString;
}

@end

static NSString *ARTConfigManagerUserDefaultsKeyPrefix = @"ARTConfigManager";
static NSString *ARTConfigManagerPropertySwizzledSuffix = @"_swizzled";

@interface ARTConfigManager ()
<TZObjectInfoProtocol>
@property (nonatomic, strong) TZObjectInfo *info;
@property (nonatomic, strong) NSDictionary *dispathMap;
@end

@implementation ARTConfigManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.info = [[TZObjectInfo alloc] initWithObject:self];
        self.dispathMap = @{@"c": NSStringFromSelector(@selector(handleBOOLInvocation:))};

        for (TZProperty *property in self.info.properties) {
            if (!property.isReadOnly) {
                [self setValue:NSUserDefaults.standardUserDefaults[[ARTConfigManagerUserDefaultsKeyPrefix stringByAppendingString:property.name]] forKey:property.name];
                [self swizzleSetMethodWithProperty:property];
            }
        }
    }
    return self;
}

- (void)setNilValueForKey:(NSString *)key
{
    // prevent from crashing
}

#pragma mark - Private

- (void)swizzleSetMethodWithProperty:(TZProperty *)property
{
    static IMP msgForwardIMP = _objc_msgForward;

    const char *key = property.name.UTF8String;
    size_t size = strlen(key);
    char buf[size + 5];

    strncpy(buf, "set", 3);
    strncpy(&buf[3], key, size);
    char lo = buf[3];
    char hi = islower(lo) ? toupper(lo) : lo;
    buf[3] = hi;
    buf[size + 3] = ':';
    buf[size + 4] = '\0';

    SEL setSEL = sel_registerName(buf);

    Method originMethod = class_getInstanceMethod(self.class, setSEL);

    IMP originIMP = class_replaceMethod(self.class, setSEL, msgForwardIMP, method_getTypeEncoding(originMethod));
    class_addMethod(self.class, [self originSelectorFromSetSelector:setSEL], originIMP, method_getTypeEncoding(originMethod));
}

- (NSString *)propertyFromSetSelector:(SEL)sel
{
    const char *setSEL = sel_getName(sel);
    size_t size = strlen(setSEL) - 3;
    char buf[size];

    // setXXX:
    strncpy(buf, &setSEL[3], size);
    char hi = buf[0];
    char lo = isupper(hi) ? tolower(hi) : hi;
    buf[0] = lo;
    buf[size - 1] = '\0';

    return [NSString stringWithUTF8String:buf];
}

- (SEL)originSelectorFromSetSelector:(SEL)sel
{
    static NSMutableDictionary *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSMutableDictionary alloc] init];
    });
    NSString *selString = NSStringFromSelector(sel);
    NSString *retSELString = cache[selString];
    if (!retSELString) {
        NSMutableString *mSELString = selString.mutableCopy;
        [mSELString insertString:ARTConfigManagerPropertySwizzledSuffix atIndex:selString.length - 1];
        retSELString = mSELString.copy;
        cache[selString] = retSELString;
    }

    return NSSelectorFromString(retSELString);
}

- (void)handleBOOLInvocation:(NSInvocation *)invocation
{
    NSInvocation *anInvocation = invocation;
    BOOL value;
    [anInvocation getArgument:&value atIndex:2];

    NSString *property = [self propertyFromSetSelector:invocation.selector];

    if ([[self valueForKey:property] boolValue] != value) {
//        Ivar ivar = class_getInstanceVariable(self.class, [@"_" stringByAppendingString:[self propertyFromSetSelector:invocation.selector]].UTF8String);
//        BOOL *ivarPtr = (BOOL *)&((char *)(__bridge void *)self)[ivar_getOffset(ivar)];
//        *ivarPtr = value;
        [self setValue:@(value) forKey:[property stringByAppendingString:ARTConfigManagerPropertySwizzledSuffix]];

        NSUserDefaults.standardUserDefaults[[ARTConfigManagerUserDefaultsKeyPrefix stringByAppendingString:property]] = @(value);
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}

#pragma mark Forward Invocation

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(class_getInstanceMethod(self.class, aSelector))];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSString *sel = self.dispathMap[[self.info classStringForProperty:[self propertyFromSetSelector:anInvocation.selector]]];
    NSInvocation *invocation = anInvocation;
    if (sel) {
        TZWarningIgnore(-Warc-performSelector-leaks)
        [self performSelector:NSSelectorFromString(sel) withObject:invocation];
        TZWarningIgnoreEnd
    }
}

#pragma mark - TZObjectInfoProtocol

- (NSArray *)ignoredProperties
{
    return @[@"info",
             @"dispathMap",
             @"debugDescription",
             @"description",
             @"hash",
             @"superclass",
             ];
}

@end

@implementation ARTConfigManagerController

@end
