//
//  ARTDataController.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/28.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTController.h"

typedef NS_ENUM(NSInteger, ARTDataControllerProcessState) {
    ARTDataControllerProcessStateWillProcess,
    ARTDataControllerProcessStateProcessingData,
    ARTDataControllerProcessStateProcessingType,
    ARTDataControllerProcessStateProcessingStructsAndUnions,
    ARTDataControllerProcessStateDidProcess,
};

NS_ASSUME_NONNULL_BEGIN

@class CDOCProtocol, CDOCClass, CDTypeController;

@interface ARTDataController : ARTController
@property (nonatomic, readonly) NSArray<CDOCClass *> *relationshipNodes;
@property (nonatomic, readonly) NSArray<CDOCClass *> *classNodes;
@property (nonatomic, readonly) CDOCClass * _Nullable (^classForName)(NSString *name);
@property (nonatomic, readonly) NSDictionary<NSString *, CDOCProtocol *> *allProtocols;
@property (nonatomic, readonly) NSDictionary<NSString *, CDOCClass *> *allClasses;
@property (nonatomic, readonly) NSDictionary<NSString *, CDOCClass *> *allClassesInMainFile;
@property (nonatomic, readonly) NSString *filePath;
@property (nonatomic, readonly) CDTypeController *typeController;
- (void)processDataWithFilePath:(NSString *)filePath
                       progress:(void (^ _Nullable)(ARTDataControllerProcessState state, NSString * _Nullable framework, NSString * _Nullable class, NSString * _Nullable ivar, NSString * _Nullable type))progress
                     completion:(void (^)(ARTDataController *dataController))completion;
@end

NS_ASSUME_NONNULL_END
