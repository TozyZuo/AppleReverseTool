//
//  ARTClassTreeCell.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTClassTreeCell, CDOCProtocol, CDOCClass, CDOCCategory;

@protocol ARTClassTreeCellDelegate <NSObject>
@optional
- (void)classTreeCell:(ARTClassTreeCell *)classTreeCell didClickLink:(NSString *)link rightMouse:(BOOL)rightMouse;
@end

@interface ARTClassTreeCell : NSView
@property (nonatomic,   weak  ) id<ARTClassTreeCellDelegate> delegate;
@property (nonatomic,   weak  ) NSOutlineView *outlineView;
@property (nonatomic, readonly) __kindof CDOCProtocol *data;
- (void)updateDataWithClass:(CDOCClass *)class;
- (void)updateDataWithCategory:(CDOCCategory *)category;
@end

NS_ASSUME_NONNULL_END
