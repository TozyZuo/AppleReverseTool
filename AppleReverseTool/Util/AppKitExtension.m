//
//  AppKitExtension.m
//  Rcode
//
//  Created by TozyZuo on 2018/11/5.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

@implementation NSObject (AppKitExtension)

BOOL ClassImplementedSelector(Class aClass, SEL aSelector)
{
    if ([aClass instancesRespondToSelector:aSelector]) {
        IMP imp = method_getImplementation(class_getInstanceMethod(aClass, aSelector));
        IMP superIMP = method_getImplementation(class_getInstanceMethod(class_getSuperclass(aClass), aSelector));
        return (!superIMP && imp) || (imp != superIMP);
    }
    return NO;
}

+ (BOOL)implementedSelector:(SEL)aSelector
{
    return ClassImplementedSelector(object_getClass(self), aSelector);
}

+ (BOOL)instancesImplementedSelector:(SEL)aSelector
{
    return ClassImplementedSelector(self, aSelector);
}

- (BOOL)implementedSelector:(SEL)aSelector
{
    return ClassImplementedSelector(self.class, aSelector);
}

@end

@implementation NSView (AppKitExtension)

+ (void)load
{
    if ([self instancesImplementedSelector:@selector(description)]) {
        method_exchangeImplementations(class_getInstanceMethod(self, @selector(description)), class_getInstanceMethod(self, @selector(description_AppKitExtension)));
    } else {
        Method description_AppKitExtension = class_getInstanceMethod(self, @selector(description_AppKitExtension));
        class_addMethod(self, @selector(description), method_getImplementation(description_AppKitExtension), method_getTypeEncoding(description_AppKitExtension));
    }
}

- (NSString *)description_AppKitExtension
{
    static NSMutableDictionary<Class, NSNumber *> *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSMutableDictionary alloc] init];
    });

    NSNumber *implementedDescription = cache[self.class];

    if (!implementedDescription) {
        implementedDescription = @(method_getImplementation(class_getInstanceMethod(self.class, @selector(description))) != method_getImplementation(class_getInstanceMethod(self.class, @selector(description_AppKitExtension))));
        cache[(id)self.class] = implementedDescription;
    }

    NSMutableString *str;

    if (implementedDescription.boolValue) {
        str = [self description_AppKitExtension].mutableCopy;
    } else {
        str = super.description.mutableCopy;
    }

    [str appendString:@"["];
    [str appendFormat:@"frame = %@; ", NSStringFromRect(self.frame)];
    [str appendString:self.descriptionAppendTextIfApplicable];
    if (!self.wantsDefaultClipping) [str appendString:@"wantsDefaultClipping = NO; "];
    if (self.alphaValue != 1) [str appendFormat:@"alphaValue = %g; ", self.alphaValue];
    if (self.hidden) [str appendString:@"hidden = YES; "];
    if (self.isOpaque) [str appendString:@"opaque = YES; "];
    [str appendString:self.descriptionAutoresizing];
    if (!self.autoresizesSubviews) [str appendString:@"autoresizesSubviews = NO; "];
    if (!self.tag)  [str appendFormat:@"tag = %ld; ", self.tag];
    if (self.gestureRecognizers.count) [str appendFormat:@"gestureRecognizers(%lu) = <NSArray: %p>; ", self.gestureRecognizers.count,  self.gestureRecognizers];
    if (self.trackingAreas.count) [str appendFormat:@"trackingAreas(%lu) = <NSArray: %p>; ", self.trackingAreas.count, self.trackingAreas];
    if (self.layer) [str appendFormat:@"layer = %@; ", self.layer];
    [str deleteCharactersInRange:NSMakeRange(str.length - 2, 2)];
    [str appendString:@"]"];
    return str;
}

- (NSString *)descriptionAppendTextIfApplicable
{
    NSString *text = nil;

TZWarningIgnore(-Wundeclared-selector)
    if ([self respondsToSelector:@selector(text)]) {
        id t = [self performSelector:@selector(text)];
TZWarningIgnoreEnd
        if ([t isKindOfClass:NSString.class]) {
            text = t;
        }
        if (text) {
            if (text.length >= 0x1a) {
                text = [text substringWithRange:[text rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, 0x1a)]];
                text = [text stringByAppendingString:@"..."];
            }
            text = [NSString stringWithFormat:@"text = '%@'; ", text];
        }
    }
    return text ?: @"";
}

- (NSString *)descriptionAutoresizing
{
    NSAutoresizingMaskOptions mask = self.autoresizingMask;

    NSMutableString *str = [NSMutableString string];

    if ((mask & NSViewMinXMargin)) {
        [str appendString:@"MinX+"];
    }
    if ((mask & NSViewWidthSizable)) {
        [str appendString:@"W+"];
    }
    if ((mask & NSViewMaxXMargin)) {
        [str appendString:@"MaxX+"];
    }
    if ((mask & NSViewMinYMargin)) {
        [str appendString:@"MinY+"];
    }
    if ((mask & NSViewHeightSizable)) {
        [str appendString:@"H+"];
    }
    if ((mask & NSViewMaxYMargin)) {
        [str appendString:@"MaxY+"];
    }

    if (str.length) {
        [str deleteCharactersInRange:NSMakeRange(str.length - 1, 1)];
    }
    else {
        [str appendString:@"none"];
    }

    return [NSString stringWithFormat:@"autoresize = %@; ", str];
}

@end
