//
//  ARTRelationshipTreeModel.m
//  Rcode
//
//  Created by TozyZuo on 2018/10/13.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTRelationshipTreeModel.h"
#import "ARTDataController.h"
#import "ClassDumpExtension.h"
#import "CDOCInstanceVariable.h"

@interface ARTRelationshipTreeModel ()
@property (nonatomic,  weak ) ARTDataController *dataController;
@property (nonatomic, strong) id data;
@end

@implementation ARTRelationshipTreeModel
@synthesize subNodes = _subNodes;

- (instancetype)initWithData:(id)data dataController:(ARTDataController *)dataController
{
    self = [super init];
    if (self) {
        self.data = data;
        self.dataController = dataController;
    }
    return self;
}

- (BOOL)canBeExpanded
{
    CDOCClass *classData = self.classData;
    return classData.isInsideMainBundle ? classData.instanceVariables.count > 0 : NO;
}

- (void)createSubNodes
{
    if (!_subNodes) {
        NSMutableArray *subNodes = [[NSMutableArray alloc] init];
        for (CDOCInstanceVariable *var in self.classData.instanceVariables) {
            ARTRelationshipTreeModel *model = [[ARTRelationshipTreeModel alloc] initWithData:var dataController:self.dataController];
            model.superNode = self;
            [subNodes addObject:model];
        }
        [subNodes sortUsingComparator:^NSComparisonResult(ARTRelationshipTreeModel * _Nonnull obj1, ARTRelationshipTreeModel * _Nonnull obj2) {
            CDDetailedType detailedType1 = obj1.iVarData.type.detailedType;
            CDDetailedType detailedType2 = obj2.iVarData.type.detailedType;
            if (detailedType1 == detailedType2) {
                if (detailedType1 == CDDetailedTypeNamedObject) {
                    CDOCClass *c1 = self.dataController.classForName(obj1.iVarData.type.typeName.name);
                    CDOCClass *c2 = self.dataController.classForName(obj2.iVarData.type.typeName.name);
                    if (c1.isInsideMainBundle != c2.isInsideMainBundle) {
                        return c2.isInsideMainBundle ? NSOrderedAscending : NSOrderedDescending;
                    }
                }
                return [obj1.iVarData.name compare:obj2.iVarData.name];
            } else {
                return detailedType1 < detailedType2 ? NSOrderedAscending : NSOrderedDescending;
            }
        }];
        _subNodes = subNodes;
    }
}

- (CDOCClass *)classData
{
    if ([self.data isKindOfClass:CDOCClass.class]) {
        return self.data;
    } else if ([self.data isKindOfClass:CDOCInstanceVariable.class]) {
        CDOCInstanceVariable *var =(CDOCInstanceVariable *)self.data;
        return self.dataController.classForName(var.type.typeName.name);
    }
    return nil;
}

- (CDOCInstanceVariable *)iVarData
{
    if ([self.data isKindOfClass:CDOCClass.class]) {
        return nil;
    } else if ([self.data isKindOfClass:CDOCInstanceVariable.class]) {
        return self.data;
    }
    return nil;
}

@end
