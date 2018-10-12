//
//  ARTRelationshipTreeViewController.h
//  Rcode
//
//  Created by TozyZuo on 2018/10/12.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class ARTRelationshipTreeViewController, CDOCClass, ARTDataController;

@protocol ARTRelationshipTreeViewControllerDelegate <NSObject>
@optional
- (void)relationshipTreeViewController:(ARTRelationshipTreeViewController *)relationshipTreeViewController didClickItem:(id)item link:(NSString *)link rightMouse:(BOOL)rightMouse;
@end

@interface ARTRelationshipTreeViewController : ARTViewController
@property (nonatomic, weak) ARTDataController *dataController;
@property (nonatomic, weak) id<ARTRelationshipTreeViewControllerDelegate> delegate;
- (void)updateData:(NSArray<CDOCClass *> *)data;
@end

NS_ASSUME_NONNULL_END
