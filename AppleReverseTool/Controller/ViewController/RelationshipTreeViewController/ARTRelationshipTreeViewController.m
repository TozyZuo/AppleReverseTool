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
#import "ARTRelationshipTreeModel.h"
#import "ARTRichTextController.h"
#import "ARTConfigManager.h"
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
@property (nonatomic,  weak ) ARTDataController *dataController;
@property (nonatomic, strong) NSFont *font;
@property (nonatomic, strong) NSArray<ARTRelationshipTreeModel *> *data;
@end

@implementation ARTRelationshipTreeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.outlineView.headerView = nil;

    self.font = NSFontManager.sharedFontManager.selectedFont;

    __weak typeof(self) weakSelf = self;
    [[ARTFontManager sharedFontManager] addObserver:self fontChangeBlock:^(NSFont * _Nonnull (^ _Nonnull updateFontBlock)(NSFont * _Nonnull)) {
        weakSelf.font = updateFontBlock(weakSelf.font);
        [weakSelf.outlineView reloadData];
    }];

    [self observe:ARTConfigManager.sharedManager keyPath:@"hideUnexpandedVariables" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change)
    {
        [weakSelf refreshData:weakSelf.data];

        NSMutableArray *modelData = weakSelf.data.mutableCopy;
        [modelData sortUsingComparator:^NSComparisonResult(ARTRelationshipTreeModel * _Nonnull obj1, ARTRelationshipTreeModel * _Nonnull obj2)
         {
             return obj1.canBeExpanded ? NSOrderedAscending : NSOrderedDescending;
         }];
        weakSelf.data = modelData;
        [weakSelf.outlineView reloadData];
    }];
}

#pragma mark - Private

- (void)refreshData:(NSArray<ARTRelationshipTreeModel *> *)data
{
    for (ARTRelationshipTreeModel *model in data) {
        if (model.subNodes) {
            [self refreshData:model.subNodes];
        }
        [model recreateSubNodesForcibly:NO hideUnexpandedVariables:ARTConfigManager.sharedManager.hideUnexpandedVariables];
    }
}

#pragma mark - Public

- (void)updateData:(ARTDataController *)dataController
{
    self.dataController = dataController;

    NSMutableArray *modelData = [[NSMutableArray alloc] init];
    for (CDOCClass *class in dataController.relationshipNodes) {
        [modelData addObject:[[ARTRelationshipTreeModel alloc] initWithData:class dataController:self.dataController]];
    }
    [modelData sortUsingComparator:^NSComparisonResult(ARTRelationshipTreeModel * _Nonnull obj1, ARTRelationshipTreeModel * _Nonnull obj2)
    {
        return obj1.canBeExpanded ? NSOrderedAscending : NSOrderedDescending;
    }];
    self.data = modelData;
    [self.outlineView reloadData];
}

#pragma mark - NSOutlineViewDataSource

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    return self.font.pointSize + 10;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable ARTRelationshipTreeModel *)item
{
    if (item) {
        return item.subNodes.count;
    } else {
        return self.data.count;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable ARTRelationshipTreeModel *)item
{
    if (item) {
        return item.subNodes[index];
    } else {
        return self.data[index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(ARTRelationshipTreeModel *)item
{
    return item.canBeExpanded;
}

#pragma mark - NSOutlineViewDelegate

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(ARTRelationshipTreeModel *)item NS_AVAILABLE_MAC(10_7)
{
    ARTRelationshipTreeCell *cell = [outlineView makeViewWithIdentifier:@"CellID" owner:self];
    cell.outlineView = outlineView;
    cell.delegate = self;
    cell.dataController = self.dataController;
    cell.textView.font = self.font;
    [cell updateData:item];

    NSTableColumn *column = outlineView.tableColumns.firstObject;
    if (column.width < cell.richTextController.optimumSize.width) {
        column.width = cell.richTextController.optimumSize.width;
        column.minWidth = column.width;
    }
    return cell;
}

#pragma mark - ARTRelationshipTreeCellDelegate

- (void)relationshipTreeCell:(ARTRelationshipTreeCell *)relationshipTreeCell didClickLink:(NSString *)link rightMouse:(BOOL)rightMouse
{
    ARTURL *url = [[ARTURL alloc] initWithString:link];
    if ([url.scheme isEqualToString:kSchemeAction]) {
        ARTRelationshipTreeModel *data = relationshipTreeCell.data;
        if ([url.host isEqualToString:kExpandSubNodeAction]) {
            if ([self.outlineView isItemExpanded:data]) {
                [self.outlineView collapseItem:data];
            } else {
                [relationshipTreeCell.data recreateSubNodesForcibly:YES hideUnexpandedVariables:ARTConfigManager.sharedManager.hideUnexpandedVariables];
                [self.outlineView expandItem:data];
            }
            [relationshipTreeCell updateData:data];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(relationshipTreeViewController:didClickItem:link:rightMouse:)])
        {
            [self.delegate relationshipTreeViewController:self didClickItem:relationshipTreeCell.data link:link rightMouse:rightMouse];
        }
    }
}

@end
