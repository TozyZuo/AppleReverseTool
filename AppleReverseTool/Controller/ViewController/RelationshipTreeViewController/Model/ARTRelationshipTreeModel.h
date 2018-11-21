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
@property (nonatomic,  weak  ) ARTRelationshipTreeModel *superNode;
@property (nonatomic,readonly) NSArray<ARTRelationshipTreeModel *> *subNodes;
@property (nonatomic, assign ) BOOL hideUnexpandedVariables;
@property (nonatomic,readonly) BOOL canBeExpanded;
@property (nonatomic,readonly) CDOCClass *classData;
@property (nonatomic,readonly) CDOCInstanceVariable *iVarData;
- (instancetype)initWithData:(id)data dataController:(ARTDataController *)dataController;
- (void)createSubNodes;
- (void)recreateSubNodesForcibly:(BOOL)force;
@end
NS_ASSUME_NONNULL_END
