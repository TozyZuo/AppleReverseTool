//
//  ClassDumpHook.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/1.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDObjectiveCProcessor.h"
#import "CDOCCategory.h"
#import "CDOCInstanceVariable.h"
#import "CDMethodType.h"
#import "CDTypeParser.h"
#import "CDTypeController.h"
#import "CDOCClassReference.h"

extern void *_dispatch_queue_userInfo_key;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - ARTDataController

@interface CDObjectiveCProcessor (ARTDataController)
- (void)hook_process;
- (void)hook_registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
@end

@interface CDOCProtocol (ARTDataController)
- (void)hook_setName:(NSString *)name;
- (void)hook_registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
@end

@interface CDOCCategory (ARTDataController)
- (void)hook_setClassRef:(CDOCClassReference *)ref;
@end

@interface CDOCInstanceVariable (ARTDataController)
- (id)hook_initWithName:(NSString *)name typeString:(NSString *)typeString offset:(NSUInteger)offset;
@end

@interface CDMethodType (ARTDataController)
- (id)hook_initWithType:(CDType *)type offset:(NSString *)offset;
@end

@interface CDTypeController (ARTDataController)
- (void)hook_workSomeMagic;
@end

#pragma mark - ART

@interface CDOCClassReference (ART)
- (instancetype)hook_initWithClassObject:(CDOCClass *)classObject;
@end

@interface CDOCCategory (ART)
- (NSString *)hook_className;
@end

NS_ASSUME_NONNULL_END
