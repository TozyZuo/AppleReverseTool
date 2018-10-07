//
//  ARTClass.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/29.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRNode.h"

NS_ASSUME_NONNULL_BEGIN

//@protocol ARTNode;
@class CDOCClass, ARTiVar;

@interface ARTClass : NSObject
<ARTNode>
@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong) NSString *superClassName;
@property (nonatomic, strong) NSString *bundleName;
@property (nonatomic, assign) BOOL isInsideMainBundle;
@property (nonatomic, strong) NSArray<ARTiVar *> *iVars;
- (instancetype)initWithClass:(CDOCClass *)class bundleName:(NSString *)bundleName;
@end

NS_ASSUME_NONNULL_END
