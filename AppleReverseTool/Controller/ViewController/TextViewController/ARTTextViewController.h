//
//  ARTTextViewController.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/1.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CDOCProtocol, CDTypeController, ARTTextViewController, ARTDataController;

@protocol ARTTextViewControllerDelegate <NSObject>
@optional
- (void)textViewController:(ARTTextViewController *)textViewController didClickLink:(NSString *)link rightMouse:(BOOL)rightMouse;
@end

@interface ARTTextViewController : ARTViewController
@property (nonatomic, weak) id<ARTTextViewControllerDelegate> delegate;
@property (nonatomic, weak) ARTDataController *dataController;
- (void)updateDataWithLink:(NSString *)link;
@end

NS_ASSUME_NONNULL_END
