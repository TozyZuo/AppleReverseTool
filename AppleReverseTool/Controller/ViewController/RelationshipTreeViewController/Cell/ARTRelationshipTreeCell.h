//
//  ARTRelationshipTreeCell.h
//  Rcode
//
//  Created by TozyZuo on 2018/10/12.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTRelationshipTreeCell;

@protocol ARTRelationshipTreeCellDelegate <NSObject>
@optional
- (void)relationshipTreeCell:(ARTRelationshipTreeCell *)relationshipTreeCell didClickLink:(NSString *)link rightMouse:(BOOL)rightMouse;
@end

@interface ARTRelationshipTreeCell : NSView
@property (nonatomic,   weak  ) id<ARTRelationshipTreeCellDelegate> delegate;
@property (nonatomic,   weak  ) NSOutlineView *outlineView;
@property (nonatomic, readonly) id data;
- (void)updateData:(id)data;
@end

NS_ASSUME_NONNULL_END
