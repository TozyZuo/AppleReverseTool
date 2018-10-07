//
//  ARTTextViewControllerVisitor.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/3.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "CDVisitor.h"

NS_ASSUME_NONNULL_BEGIN

@class CDTypeController, ARTDataController;
__attribute__((visibility("hidden")))
@interface ARTTextViewControllerVisitor : CDVisitor
@property (readonly) NSMutableString *resultString;
- (instancetype)initWithTypeController:(CDTypeController *)typeController dataController:(ARTDataController *)dataController;
@end

NS_ASSUME_NONNULL_END
