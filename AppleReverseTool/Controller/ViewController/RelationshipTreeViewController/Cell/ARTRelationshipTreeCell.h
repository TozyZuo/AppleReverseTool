//
//  ARTRelationshipTreeCell.h
//  Rcode
//
//  Created by TozyZuo on 2018/10/12.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTRichTextCell.h"

NS_ASSUME_NONNULL_BEGIN

@class ARTRelationshipTreeModel, ARTDataController;

@interface ARTRelationshipTreeCell : ARTRichTextCell
@property (nonatomic,   weak  ) IBOutlet NSOutlineView *outlineView;
@property (nonatomic,   weak  ) ARTDataController *dataController;
@property (nonatomic, readonly) ARTRelationshipTreeModel *data;
- (void)updateData:(ARTRelationshipTreeModel *)data;
@end

NS_ASSUME_NONNULL_END
