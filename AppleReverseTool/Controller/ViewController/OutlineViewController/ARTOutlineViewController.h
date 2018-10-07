//
//  ARTOutlineViewController.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/1.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class ARTClass, ARTOutlineViewController, CDOCClass;

@protocol ARTOutlineViewControllerDelegate <NSObject>
@optional
- (void)outlineViewController:(ARTOutlineViewController *)outlineViewController didClickItem:(CDOCClass *)item url:(NSURL *)url rightMouse:(BOOL)rightMouse;
@end

@interface ARTOutlineViewController : ARTViewController
@property (nonatomic, weak) id<ARTOutlineViewControllerDelegate> delegate;
- (void)updateData:(NSArray<CDOCClass *> *)data;
@end

NS_ASSUME_NONNULL_END
