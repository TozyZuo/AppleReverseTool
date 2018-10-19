//
//  ARTFontManager.m
//  Rcode
//
//  Created by TozyZuo on 2018/10/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTFontManager.h"
#import "ARTWeakObjectWrapper.h"

static NSString * const NSFontManagerFontChangeBlockKey = @"NSFontManagerFontChangeBlockKey";

@interface NSFontManager (ARTPrivate)
@property (readonly) NSMutableArray<ARTWeakObjectWrapper *> *observers;
@end

@implementation NSFontManager (ART)

- (NSMutableArray *)observers
{
    NSMutableArray *observers = self[ARTAssociatedKeyForSelector(_cmd)];
    if (!observers) {
        observers = [[NSMutableArray alloc] init];
        self[ARTAssociatedKeyForSelector(_cmd)] = observers;
    }
    return observers;
}

- (void)addObserver:(id)observer fontChangeBlock:(void (^)(NSFont * _Nonnull (^ _Nonnull)(NSFont * _Nonnull)))block
{
    if (observer && block) {
        observer[NSFontManagerFontChangeBlockKey] = [block copy];
        [self.observers addObject:[[ARTWeakObjectWrapper alloc] initWithTarget:observer]];

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            self.target = self;
            self.action = @selector(handleFontChange:);
        });
    }
}

- (void)handleFontChange:(id)sender
{
    static NSFont *(^updateFontBlock)(NSFont *);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        updateFontBlock = ^(NSFont *font) {
            return [self convertFont:font];
        };
    });

    NSMutableArray *observers = self.observers;
    for (ARTWeakObjectWrapper *wrapper in observers.copy) {
        if (wrapper.target) {
            void (^fontChangeBlock)(NSFont *(^)(NSFont *)) = wrapper.target[NSFontManagerFontChangeBlockKey];
            fontChangeBlock(updateFontBlock);
        } else {
            [observers removeObject:wrapper];
        }
    }
}

@end

@implementation ARTFontManager

@end
