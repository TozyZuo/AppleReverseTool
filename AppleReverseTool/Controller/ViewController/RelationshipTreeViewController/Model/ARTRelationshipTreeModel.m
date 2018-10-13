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
