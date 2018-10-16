//
//  ClassDumpHook.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/1.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ClassDumpHook.h"
#import "ClassDumpExtension.h"
#import "CDMachOFile.h"
#import "CDOCClassReference.h"
#import "CDTypeLexer.h"
#import "ARTDataController.h"

void *_dispatch_queue_userInfo_key = &_dispatch_queue_userInfo_key;

@implementation CDObjectiveCProcessor (ARTDataController)

- (void)hook_process
{
    void *userInfoAddress = dispatch_get_specific(_dispatch_queue_userInfo_key);
    __unsafe_unretained NSMutableDictionary *userInfo = (__bridge NSMutableDictionary *)(userInfoAddress);

    NSString *framework = self.machOFile.filename.lastPathComponent;
    userInfo[@"framework"] = framework;

    void (^ _Nullable progress)(ARTDataControllerProcessState, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable) = userInfo[@"progress"];
    if (progress) {
        progress(ARTDataControllerProcessStateProcessingData, framework, nil, nil, nil);
    }
    [self hook_process];
}

- (void)hook_registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase
{
    void *userInfoAddress = dispatch_get_specific(_dispatch_queue_userInfo_key);
    __unsafe_unretained NSMutableDictionary *userInfo = (__bridge NSMutableDictionary *)(userInfoAddress);

    NSString *framework = self.machOFile.filename.lastPathComponent;
    userInfo[@"framework"] = framework;

    void (^ _Nullable progress)(ARTDataControllerProcessState, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable) = userInfo[@"progress"];
    if (progress) {
        progress(ARTDataControllerProcessStateProcessingType, framework, nil, nil, nil);
    }
    [self hook_registerTypesWithObject:typeController phase:phase];
}

@end

@implementation CDOCProtocol (ARTDataController)

- (void)hook_setName:(NSString *)name
{
    void *userInfoAddress = dispatch_get_specific(_dispatch_queue_userInfo_key);
    __unsafe_unretained NSMutableDictionary *userInfo = (__bridge NSMutableDictionary *)(userInfoAddress);

    userInfo[@"class"] = name;

    void (^ _Nullable progress)(ARTDataControllerProcessState, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable) = userInfo[@"progress"];
    if (progress) {
        progress(ARTDataControllerProcessStateProcessingData, userInfo[@"framework"], name, nil, nil);
    }

    [self hook_setName:name];
}

- (void)hook_registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase
{
    void *userInfoAddress = dispatch_get_specific(_dispatch_queue_userInfo_key);
    __unsafe_unretained NSMutableDictionary *userInfo = (__bridge NSMutableDictionary *)(userInfoAddress);

    userInfo[@"class"] = self.name;

    void (^ _Nullable progress)(ARTDataControllerProcessState, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable) = userInfo[@"progress"];
    if (progress) {
        progress(ARTDataControllerProcessStateProcessingType, userInfo[@"framework"], self.name, nil, nil);
    }

    [self hook_registerTypesWithObject:typeController phase:phase];
}

@end

@implementation CDOCCategory (ARTDataController)

- (void)hook_setClassRef:(CDOCClassReference *)ref
{
    void *userInfoAddress = dispatch_get_specific(_dispatch_queue_userInfo_key);
    __unsafe_unretained NSMutableDictionary *userInfo = (__bridge NSMutableDictionary *)(userInfoAddress);

    NSString *class = [NSString stringWithFormat:@"%@(%@)", ref.className, self.name];
    userInfo[@"class"] = class;

    void (^ _Nullable progress)(ARTDataControllerProcessState, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable) = userInfo[@"progress"];
    if (progress) {
        progress(ARTDataControllerProcessStateProcessingData, userInfo[@"framework"], class, nil, nil);
    }

    [self hook_setClassRef:ref];
}

@end

@implementation CDOCInstanceVariable (ARTDataController)

- (id)hook_initWithName:(NSString *)name typeString:(NSString *)typeString offset:(NSUInteger)offset
{
    void *userInfoAddress = dispatch_get_specific(_dispatch_queue_userInfo_key);
    __unsafe_unretained NSMutableDictionary *userInfo = (__bridge NSMutableDictionary *)(userInfoAddress);

    void (^ _Nullable progress)(ARTDataControllerProcessState, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable) = userInfo[@"progress"];
    if (progress) {
        progress(ARTDataControllerProcessStateProcessingData, userInfo[@"framework"], userInfo[@"class"], name, nil);
    }
    return [self hook_initWithName:name typeString:typeString offset:offset];
}

@end

@implementation CDMethodType (ARTDataController)

- (id)hook_initWithType:(CDType *)type offset:(NSString *)offset
{
    void *userInfoAddress = dispatch_get_specific(_dispatch_queue_userInfo_key);
    __unsafe_unretained NSMutableDictionary *userInfo = (__bridge NSMutableDictionary *)(userInfoAddress);

    void (^ _Nullable progress)(ARTDataControllerProcessState, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable) = userInfo[@"progress"];
    if (progress) {
        progress(ARTDataControllerProcessStateProcessingType, userInfo[@"framework"], userInfo[@"class"], nil, type.typeName.name);
    }

    return [self hook_initWithType:type offset:offset];
}

@end

@implementation CDTypeController (ARTDataController)

- (void)hook_workSomeMagic
{
    void *userInfoAddress = dispatch_get_specific(_dispatch_queue_userInfo_key);
    __unsafe_unretained NSMutableDictionary *userInfo = (__bridge NSMutableDictionary *)(userInfoAddress);

    void (^ _Nullable progress)(ARTDataControllerProcessState, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable) = userInfo[@"progress"];
    if (progress) {
        progress(ARTDataControllerProcessStateProcessingStructsAndUnions, nil, nil, nil, nil);
    }

    return [self hook_workSomeMagic];
}

@end
