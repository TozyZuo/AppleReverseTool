//
//  ARTRelationshipTreeCell.h
//  Rcode
//
//  Created by TozyZuo on 2018/10/12.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTRelationshipTreeCell, ARTRelationshipTreeModel, ARTDataController, ARTRichTextController;

@protocol ARTRelationshipTreeCellDelegate <NSObject>
@optional
- (void)relationshipTreeCell:(ARTRelationshipTreeCell *)relationshipTreeCell didClickLink:(NSString *)link rightMouse:(BOOL)rightMouse;
@end

@interface ARTRelationshipTreeCell : NSView
@property (nonatomic,   weak  ) id<ARTRelationshipTreeCellDelegate> delegate;
@property (nonatomic,   weak  ) IBOutlet NSOutlineView *outlineView;
@property (   weak  , readonly) NSTextView *textView;
@property (nonatomic, readonly) ARTRichTextController *richTextController;
@property (nonatomic,   weak  ) ARTDataController *dataController;
@property (nonatomic, readonly) ARTRelationshipTreeModel *data;
- (void)updateData:(ARTRelationshipTreeModel *)data;
@end

NS_ASSUME_NONNULL_END
