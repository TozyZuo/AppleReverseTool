//
//  ARTClassTreeViewController.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/1.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class ARTClassTreeViewController, CDOCClass;

@protocol ARTClassTreeViewControllerDelegate <NSObject>
@optional
- (void)classTreeViewController:(ARTClassTreeViewController *)classTreeViewController didClickItem:(CDOCClass *)item link:(NSString *)link rightMouse:(BOOL)rightMouse;
@end

@interface ARTClassTreeViewController : ARTViewController
@property (nonatomic, weak) id<ARTClassTreeViewControllerDelegate> delegate;
- (void)updateData:(NSArray<CDOCClass *> *)data;
@end

NS_ASSUME_NONNULL_END
