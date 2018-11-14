//
//  NSMenu+TZCategory.m
//  Rcode
//
//  Created by TozyZuo on 2018/11/14.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "NSMenu+TZCategory.h"
#import <objc/runtime.h>

@implementation NSMenu (TZCategory)

+ (NSMenu *)menuWithTitle:(NSString *)title itemsUsingBlock:(id)firstArg, ...
{
    NSMutableArray *items = [[NSMutableArray alloc] init];
    va_list args;
    va_start(args, firstArg);
    for (id arg = firstArg; arg != nil; arg = va_arg(args, id))
    {
        BOOL isAlternate = NO;
        if (arg == NSMenuAlternateMark) {
            isAlternate = YES;
            arg = va_arg(args, id);
        }

        if ([arg isKindOfClass:[NSString class]])
        {
            NSMenuItem *item;
            if ([arg hasPrefix:NSMenuSeparatorItem]) {
                item = [NSMenuItem separatorItem];
            } else {
                item = [[NSMenuItem alloc] initWithTitle:arg userInfo:va_arg(args, id) block:va_arg(args, id)];;
            }
            item.alternate = isAlternate;
            [items addObject:item];
        }
        else if ([arg isKindOfClass:[NSMenu class]])
        {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[arg title] action:nil keyEquivalent:@""];
            item.submenu = arg;
            item.alternate = isAlternate;
            [items addObject:item];
        }
        else
        {
            [NSException raise:NSInvalidArgumentException format:@"Only accept strings and menus."];
        }
    }
    va_end(args);

    return [self menuWithTitle:title items:items];
}

+ (instancetype)menuWithTitle:(NSString *)title items:(NSArray<NSMenuItem *> *)items
{
    NSMenu *menu = nil;
    if (items.count) {
        menu = [[NSMenu alloc] initWithTitle:title];
        [menu addItems:items];
    }
    return menu;
}

- (void)addItems:(NSArray<NSMenuItem *> *)items
{
    for (NSMenuItem *item in items) {
        NSAssert([item isKindOfClass:[NSMenuItem class]], @"the elements must be NSMenuItem!");
        [self addItem:item];
    }
}

@end

static NSString * const NSEventModifierFlagSymbols = @"⌘⌥⇧^";
static NSCharacterSet *NSEventModifierFlagSymbolSet;

static const NSEventModifierFlags NSEventModifierFlagTable[] =
{
    NSEventModifierFlagCommand,
    NSEventModifierFlagOption,
    NSEventModifierFlagShift,
    NSEventModifierFlagControl,
};

NSString * const NSMenuSeparatorItem = @"---";
NSString * const NSMenuAlternateMark = @"NSMenuAlternateMark";

@implementation NSMenuItem (TZCategory)

+ (void)load
{
    NSEventModifierFlagSymbolSet = [NSCharacterSet characterSetWithCharactersInString:NSEventModifierFlagSymbols];
}

- (instancetype)initWithTitle:(NSString *)title userInfo:(id)userInfo block:(void (^)(NSMenuItem * _Nonnull))block
{
    if ([title hasPrefix:NSMenuSeparatorItem]) {
        return [NSMenuItem separatorItem];
    }
    if (self = [self initWithTitle:@"" action:@selector(blockAction:) keyEquivalent:@""])
    {
        self.target = self;
        if (block) self.actionBlock = block;

        NSArray *itemParts = [title componentsSeparatedByString:@" "];

        self.title = itemParts.firstObject;
        self.representedObject = userInfo;

        if (itemParts.count != 1) {
            NSString *hotKey = itemParts.lastObject;
            self.keyEquivalentModifierMask = [self modifierMaskFromString:hotKey];
            self.keyEquivalent = [hotKey stringByTrimmingCharactersInSet:NSEventModifierFlagSymbolSet].lowercaseString;
        }
    }
    return self;
}

- (NSEventModifierFlags)modifierMaskFromString:(NSString *)string
{
    NSEventModifierFlags modifierMask = 0;
    for (NSUInteger i = 0; i < string.length; i++) {
        NSString *symbol = [string substringWithRange:NSMakeRange(i, 1)];
        NSRange symbolRange = [NSEventModifierFlagSymbols rangeOfString:symbol];
        if (symbolRange.length) {
            modifierMask |= NSEventModifierFlagTable[symbolRange.location];
        }
    }
    return modifierMask;
}

- (void)blockAction:(NSMenuItem *)item
{
    void (^block)(NSMenuItem *item) = self.actionBlock;
    if (block) {
        block(self);
    }
}

const void *NSMenuItemActionBlockKey = &NSMenuItemActionBlockKey;

- (void (^)(NSMenuItem *item))actionBlock
{
    return objc_getAssociatedObject(self, NSMenuItemActionBlockKey);
}

- (void)setActionBlock:(void (^)(NSMenuItem *item))block
{
    objc_setAssociatedObject(self, NSMenuItemActionBlockKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
