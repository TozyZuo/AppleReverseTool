//
//  ARTRelationshipTreeViewController.m
//  Rcode
//
//  Created by TozyZuo on 2018/10/12.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTRelationshipTreeViewController.h"
#import "ARTRelationshipTreeCell.h"
#import "ARTDataController.h"
#import "ARTURL.h"
#import "ClassDumpExtension.h"
#import "CDOCInstanceVariable.h"
#import "CDTypeLexer.h"
#import "CDTypeName.h"

@interface ARTRelationshipTreeViewController ()
<
    NSOutlineViewDataSource,
    NSOutlineViewDelegate,
    ARTRelationshipTreeCellDelegate
>
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, strong) NSArray<CDOCClass *> *data;
@end

@implementation ARTRelationshipTreeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.outlineView.headerView = nil;
}

#pragma mark - Public

- (void)updateData:(NSArray<CDOCClass *> *)data
{
    self.data = data;
    [self.outlineView reloadData];
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
    if (item) {
        if ([item isKindOfClass:CDOCClass.class]) {
            CDOCClass *class = (CDOCClass *)item;
            return class.instanceVariables.count;
        } else {
            CDOCInstanceVariable *var = (CDOCInstanceVariable *)item;
            CDOCClass *varClass = self.dataController.classForName(var.type.typeName.name);
            return varClass ? varClass.instanceVariables.count : 0;
        }
    } else {
        return self.data.count;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
    if (item) {
        CDOCClass *class;
        if ([item isKindOfClass:CDOCClass.class]) {
            class = (CDOCClass *)item;
        } else {
            class = self.dataController.classForName(((CDOCInstanceVariable *)item).type.typeName.name);
        }
        return class.instanceVariables[index];
    } else {
        return self.data[index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([item isKindOfClass:CDOCClass.class]) {
        CDOCClass *class = (CDOCClass *)item;
        return class.instanceVariables.count > 0;
    } else {
        CDOCInstanceVariable *var = (CDOCInstanceVariable *)item;
        CDOCClass *varClass = self.dataController.classForName(var.type.typeName.name);
        return varClass ? varClass.instanceVariables.count > 0 : NO;
    }
}

#pragma mark - NSOutlineViewDelegate

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(id)item NS_AVAILABLE_MAC(10_7)
{
    ARTRelationshipTreeCell *cell = [outlineView makeViewWithIdentifier:@"CellID" owner:self];
    cell.outlineView = outlineView;
    cell.delegate = self;
    [cell updateData:item];

    return cell;
}

#pragma mark - ARTRelationshipTreeCellDelegate

- (void)relationshipTreeCell:(ARTRelationshipTreeCell *)relationshipTreeCell didClickLink:(NSString *)link rightMouse:(BOOL)rightMouse
{
//    ARTURL *url = [[ARTURL alloc] initWithString:link];
//    if ([url.scheme isEqualToString:kSchemeAction]) {
//        CDOCClass *data = classTreeCell.data;
//        if ([url.host isEqualToString:kExpandSubNodeAction]) {
//            if ([self.outlineView isItemExpanded:data]) {
//                [self.outlineView collapseItem:data];
//            } else {
//                [self.outlineView expandItem:data];
//            }
//            [classTreeCell updateDataWithClass:data];
//        }
//    } else {
        if ([self.delegate respondsToSelector:@selector(relationshipTreeViewController:didClickItem:link:rightMouse:)])
        {
            [self.delegate relationshipTreeViewController:self didClickItem:relationshipTreeCell.data link:link rightMouse:rightMouse];
        }
//    }
}

@end
