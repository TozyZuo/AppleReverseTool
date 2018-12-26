//
//  TZVector.m
//
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZVector.h"
#import <objc/objc-runtime.h>

#define UsePrivateAPI

#define TZVectorCheckAssert(condition) NSAssert((condition), @"handle this")

static NSString * const TZVectorInteralVectorClassSuffix = @"_vector";
static NSString * const TZVectorSelectorPrefix = @"vector_";

@interface NSObject (TZVector)
- (BOOL)_isKVOA;
@end

@interface NSInvocation (TZVector)
- (void)invokeSuper;
- (void)invokeUsingIMP:(IMP)imp;
@end

@interface TZMapVector (TZVectorFixWarning)
- (nullable id)vector_objectForKey:(id)aKey;
- (void)vector_setObject:(id)anObject forKey:(id)aKey;
@end

@interface TZArrayVector (TZVectorFixWarning)
- (id)vector_objectAtIndex:(NSUInteger)index;
- (void)vector_setObject:(id)obj atIndex:(NSUInteger)idx;
- (void)vector_insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)vector_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
@end

@interface TZSetVector (TZVectorFixWarning)
- (nullable id)vector_anyObject;
- (void)vector_addObject:(id)object;
@end

typedef NS_ENUM(NSInteger, TZVectorTypeDetailType) {
    TZVectorTypeDetailTypeUnknown   =   0,
    TZVectorTypeDetailTypeMap       =   1,
    TZVectorTypeDetailTypeArray     =   2,
    TZVectorTypeDetailTypeSet       =   3,
};

@interface TZVectorType ()
@property (nonatomic, assign) NSUInteger level;
@property (nonatomic, strong) NSString *string;
@property (nonatomic, assign) Class typeClass;
@property (nonatomic, assign) Class keyClass;
@property (nonatomic, assign) Class valueClass;
@property (nonatomic, strong) NSString *keyClassSring;
@property (nonatomic, strong) NSString *valueClassSring;
@property (nonatomic, assign) BOOL isContentAVector;
@property (nonatomic, assign) TZVectorTypeDetailType detailType;
- (instancetype)initWithTypeString:(NSString *)string level:(NSUInteger)level;
- (NSString *)sublevelStringFromTypeString:(NSString *)string;
- (BOOL)checkKeyObject:(id)object;
- (BOOL)checkValueObject:(id)object;
+ (NSArray<Class> *)supportedVectorClasses;
@end

const void *TZVectorRefKey = &TZVectorRefKey;

@interface TZVector : NSProxy
<TZVectorProtocol>
@property (  class  , readonly) NSMutableArray<Class> *cachedVectorClasses;
@property (  class  , readonly) NSMutableSet<NSString *> *cachedVectorSelectors;
@property (nonatomic,  strong ) TZVectorType *type;
@property (nonatomic,  strong ) id vector;
@end

@implementation TZVector
@synthesize generateVectorBlock = _generateVectorBlock;

- (instancetype)initWithType:(NSString *)type
{
    return [self initWithType:type level:0];
}

- (instancetype)initWithType:(NSString *)type level:(NSUInteger)level
{
    self.type = [[TZVectorType alloc] initWithTypeString:type level:level];
    return self;
}

+ (NSMutableArray<Class> *)cachedVectorClasses
{
    static NSMutableArray *cachedVectorClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cachedVectorClass = [[NSMutableArray alloc] init];
    });
    return cachedVectorClass;
}

+ (NSMutableSet<NSString *> *)cachedVectorSelectors
{
    static NSMutableSet *cachedVectorSelectors;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cachedVectorSelectors = [[NSMutableSet alloc] init];
    });
    return cachedVectorSelectors;
}


- (id)unknownSelector
{
    return self;
}

- (void)generateVector
{
    if (!self.vector) {

        id vector;
        TZVectorType *type = self.type;

        if (self.generateVectorBlock) {
            vector = self.generateVectorBlock(type);
            if (vector) {
                NSAssert([vector isKindOfClass:type.typeClass], @"TZVector: vector%@ needs a `%@`, but got `%@`", type.string, type.typeClass, [vector class]);
            }
        }

        if (!vector) {
            vector = [[type.typeClass alloc] init];
        }

        self.vector = [self addAutoGenerateContentVectorAbilityToVector:vector];
    }
}

- (id)addAutoGenerateContentVectorAbilityToVector:(id)vector
{
    Class vectorClass = [self realVectorClassForVector:vector];

    if (![TZVector.cachedVectorClasses containsObject:vectorClass]) {

        NSArray *selectors;

        switch (self.type.detailType) {
            case TZVectorTypeDetailTypeMap:
                selectors = @[NSStringFromSelector(@selector(objectForKey:)),
                              NSStringFromSelector(@selector(setObject:forKey:)),
                              NSStringFromSelector(@selector(objectForKeyedSubscript:)),
                              NSStringFromSelector(@selector(setObject:forKeyedSubscript:)),];
                break;
            case TZVectorTypeDetailTypeArray:
                selectors = @[NSStringFromSelector(@selector(firstObject)),
                              NSStringFromSelector(@selector(lastObject)),
                              NSStringFromSelector(@selector(objectAtIndex:)),
                              NSStringFromSelector(@selector(objectAtIndexedSubscript:)),
                              NSStringFromSelector(@selector(insertObject:atIndex:)),
                              NSStringFromSelector(@selector(replaceObjectAtIndex:withObject:)),
                              NSStringFromSelector(@selector(setObject:atIndex:)),
                              NSStringFromSelector(@selector(setObject:atIndexedSubscript:)),];
                break;
            case TZVectorTypeDetailTypeSet:
                selectors = @[NSStringFromSelector(@selector(anyObject)),
                              NSStringFromSelector(@selector(addObject:))];
                break;
            default:
            {
                NSMutableArray *array = [[NSMutableArray alloc] init];
                Class vectorSuperClass = [vectorClass superclass];
                unsigned count;
                Method *methods = class_copyMethodList(vectorSuperClass, &count);

                for (int i = 0; i < count; i++) {
                    [array addObject:NSStringFromSelector(method_getName(methods[i]))];
                }

                free(methods);

                selectors = array;
            }
                break;
        }

        for (NSString *sel in selectors) {

            SEL selector = NSSelectorFromString(sel);

            if (class_respondsToSelector(vectorClass, selector)) {

                Method method = class_getInstanceMethod(vectorClass, selector);

                // hook origin
                TZVectorCheckAssert(class_addMethod(vectorClass, selector, _objc_msgForward, method_getTypeEncoding(method)));
                // save origin
                TZVectorCheckAssert(class_addMethod(vectorClass, NSSelectorFromString([TZVectorSelectorPrefix stringByAppendingString:sel]), _objc_msgForward, method_getTypeEncoding(method)));

                [TZVector.cachedVectorSelectors addObject:sel];
            }
        }

        TZVectorCheckAssert(class_addMethod(vectorClass, @selector(forwardingTargetForSelector:), class_getMethodImplementation(TZVector.class, @selector(vector_forwardingTargetForSelector:)), "@@::"));
        TZVectorCheckAssert(class_addMethod(vectorClass, @selector(methodSignatureForSelector:), class_getMethodImplementation(TZVector.class, @selector(vector_methodSignatureForSelector:)), "@@::"));
        TZVectorCheckAssert(class_addMethod(vectorClass, @selector(forwardInvocation:), class_getMethodImplementation(TZVector.class, @selector(vector_forwardInvocation:)), "v@:@"));

        [TZVector.cachedVectorClasses addObject:vectorClass];
    }

    object_setClass(vector, vectorClass);

    objc_setAssociatedObject(vector, TZVectorRefKey, self, OBJC_ASSOCIATION_ASSIGN);

    return vector;
}

- (Class)realVectorClassForVector:(id)vector
{
    Class vectorClass;

    if ([vector _isKVOA])
    {
        vectorClass = object_getClass(vector);
    }
    else
    {
        Class typeClass = [vector class];
        NSString *vectorClassString = [NSStringFromClass(typeClass) stringByAppendingString:TZVectorInteralVectorClassSuffix];
        vectorClass = NSClassFromString(vectorClassString);
        if (!vectorClass) {
            vectorClass = objc_allocateClassPair(typeClass, vectorClassString.UTF8String, 0);
            objc_registerClassPair(vectorClass);
        }
    }

    return vectorClass;
}

#pragma mark - Forward

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    [self generateVector];

    return nil;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if ([self.vector respondsToSelector:aSelector]) {
        return [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(class_getInstanceMethod([self.vector class], aSelector))];
    }

    return [NSMethodSignature signatureWithObjCTypes:"@@:"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([NSStringFromSelector(anInvocation.selector) hasPrefix:TZVectorSelectorPrefix])
    {
        anInvocation.target = self.vector;
    }
    else if ([self.vector respondsToSelector:anInvocation.selector])
    {
        anInvocation.target = self.vector;
        if ([TZVector.cachedVectorSelectors containsObject:NSStringFromSelector(anInvocation.selector)]) {
            anInvocation.selector = NSSelectorFromString([TZVectorSelectorPrefix stringByAppendingString:NSStringFromSelector(anInvocation.selector)]);
        }
    }
    else
    {
        anInvocation.selector = @selector(unknownSelector);
    }

    [anInvocation invoke];
}

#pragma mark - Vector Forward

- (id)vector_forwardingTargetForSelector:(SEL)aSelector
{
    if (![NSStringFromSelector(aSelector) hasPrefix:TZVectorSelectorPrefix]) {
        // if TZVectorRef was wild, please check yourself.
        return objc_getAssociatedObject(self, TZVectorRefKey);
    }

    return self;
}

- (NSMethodSignature *)vector_methodSignatureForSelector:(SEL)aSelector
{
    return [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(class_getInstanceMethod(self.class, aSelector))];
}

- (void)vector_forwardInvocation:(NSInvocation *)anInvocation
{
    NSString *sel = NSStringFromSelector(anInvocation.selector);
    if ([sel hasPrefix:TZVectorSelectorPrefix]) {
        anInvocation.selector = NSSelectorFromString([sel substringFromIndex:TZVectorSelectorPrefix.length]);
    }
#ifdef UsePrivateAPI
    [anInvocation invokeSuper];
#else
    id target = anInvocation.target;
    Class cls = object_getClass(target);
    object_setClass(anInvocation.target, [cls superclass]);
    [anInvocation invoke];
    object_setClass(target, cls);
#endif
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    return [self.vector isEqual:object];
}

- (NSUInteger)hash
{
    return [self.vector hash];
}

- (Class)superclass
{
    return [self.vector superclass];
}

- (Class)class
{
    return [self.vector class];
}

- (instancetype)self
{
    return self.vector;
}

- (BOOL)isKindOfClass:(Class)aClass
{
    return [self.vector isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass
{
    return [self.vector isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return [self.vector conformsToProtocol:aProtocol];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [self.vector respondsToSelector:aSelector];
}

- (NSString *)description
{
    return [self.vector description] ?: [NSString stringWithFormat:@"%@(uninitialized)", NSStringFromClass(self.type.typeClass)];
}

#pragma mark - Map

- (nullable id)objectForKey:(id)aKey
{
    return self[aKey];
}

- (nullable id)objectForKeyedSubscript:(id)key
{
    [self generateVector];

    TZVectorCheckAssert([self.vector respondsToSelector:@selector(objectForKey:)]);

    id object = [self.vector vector_objectForKey:key];

    TZVectorType *type = self.type;

    if (!object && type.isContentAVector && [self.vector respondsToSelector:@selector(vector_setObject:forKey:)])
    {
        object = [[TZVector alloc] initWithType:[type sublevelStringFromTypeString:type.string] level:type.level + 1];
        ((TZVector *)object).generateVectorBlock = self.generateVectorBlock;
        [self.vector vector_setObject:object forKey:key];
    }

    return object;
}

- (void)setObject:(id)anObject forKey:(id)aKey
{
    self[aKey] = anObject;
}

- (void)setObject:(nullable id)obj forKeyedSubscript:(id)key
{
    [self generateVector];

    TZVectorCheckAssert([self.vector respondsToSelector:@selector(setObject:forKey:)]);

    NSAssert([self.type checkKeyObject:key], @"Vector%@ needs `%@` as key, but receive `%@` %@", self.type.string, self.type.keyClassSring, [key class] ?: @"nil", key ?: @"");
    NSAssert(!obj || [self.type checkValueObject:obj], @"Vector%@ needs `%@` as value, but receive `%@` %@", self.type.string, self.type.valueClassSring, [obj class], obj);

    if (obj) {
        [self.vector vector_setObject:obj forKey:key];
    } else {
        [self.vector removeObjectForKey:key];
    }
}

#pragma mark - Array

- (id)firstObject
{
    return self[0];
}

- (id)lastObject
{
    if (![self.vector count]) {
        return self[0];
    }
    return self[[self.vector count] - 1];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return self[index];
}

- (id)objectAtIndexedSubscript:(NSUInteger)index
{
    [self generateVector];

    TZVectorCheckAssert([self.vector respondsToSelector:@selector(objectAtIndex:)]);

    id object;
    if (index < [self.vector count]) {
        object = [self.vector vector_objectAtIndex:index];
    }

    TZVectorType *type = self.type;

    if (!object && type.isContentAVector)
    {
        NSLog(@"TZVector: Extremely NOT Recommend using a `%@` in vector chain, please use a map vector instead.", self.type.typeClass);
        object = [[TZVector alloc] initWithType:[type sublevelStringFromTypeString:type.string] level:type.level + 1];
        TZVector *vector = object;
        vector.generateVectorBlock = self.generateVectorBlock;
        if (index != [self.vector count]) {
            NSLog(@"TZVector: Auto generate a vector(%@%@) at index %lu, not %lu, please check.", vector.type.typeClass, vector.type.string, [self.vector count], index);
        }
        [self.vector vector_insertObject:object atIndex:[self.vector count]];
//        [self.vector addObject:object];
    }

    return object;
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    [self generateVector];

    NSAssert(!anObject || [self.type checkValueObject:anObject], @"Vector%@ needs `%@` as content, but receive `%@` %@", self.type.string, self.type.valueClassSring, [anObject class], anObject);
    if (anObject) {
        [self.vector vector_insertObject:anObject atIndex:index];
    } else {
        NSLog(@"TZVector: Vector%@ receive `nil`. -[%@ %@]", self.type.string, self.type.typeClass, NSStringFromSelector(_cmd));
    }
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    NSAssert(!anObject || [self.type checkValueObject:anObject], @"Vector%@ needs `%@` as content, but receive `%@` %@", self.type.string, self.type.valueClassSring, [anObject class], anObject);
    if (anObject) {
        [self.vector vector_replaceObjectAtIndex:index withObject:anObject];
    } else {
        NSLog(@"TZVector: Vector%@ receive `nil`. -[%@ %@]", self.type.string, self.type.typeClass, NSStringFromSelector(_cmd));
    }
}

- (void)setObject:(id)obj atIndex:(NSUInteger)idx
{
    self[idx] = obj;
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    [self generateVector];

    NSAssert(!obj || [self.type checkValueObject:obj], @"Vector%@ needs `%@` as content, but receive `%@` %@", self.type.string, self.type.valueClassSring, [obj class], obj);

    if (obj) {
        [self.vector vector_setObject:obj atIndex:idx];
    } else {
        NSLog(@"TZVector: Vector%@ receive `nil`. -[%@ %@]", self.type.string, self.type.typeClass, NSStringFromSelector(_cmd));
    }
}

#pragma mark - Set

- (nullable id)anyObject
{
    [self generateVector];

    TZVectorCheckAssert([self.vector respondsToSelector:@selector(anyObject)]);

    id object = [self.vector vector_anyObject];

    TZVectorType *type = self.type;

    if (!object && type.isContentAVector)
    {
        NSLog(@"TZVector: Extremely NOT Recommend using a `%@` in vector chain, please use a map vector instead.", self.type.typeClass);
        object = [[TZVector alloc] initWithType:[type sublevelStringFromTypeString:type.string] level:type.level + 1];
        ((TZVector *)object).generateVectorBlock = self.generateVectorBlock;
        [self.vector vector_addObject:object];
    }

    return object;
}

- (void)addObject:(id)anObject
{
    [self generateVector];

    if (self.type.detailType == TZVectorTypeDetailTypeSet) {
        NSAssert(!anObject || [self.type checkValueObject:anObject], @"Vector%@ needs `%@` as content, but receive `%@` %@", self.type.string, self.type.valueClassSring, [anObject class], anObject);
        if (anObject) {
            [self.vector vector_addObject:anObject];
        } else {
            NSLog(@"TZVector: Vector%@ receive `nil`. -[%@ %@]", self.type.string, self.type.typeClass, NSStringFromSelector(_cmd));
        }
    } else {
        [self.vector addObject:anObject];
    }
}

@end


#define IgnoreWarningHelper0(x) #x
#define IgnoreWarningHelper1(x) IgnoreWarningHelper0(clang diagnostic ignored x)
#define IgnoreWarningHelper2(y) IgnoreWarningHelper1(#y)

#define IgnoreWarningEnd _Pragma("clang diagnostic pop")

#define IgnoreWarning(...) IgnoreWarnings(__VA_ARGS__, 5, 4, 3, 2, 1)
#define IgnoreWarnings(_1, _2, _3, _4, _5, N, ...) _IgnoreWarnings(N, _1, _2, _3, _4, _5)
#define _IgnoreWarnings(count, args...) IgnoreWarning ## count(args)

#define IgnoreWarning1(_1, _2, _3, _4, _5)\
_Pragma("clang diagnostic push")\
_Pragma(IgnoreWarningHelper2(_1))

#define IgnoreWarning2(_1, _2, _3, _4, _5)\
_Pragma("clang diagnostic push")\
_Pragma(IgnoreWarningHelper2(_1))\
_Pragma(IgnoreWarningHelper2(_2))

#define IgnoreWarning3(_1, _2, _3, _4, _5)\
_Pragma("clang diagnostic push")\
_Pragma(IgnoreWarningHelper2(_1))\
_Pragma(IgnoreWarningHelper2(_2))\
_Pragma(IgnoreWarningHelper2(_3))

#define IgnoreWarning4(_1, _2, _3, _4, _5)\
_Pragma("clang diagnostic push")\
_Pragma(IgnoreWarningHelper2(_1))\
_Pragma(IgnoreWarningHelper2(_2))\
_Pragma(IgnoreWarningHelper2(_3))\
_Pragma(IgnoreWarningHelper2(_4))

#define IgnoreWarning5(_1, _2, _3, _4, _5)\
_Pragma("clang diagnostic push")\
_Pragma(IgnoreWarningHelper2(_1))\
_Pragma(IgnoreWarningHelper2(_2))\
_Pragma(IgnoreWarningHelper2(_3))\
_Pragma(IgnoreWarningHelper2(_4))\
_Pragma(IgnoreWarningHelper2(_5))


#define VectorImplementation(VectorClass)\
\
IgnoreWarning(-Wincompatible-pointer-types, -Wobjc-designated-initializers, -Wincomplete-implementation)\
\
@implementation VectorClass \
\
@dynamic generateVectorBlock;\
\
+ (instancetype)alloc\
{\
    if (self != VectorClass.class) {\
        return [VectorClass alloc];\
    }\
    return [super alloc];\
}\
\
- (instancetype)initWithType:(NSString *)type\
{\
    return [[TZVector alloc] initWithType:[NSString stringWithFormat:@"%@%@ *", self.superclass, type]];\
}\
\
@end \
\
IgnoreWarningEnd


VectorImplementation(TZMapVector)
VectorImplementation(TZCacheVector)
VectorImplementation(TZMapTableVector)
VectorImplementation(TZArrayVector)
VectorImplementation(TZOrderedSetVector)
VectorImplementation(TZSetVector)
VectorImplementation(TZCountedSetVector)
VectorImplementation(TZHashTableVector)


@implementation TZVectorType

- (instancetype)initWithTypeString:(NSString *)string level:(NSUInteger)level
{
    self = [super init];
    if (self) {
        self.level = level;

        string = [string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if ([string hasPrefix:@"<"]) {
            string = [string substringFromIndex:1];
        }
        if ([string hasSuffix:@">"]) {
            string = [string substringToIndex:string.length - 2];
        }

        NSString *sublevelString = [self sublevelStringFromTypeString:string];

        self.string = [NSString stringWithFormat:@"<%@>", sublevelString];

        [self classFromTypeString:string outKeyClass:NULL outValueClass:&_typeClass outKeyClassString:NULL outValueClassString:NULL];

        NSString *keyString, *valueString;
        [self classFromTypeString:sublevelString outKeyClass:&_keyClass outValueClass:&_valueClass outKeyClassString:&keyString outValueClassString:&valueString];
        self.keyClassSring = keyString;
        self.valueClassSring = valueString;

        self.isContentAVector = [sublevelString rangeOfString:@"<"].length > 0;

        if (_typeClass == NSMutableDictionary.class ||
            _typeClass == NSCache.class ||
            _typeClass == NSMapTable.class)
        {
            self.detailType = TZVectorTypeDetailTypeMap;
        }
        else if (_typeClass == NSMutableArray.class ||
                 _typeClass == NSMutableOrderedSet.class)
        {
            self.detailType = TZVectorTypeDetailTypeArray;
        }
        else if (_typeClass == NSHashTable.class ||
                 _typeClass == NSMutableSet.class ||
                 _typeClass == NSCountedSet.class)
        {
            self.detailType = TZVectorTypeDetailTypeArray;
        }
    }
    return self;
}

- (void)classFromTypeString:(NSString *)string outKeyClass:(Class *)outKeyClass outValueClass:(Class *)outValueClass outKeyClassString:(NSString **)outKeyClassString outValueClassString:(NSString **)outValueClassString
{
    if (!string.length) {
        return;
    }

    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];

    if ([string hasPrefix:@"<"]) {
        string = [string substringFromIndex:1];
    }
    if ([string hasSuffix:@">"]) {
        string = [string substringToIndex:string.length - 2];
    }

    NSString *classStrings;
    NSScanner *scanner = [[NSScanner alloc] initWithString:string];
    [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"<"] intoString:&classStrings];

    NSArray *classStringArray = [classStrings componentsSeparatedByString:@","];
    NSString *classString;

    if (classStringArray.count == 1)
    {
        if (outValueClass || outValueClassString) {
            [[[NSScanner alloc] initWithString:classStringArray.firstObject] scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"*"] intoString:&classString];
            [self cleanClass:classString outClass:outValueClass outClassString:outValueClassString];
        }
    }
    else if (classStringArray.count == 2)
    {
        if (outKeyClass || outKeyClassString) {
            [[[NSScanner alloc] initWithString:classStringArray.firstObject] scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"*"] intoString:&classString];
            [self cleanClass:classString outClass:outKeyClass outClassString:outKeyClassString];
        }

        if (outValueClass || outValueClassString) {
            [[[NSScanner alloc] initWithString:classStringArray.lastObject] scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"*"] intoString:&classString];
            [self cleanClass:classString outClass:outValueClass outClassString:outValueClassString];
        }
    }
}

- (NSString *)sublevelStringFromTypeString:(NSString *)string
{
    if (!string.length) {
        return nil;
    }

    string = [string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];

    if (![string rangeOfString:@"<"].length) {
        return nil;
    }

    NSUInteger start = [string rangeOfString:@"<"].location;
    NSUInteger end = [string rangeOfString:@">" options:NSBackwardsSearch].location;

    return [string substringWithRange:NSMakeRange(start + 1, end - start - 1)];
}

- (void)cleanClass:(NSString *)classString outClass:(Class *)outClass outClassString:(NSString **)outClassString
{
    Class aClass;
    if ([classString isEqualToString:@"id"]) {
        if (outClassString) {
            *outClassString = classString;
        }
        if (outClass) {
            *outClass = nil;
        }
    } else if ([classString isEqualToString:@"Class"]) {
        if (outClassString) {
            *outClassString = classString;
        }
        if (outClass) {
            *outClass = object_getClass([NSObject class]);
        }
    } else {
        aClass = NSClassFromString(classString);
        for (Class c in [TZVectorType confusedVectorClasses]) {
            if ([aClass isSubclassOfClass:c]) {
                while (![[TZVectorType supportedVectorClasses] containsObject:aClass]) {
                    aClass = [aClass superclass];
                }
                break;
            }
        }

        if (outClassString) {
            *outClassString = NSStringFromClass(aClass);
        }
        if (outClass) {
            *outClass = aClass;
        }
    }
}

+ (NSArray<Class> *)supportedVectorClasses
{
    static NSArray *supportedVectorClasses;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (Class aClass in [self confusedVectorClasses]) {
            [array addObject:[aClass superclass]];
        }
        supportedVectorClasses = array.copy;
    });
    return supportedVectorClasses;
}

+ (NSArray<Class> *)confusedVectorClasses
{
    static NSArray *confusedVectorClasses;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        confusedVectorClasses = @[// sort by probability, guess personally
                                  TZMapVector.class,
                                  TZArrayVector.class,
                                  TZCacheVector.class,
                                  TZHashTableVector.class,
                                  TZMapTableVector.class,
                                  TZSetVector.class,
                                  TZOrderedSetVector.class,
                                  TZCountedSetVector.class,
                                  /*
                                  // array
                                  TZArrayVector.class,
                                  TZOrderedSetVector.class,
                                  // set
                                  TZSetVector.class,
                                  TZCountedSetVector.class,
                                  TZHashTableVector.class,
                                  // map
                                  TZMapVector.class,
                                  TZMapTableVector.class,
                                   */];
    });
    return confusedVectorClasses;
}

- (BOOL)checkKeyObject:(id)object
{
    if ([self.keyClassSring isEqualToString:@"id"]) {
        return YES;
    }

    return [object isKindOfClass:self.keyClass];
}

- (BOOL)checkValueObject:(id)object
{
    if (object && [self.valueClassSring isEqualToString:@"id"]) {
        return YES;
    }

    return [object isKindOfClass:self.valueClass];
}

@end

@implementation NSCache (TZVector)

- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id)key
{
    if (obj) {
        [self setObject:obj forKey:key];
    } else {
        [self removeObjectForKey:key];
    }
}

@end

@implementation NSMapTable (TZVector)

- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id)key
{
    [self setObject:obj forKey:key];
}

@end
