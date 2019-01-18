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

#define ImplementCategory(class, categoryName, property, ...)\
_ImplementCategory(class, categoryName, property, __VA_ARGS__)

#define TZVectorForbidInheriting __attribute__((objc_subclassing_restricted))

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

TZVectorForbidInheriting
@interface TZMapVector<K, V> : NSMutableDictionary<K, V>
<TZVectorProtocol>
@end

@interface NSCache<K, V> (TZVector)
- (nullable V)objectForKeyedSubscript:(K)key;
- (void)setObject:(nullable V)obj forKeyedSubscript:(K)key;
@end

TZVectorForbidInheriting
@interface TZCacheVector<K, V> : NSCache<K, V>
<TZVectorProtocol>
@end

@interface NSMapTable<K, V> (TZVector)
- (nullable V)objectForKeyedSubscript:(K)key;
- (void)setObject:(nullable V)obj forKeyedSubscript:(K)key;
@end

TZVectorForbidInheriting
@interface TZMapTableVector<K, V> : NSMapTable<K, V>
<TZVectorProtocol>
@end

#pragma mark - Array

TZVectorForbidInheriting
@interface TZArrayVector<T> : NSMutableArray<T>
<TZVectorProtocol>
- (void)sortUsingComparator:(NSComparisonResult (^NS_NOESCAPE)(T obj1, T obj2))cmptr ;
@end

TZVectorForbidInheriting
@interface TZOrderedSetVector<T> : NSMutableOrderedSet<T>
<TZVectorProtocol>
@end

#pragma mark - Set

TZVectorForbidInheriting
@interface TZSetVector<T> : NSMutableSet<T>
<TZVectorProtocol>
@end

TZVectorForbidInheriting
@interface TZCountedSetVector<T> : NSCountedSet<T>
<TZVectorProtocol>
@end

TZVectorForbidInheriting
@interface TZHashTableVector<T> : NSHashTable<T>
<TZVectorProtocol>
@end


NS_ASSUME_NONNULL_END


#define IgnoreWarning(...) IgnoreWarnings(__VA_ARGS__, 5, 4, 3, 2, 1)
#define IgnoreWarnings(_1, _2, _3, _4, _5, N, ...) _IgnoreWarnings(N, _1, _2, _3, _4, _5)
#define _IgnoreWarnings(count, args...) IgnoreWarning ## count(args)

#define IgnoreWarningEnd _Pragma("clang diagnostic pop")

#define IgnoreWarningHelper0(x) #x
#define IgnoreWarningHelper1(x) IgnoreWarningHelper0(clang diagnostic ignored x)
#define IgnoreWarningHelper2(y) IgnoreWarningHelper1(#y)

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

OBJC_EXPORT Class objc_getClass(const char *name);
OBJC_EXPORT IMP class_getMethodImplementation(Class cls, SEL name);
OBJC_EXPORT SEL sel_registerName(const char *str);
OBJC_EXPORT BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types);
extern Class TargetVectorClassForClass(Class cls);

#define ImplementCategoryBegin(class, categoryName)\
IgnoreWarning(-Wincomplete-implementation, -Wobjc-property-implementation)\
@implementation class (categoryName)\
\
+ (void)load\
{\
    char *key, buf[64], lo, hi;\
    size_t size;\
    SEL getter, setter;\
    Class targetClass = TargetVectorClassForClass(self);\
    Class stubClass = objc_getClass("TZVector");\
    IMP impGetter = class_getMethodImplementation(stubClass, sel_registerName("stub_value"));\
    IMP impSetter = class_getMethodImplementation(stubClass, sel_registerName("stub_setValue:"));

#ifdef DEBUG
#define CheckProperty(_class, _p) ((void)(((_class *)(nil))._p), # _p)
#else
#define CheckProperty(_class, _p) (# _p)
#endif

#define ImplementProperty(_class, _p)\
    key =  CheckProperty(_class, _p);\
    size = strlen(key);\
    NSAssert(size < 60, @"name `%s` is too long.", key);\
    strncpy(buf, "set", 3);\
    strncpy(&buf[3], key, size);\
    lo = buf[3];\
    hi = islower(lo) ? toupper(lo) : lo;\
    buf[3] = hi;\
    buf[size + 3] = ':';\
    buf[size + 4] = '\0';\
    getter = sel_registerName(key);\
    setter = sel_registerName(buf);\
    if (!class_addMethod(targetClass, getter, impGetter, "@@:")) {\
        NSLog(@"TZVector: auto implement method `%s` failed in %s(%s).", key, #_class, #_p);\
    }\
    if (!class_addMethod(targetClass, setter, impSetter, "v@:@")) {\
        NSLog(@"TZVector: auto implement method `%s` failed in %s(%s).", buf, #_class, #_p);\
    }

#define ImplementCategoryEnd \
}\
@end \
IgnoreWarningEnd

#define _ImplementCategory(class, categoryName, property, ...)\
ImplementCategoryHelper0(class, categoryName, property, __VA_ARGS__, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1)

#define ImplementCategoryHelper0(class, categoryName, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, N, ...)\
ImplementCategoryHelper1(class, categoryName, N, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)

#define ImplementCategoryHelper1(class, categoryName, count, properties...)\
ImplementCategory ## count(class, categoryName, properties)

#define ImplementCategory1(class, categoryName, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)\
ImplementCategoryBegin(class, categoryName)\
ImplementProperty(class, p1)\
ImplementCategoryEnd

#define ImplementCategory2(class, categoryName, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)\
ImplementCategoryBegin(class, categoryName)\
ImplementProperty(class, p1)\
ImplementProperty(class, p2)\
ImplementCategoryEnd

#define ImplementCategory3(class, categoryName, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)\
ImplementCategoryBegin(class, categoryName)\
ImplementProperty(class, p1)\
ImplementProperty(class, p2)\
ImplementProperty(class, p3)\
ImplementCategoryEnd

#define ImplementCategory4(class, categoryName, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)\
ImplementCategoryBegin(class, categoryName)\
ImplementProperty(class, p1)\
ImplementProperty(class, p2)\
ImplementProperty(class, p3)\
ImplementProperty(class, p4)\
ImplementCategoryEnd

#define ImplementCategory5(class, categoryName, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)\
ImplementCategoryBegin(class, categoryName)\
ImplementProperty(class, p1)\
ImplementProperty(class, p2)\
ImplementProperty(class, p3)\
ImplementProperty(class, p4)\
ImplementProperty(class, p5)\
ImplementCategoryEnd

#define ImplementCategory6(class, categoryName, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)\
ImplementCategoryBegin(class, categoryName)\
ImplementProperty(class, p1)\
ImplementProperty(class, p2)\
ImplementProperty(class, p3)\
ImplementProperty(class, p4)\
ImplementProperty(class, p5)\
ImplementProperty(class, p6)\
ImplementCategoryEnd

#define ImplementCategory7(class, categoryName, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)\
ImplementCategoryBegin(class, categoryName)\
ImplementProperty(class, p1)\
ImplementProperty(class, p2)\
ImplementProperty(class, p3)\
ImplementProperty(class, p4)\
ImplementProperty(class, p5)\
ImplementProperty(class, p6)\
ImplementProperty(class, p7)\
ImplementCategoryEnd

#define ImplementCategory8(class, categoryName, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)\
ImplementCategoryBegin(class, categoryName)\
ImplementProperty(class, p1)\
ImplementProperty(class, p2)\
ImplementProperty(class, p3)\
ImplementProperty(class, p4)\
ImplementProperty(class, p5)\
ImplementProperty(class, p6)\
ImplementProperty(class, p7)\
ImplementProperty(class, p8)\
ImplementCategoryEnd

#define ImplementCategory9(class, categoryName, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)\
ImplementCategoryBegin(class, categoryName)\
ImplementProperty(class, p1)\
ImplementProperty(class, p2)\
ImplementProperty(class, p3)\
ImplementProperty(class, p4)\
ImplementProperty(class, p5)\
ImplementProperty(class, p6)\
ImplementProperty(class, p7)\
ImplementProperty(class, p8)\
ImplementProperty(class, p9)\
ImplementCategoryEnd

#define ImplementCategory10(class, categoryName, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)\
ImplementCategoryBegin(class, categoryName)\
ImplementProperty(class, p1)\
ImplementProperty(class, p2)\
ImplementProperty(class, p3)\
ImplementProperty(class, p4)\
ImplementProperty(class, p5)\
ImplementProperty(class, p6)\
ImplementProperty(class, p7)\
ImplementProperty(class, p8)\
ImplementProperty(class, p9)\
ImplementProperty(class, p10)\
ImplementCategoryEnd
