//
//  ARTPickClassViewController.h
//  Rcode
//
//  Created by TozyZuo on 2018/11/28.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class ARTDataController, CDOCClass;

@interface ARTClassPickerViewController : ARTViewController
@property (readonly,  weak) NSTableView *tableView;
@property (nonatomic, weak) ARTDataController *dataController;
- (void)setFilterString:(NSString *)filterString completion:(void (^)(CDOCClass * _Nullable aClass))completion;
@end

NS_ASSUME_NONNULL_END
