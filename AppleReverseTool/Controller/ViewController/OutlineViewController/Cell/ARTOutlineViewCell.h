//
//  ARTOutlineViewCell.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTOutlineViewCell, ARTClass, CDOCClass;

@protocol ARTOutlineViewCellDelegate <NSObject>
@optional
- (void)outlineViewCell:(ARTOutlineViewCell *)outlineViewCell didClickLinkWithURL:(NSURL *)url rightMouse:(BOOL)rightMouse;
@end

@interface ARTOutlineViewCell : NSView
@property (nonatomic, weak) id<ARTOutlineViewCellDelegate> delegate;
@property (nonatomic, weak) NSOutlineView *outlineView;
@property (nonatomic, weak, readonly) CDOCClass *data;
- (void)updateData:(CDOCClass *)data;
@end

NS_ASSUME_NONNULL_END
