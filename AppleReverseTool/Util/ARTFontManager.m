//
//  ARTFontManager.m
//  Rcode
//
//  Created by TozyZuo on 2018/10/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTFontManager.h"
#import "ARTWeakObjectWrapper.h"

static NSString * const NSFontManagerSelectedFontKey = @"NSFontManagerSelectedFontKey";
static NSString * const NSFontManagerFontChangeBlockKey = @"NSFontManagerFontChangeBlockKey";

@interface NSFontManager (ART)
- (id)_init;
@end

@interface ARTFontManager ()
@property (strong) NSMutableArray<ARTWeakObjectWrapper *> *observers;
@end

@implementation ARTFontManager
@dynamic sharedFontManager;

+ (void)load
{
    [NSFontManager setFontManagerFactory:self];
}

- (instancetype)_init
{
    self = [super _init];
    if (self) {
        self.observers = [[NSMutableArray alloc] init];
        NSData *fontData = NSUserDefaults.standardUserDefaults[NSFontManagerSelectedFontKey];
        if (!fontData) {
            fontData = [NSKeyedArchiver archivedDataWithRootObject:[NSFont fontWithName:@"Menlo-Regular" size:18]];
            NSUserDefaults.standardUserDefaults[NSFontManagerSelectedFontKey] = fontData;
        }
        [super setSelectedFont:[NSKeyedUnarchiver unarchiveObjectWithData:fontData] isMultiple:NO];
    }
    return self;
}

- (void)setSelectedFont:(NSFont *)fontObj isMultiple:(BOOL)flag
{
    [super setSelectedFont:fontObj isMultiple:flag];
    NSUserDefaults.standardUserDefaults[NSFontManagerSelectedFontKey] = [NSKeyedArchiver archivedDataWithRootObject:fontObj];
}

- (void)setTarget:(id)target
{

}

- (void)addObserver:(id)observer fontChangeBlock:(void (^)(NSFont * _Nonnull (^ _Nonnull)(NSFont * _Nonnull)))block
{
    if (observer && block) {
        observer[NSFontManagerFontChangeBlockKey] = [block copy];
        [self.observers addObject:[[ARTWeakObjectWrapper alloc] initWithTarget:observer]];

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            super.target = self;
        });
    }
}

- (void)changeFont:(id)sender
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
