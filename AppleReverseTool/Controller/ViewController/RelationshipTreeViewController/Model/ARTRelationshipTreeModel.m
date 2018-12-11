//
//  ARTRelationshipTreeModel.m
//  Rcode
//
//  Created by TozyZuo on 2018/10/13.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTRelationshipTreeModel.h"
#import "ARTDataController.h"
#import "ARTConfigManager.h"
#import "ClassDumpExtension.h"
#import "CDOCInstanceVariable.h"

@interface ARTRelationshipTreeModel ()
@property (nonatomic,  weak ) ARTDataController *dataController;
@property (nonatomic, strong) CDOCClass *classData;
@property (nonatomic, strong) CDOCInstanceVariable *ivarData;
@property (nonatomic, assign) ARTRelationshipTreeModelType type;
@property (nonatomic, strong) CDOCClass *internalClassData;
@end

@implementation ARTRelationshipTreeModel
@synthesize subNodes = _subNodes;
@synthesize subclassNodes = _subclassNodes;

- (instancetype)initWithClass:(CDOCClass *)aClass type:(ARTRelationshipTreeModelType)type dataController:(ARTDataController *)dataController
{
    self = [super init];
    if (self) {
        self.classData = aClass;
        self.type = type;
        self.dataController = dataController;
    }
    return self;
}

- (instancetype)initWithInstanceVariable:(CDOCInstanceVariable *)var type:(ARTRelationshipTreeModelType)type dataController:(ARTDataController *)dataController
{
    self = [super init];
    if (self) {
        self.ivarData = var;
        self.type = type;
        self.dataController = dataController;
    }
    return self;
}

- (CDOCClass *)internalClassData
{
    if (_classData) {
        return _classData;
    } else if (_ivarData) {
        return self.dataController.classForName(_ivarData.type.typeName.name);
    }
    return nil;
}

- (BOOL)canBeExpanded
{
    switch (self.type) {
        case ARTRelationshipTreeModelTypeReferer:
            return self.canExpandeSubNodes || self.internalClassData.subClasses.count > 0;
        case ARTRelationshipTreeModelTypeReference:
            return self.canExpandeSubNodes;
        case ARTRelationshipTreeModelTypeSubclass:
            return self.internalClassData.subClasses.count > 0;
    }
}

- (BOOL)canExpandeSubNodes
{
    CDOCClass *classData = self.internalClassData;
    switch (self.type) {
        case ARTRelationshipTreeModelTypeReference:
            {
                if (classData && (classData.isInsideMainBundle ||
                    ARTConfigManager.sharedInstance.allowExpandClassNotInMainBundle))
                {
                    if (self.hideUnexpandedVariables) {
                        for (CDOCInstanceVariable *ivar in classData.instanceVariables) {
                            if ([self classDataFromInstanceVariable:ivar]) {
                                return YES;
                            }
                        }
                    } else {
                        return classData.instanceVariables.count > 0;
                    }
                }
            }
            return NO;
        case ARTRelationshipTreeModelTypeReferer:
            return classData.referers.count > 0;
        case ARTRelationshipTreeModelTypeSubclass:
            return NO;
    }
    return NO;
}

- (void)createSubNodes
{
    if (!_subNodes) {
        [self recreateSubNodesForcibly:YES];
    }
}

- (void)createSubclassNodes
{
    if (!_subclassNodes) {
        NSMutableArray *subNodes = [[NSMutableArray alloc] init];
        for (CDOCClass *subClass in self.internalClassData.subClasses) {
            ARTRelationshipTreeModel *model = [[ARTRelationshipTreeModel alloc] initWithClass:subClass type:ARTRelationshipTreeModelTypeSubclass dataController:self.dataController];
            model.hideUnexpandedVariables = self.hideUnexpandedVariables;
            model.superNode = self;
            [subNodes addObject:model];
        }
        _subclassNodes = subNodes;
    }
}

- (void)recreateSubNodesForcibly:(BOOL)force
{
    if (force || _subNodes) {
        NSMutableArray *subNodes = [[NSMutableArray alloc] init];
        switch (self.type) {
            case ARTRelationshipTreeModelTypeReference:
                for (CDOCInstanceVariable *ivar in self.internalClassData.instanceVariables) {
                    CDOCClass *aClass = [self classDataFromInstanceVariable:ivar];
                    if (aClass || !self.hideUnexpandedVariables) {
                        ARTRelationshipTreeModel *model = [[ARTRelationshipTreeModel alloc] initWithInstanceVariable:ivar type:ARTRelationshipTreeModelTypeReference dataController:self.dataController];
                        model.hideUnexpandedVariables = self.hideUnexpandedVariables;
                        model.superNode = self;
                        [subNodes addObject:model];
                    }
                }
                break;
            case ARTRelationshipTreeModelTypeReferer:
            {
                NSArray *referers = [self.internalClassData.referers.allObjects sortedArrayUsingComparator:^NSComparisonResult(CDOCClass * _Nonnull obj1, CDOCClass * _Nonnull obj2)
                {
                    if (obj1.isInsideMainBundle != obj2.isInsideMainBundle) {
                        return obj2.isInsideMainBundle ? NSOrderedAscending : NSOrderedDescending;
                    }
                    return [obj1.name compare:obj2.name];
                }];
                for (CDOCClass *refererClass in referers) {
                    ARTRelationshipTreeModel *model = [[ARTRelationshipTreeModel alloc] initWithClass:refererClass type:ARTRelationshipTreeModelTypeReferer dataController:self.dataController];
                    model.hideUnexpandedVariables = self.hideUnexpandedVariables;
                    model.superNode = self;
                    [subNodes addObject:model];
                }
            }
                break;
            case ARTRelationshipTreeModelTypeSubclass:
//                for (CDOCClass *subClass in self.internalClassData.subClasses) {
//                    ARTRelationshipTreeModel *model = [[ARTRelationshipTreeModel alloc] initWithClass:subClass type:ARTRelationshipTreeModelTypeSubclass dataController:self.dataController];
//                    model.hideUnexpandedVariables = self.hideUnexpandedVariables;
//                    model.superNode = self;
//                    [subNodes addObject:model];
//                }
                break;
        }
        [subNodes sortUsingComparator:^NSComparisonResult(ARTRelationshipTreeModel * _Nonnull obj1, ARTRelationshipTreeModel * _Nonnull obj2) {
            CDDetailedType detailedType1 = obj1.ivarData.type.detailedType;
            CDDetailedType detailedType2 = obj2.ivarData.type.detailedType;
            if (detailedType1 == detailedType2) {
                if (detailedType1 == CDDetailedTypeNamedObject) {
                    CDOCClass *c1 = self.dataController.classForName(obj1.ivarData.type.typeName.name);
                    CDOCClass *c2 = self.dataController.classForName(obj2.ivarData.type.typeName.name);
                    if (c1.isInsideMainBundle != c2.isInsideMainBundle) {
                        return c2.isInsideMainBundle ? NSOrderedAscending : NSOrderedDescending;
                    }
                }
                return [obj1.ivarData.name compare:obj2.ivarData.name];
            } else {
                return detailedType1 < detailedType2 ? NSOrderedAscending : NSOrderedDescending;
            }
        }];
        _subNodes = subNodes;
    }
}

- (CDOCClass *)classDataFromInstanceVariable:(CDOCInstanceVariable *)ivar
{
    return self.dataController.classForName(ivar.type.typeName.name);
}

@end
