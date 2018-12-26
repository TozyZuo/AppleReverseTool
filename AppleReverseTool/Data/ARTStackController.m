//
//  ARTStackController.m
//  Rcode
//
//  Created by TozyZuo on 2018/12/18.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTStackController.h"

@interface ARTStackController ()
@property (nonatomic, strong) NSMutableArray *stack;
@property (nonatomic, strong) NSMutableArray *internalMenuStack;
@property (nonatomic, assign) BOOL canGoBack;
@property (nonatomic, assign) BOOL canGoForward;
@property (nonatomic, assign) NSInteger index;
@end

@implementation ARTStackController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.stack = [[NSMutableArray alloc] init];
        self.internalMenuStack = [[NSMutableArray alloc] init];
        self.maxCount = ULONG_MAX;
        self.index = -1;
    }
    return self;
}

#pragma mark Private

- (void)willChangeStack
{

}

- (void)didChangeStack
{
    // trigger button state change
    self.canGoBack = self.canGoBack;
    self.canGoForward = self.canGoForward;
}

- (void)menuStackHandleObject:(id)object
{
    [self.internalMenuStack removeObject:object];
    [self.internalMenuStack addObject:object];
}

#pragma mark - Public

- (BOOL)canGoBack
{
    return self.index - 1 >= 0;
}

- (BOOL)canGoForward
{
    return self.index + 1 < self.stack.count;
}

- (id)currentObject
{
    return self[self.index];
}

- (NSArray *)menuStack
{
    return self.internalMenuStack;
}

- (void)push:(id)object
{
    if (!object) {
        return;
    }

    [self willChangeStack];

    [self menuStackHandleObject:object];

    while (self.index < self.stack.count - 1) {
        [self.stack removeLastObject];
    }
    [self.stack addObject:object];
    if (self.stack.count > self.maxCount) {
        [self.stack removeObjectAtIndex:0];
        // menuStack?
    }
//    self.index = self.index + 1;
    self.index = self.stack.count - 1;

    [self didChangeStack];
}

- (id)goBack
{
    if (self.canGoBack) {
        return [self goToIndex:self.index - 1];
    }
    return nil;
}

- (id)goForward
{
    if (self.canGoForward) {
        return [self goToIndex:self.index + 1];
    }
    return nil;
}

- (id)goToIndex:(NSInteger)index
{
    if (index >= 0 && index < self.stack.count) {
        [self willChangeStack];

        self.index = index;
        id object = self.stack[index];
        [self menuStackHandleObject:object];

        [self didChangeStack];

        return object;
    }
    return nil;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    return self.stack[idx];
}

#pragma mark NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id  _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len
{
    return [self.stack countByEnumeratingWithState:state objects:buffer count:len];
}

@end
