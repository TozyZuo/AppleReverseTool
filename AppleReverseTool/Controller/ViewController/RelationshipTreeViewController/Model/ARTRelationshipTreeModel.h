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

typedef NS_ENUM(NSInteger, ARTRelationshipTreeModelType) {
    ARTRelationshipTreeModelTypeReference,
    ARTRelationshipTreeModelTypeReferer,
    ARTRelationshipTreeModelTypeSubclass,
};

@interface ARTRelationshipTreeModel : ARTModel
@property (nonatomic,   weak  ) ARTRelationshipTreeModel *superNode;
@property (nonatomic, readonly) NSArray<ARTRelationshipTreeModel *> *subNodes;
@property (nonatomic, readonly) NSArray<ARTRelationshipTreeModel *> *subclassNodes;
@property (nonatomic, readonly) BOOL canBeExpanded;
@property (nonatomic, readonly) BOOL canExpandeSubNodes;
@property (nonatomic, readonly) CDOCClass *classData;
@property (nonatomic, readonly) CDOCInstanceVariable *ivarData;
@property (nonatomic, readonly) ARTRelationshipTreeModelType type;
@property (nonatomic,  assign ) BOOL hideUnexpandedVariables;
@property (nonatomic,  assign ) BOOL isSubclassExpanded;
@property (nonatomic,  assign ) BOOL showHint;
- (instancetype)initWithClass:(CDOCClass *)aClass type:(ARTRelationshipTreeModelType)type dataController:(ARTDataController *)dataController;
//- (instancetype)initWithInstanceVariable:(CDOCInstanceVariable *)ivar type:(ARTRelationshipTreeModelType)type dataController:(ARTDataController *)dataController;
- (void)createSubNodes;
- (void)createSubclassNodes;
- (void)recreateSubNodesForcibly:(BOOL)force;
@end
NS_ASSUME_NONNULL_END
