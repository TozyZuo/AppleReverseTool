//
//  ARTVisitor.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/29.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "CDVisitor.h"

NS_ASSUME_NONNULL_BEGIN

@class ARTDataController, CDOCClass, CDOCProtocol;

@interface ARTVisitor : CDVisitor
@property (readonly) NSMutableDictionary<NSString *, CDOCClass *> *classesByClassStringInMainFile;
@property (readonly) NSMutableDictionary<NSString *, CDOCClass *> *classesByClassString;
@property (readonly) NSMutableDictionary<NSString *, CDOCProtocol *> *protocolsByProtocolString;

- (instancetype)initWithDataController:(ARTDataController *)dataController progress:(void (^ _Nullable)(NSString * _Nullable framework, NSString * _Nullable class, NSString * _Nullable ivar))progress;
@end

NS_ASSUME_NONNULL_END
