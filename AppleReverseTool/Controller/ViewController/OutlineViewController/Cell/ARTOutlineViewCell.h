//
//  ARTOutlineViewCell.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTOutlineViewCell, CDOCProtocol, CDOCClass, CDOCCategory;

@protocol ARTOutlineViewCellDelegate <NSObject>
@optional
- (void)outlineViewCell:(ARTOutlineViewCell *)outlineViewCell didClickLink:(NSString *)link rightMouse:(BOOL)rightMouse;
@end

@interface ARTOutlineViewCell : NSView
@property (nonatomic,   weak  ) id<ARTOutlineViewCellDelegate> delegate;
@property (nonatomic,   weak  ) NSOutlineView *outlineView;
@property (nonatomic, readonly) __kindof CDOCProtocol *data;
- (void)updateDataWithClass:(CDOCClass *)class;
- (void)updateDataWithCategory:(CDOCCategory *)category;
@end

NS_ASSUME_NONNULL_END
