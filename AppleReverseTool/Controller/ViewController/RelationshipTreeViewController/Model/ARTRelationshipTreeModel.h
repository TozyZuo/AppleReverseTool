//
//  ARTRelationshipTreeModel.h
//  Rcode
//
//  Created by TozyZuo on 2018/10/13.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTModel.h"

NS_ASSUME_NONNULL_BEGIN

@class ARTDataController, CDOCClass, CDOCInstanceVariable;

@interface ARTRelationshipTreeModel : ARTModel
@property (  weak  ) ARTRelationshipTreeModel *superNode;
@property (readonly) NSArray<ARTRelationshipTreeModel *> *subNodes;
@property (readonly) BOOL canBeExpanded;
@property (readonly) CDOCClass *classData;
@property (readonly) CDOCInstanceVariable *iVarData;
- (instancetype)initWithData:(id)data dataController:(ARTDataController *)dataController;
- (void)createSubNodesWithHideUnexpandedVariables:(BOOL)hideUnexpandedVariables;
- (void)recreateSubNodesForcibly:(BOOL)force hideUnexpandedVariables:(BOOL)hideUnexpandedVariables;
@end
NS_ASSUME_NONNULL_END
