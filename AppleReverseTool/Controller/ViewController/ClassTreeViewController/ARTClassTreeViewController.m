//
//  ARTClassTreeViewController.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/1.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTClassTreeViewController.h"
#import "ClassDumpExtension.h"
#import "ARTClassTreeCell.h"
#import "ARTURL.h"
#import "ARTRichTextController.h"

@interface CDOCClass (ARTClassTreeViewController)
@property (nonatomic, assign) BOOL isCategoryExpanded;
@end
@implementation CDOCClass (ARTClassTreeViewController)

- (BOOL)isCategoryExpanded
{
    return [self[ARTAssociatedKeyForSelector(_cmd)] boolValue];
}

- (void)setIsCategoryExpanded:(BOOL)isCategoryExpanded
{
    self[ARTAssociatedKeyForSelector(@selector(isCategoryExpanded))] = @(isCategoryExpanded);
}

@end

@interface ARTClassTreeViewController ()
<
    NSOutlineViewDataSource,
    NSOutlineViewDelegate,
    NSTextFieldDelegate,
    ARTClassTreeCellDelegate
>
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, strong) NSFont *font;
@property (nonatomic, strong) NSArray<CDOCClass *> *data;
@property (nonatomic, strong) NSCache<CDOCClass *, ARTClassTreeCell *> *cellCache;
@end

@implementation ARTClassTreeViewController

//- (void)awakeFromNib
//{
//    [super awakeFromNib];
//    self.outlineView.headerView = nil;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.cellCache = [[NSCache alloc] init];

    self.font = [NSFont fontWithName:@"Menlo-Regular" size:18];

    __weak typeof(self) weakSelf = self;
    [[ARTFontManager sharedFontManager] addObserver:self fontChangeBlock:^(NSFont * _Nonnull (^ _Nonnull updateFontBlock)(NSFont * _Nonnull)) {
        weakSelf.font = updateFontBlock(weakSelf.font);
        [weakSelf.outlineView reloadData];
    }];
}

#pragma mark - Private
#pragma mark Filter



#pragma mark - Public

- (void)updateData:(NSArray<CDOCClass *> *)data
{
    self.data = data;
    [self.outlineView reloadData];
    [self.outlineView expandItem:nil expandChildren:YES];
}

#pragma mark - NSOutlineViewDataSource

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    return self.font.pointSize + 10;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable CDOCClass *)item
{
    if (item) {
        return item.subNodes.count + (item.isCategoryExpanded ? item.categories.count : 0);
    } else {
        return self.data.count;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable CDOCClass *)item
{
    if (item) {
        if (item.isCategoryExpanded) {
            if (index < item.categories.count) {
                return item.categories[index];
            } else {
                return item.subNodes[index - item.categories.count];
            }
        } else {
            return item.subNodes[index];
        }
    } else {
        return self.data[index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(CDOCClass *)item
{
    if ([item isKindOfClass:CDOCCategory.class]) {
        return NO;
    }
    return item.subNodes.count ? YES : NO;
}

#pragma mark - NSOutlineViewDelegate

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(CDOCClass *)item
{
//    ARTClassTreeCell *cell = [self.cellCache objectForKey:item];
//    if (cell) {
//        return cell;
//    }
//    cell = [[ARTClassTreeCell alloc] init];
    ARTClassTreeCell *cell = [outlineView makeViewWithIdentifier:@"CellID" owner:self];
    cell.outlineView = outlineView;
    cell.delegate = self;
    cell.textView.font = self.font;
    if ([item isKindOfClass:CDOCClass.class]) {
        [cell updateDataWithClass:item];
    } else {
        [cell updateDataWithCategory:(CDOCCategory *)item];
    }

//    [self.cellCache setObject:cell forKey:item];

    NSTableColumn *column = outlineView.tableColumns.firstObject;
    if (column.width < cell.richTextController.optimumSize.width) {
        column.width = cell.richTextController.optimumSize.width;
        column.minWidth = column.width;
    }

    return cell;
}

#pragma mark - ARTClassTreeCellDelegate

- (void)classTreeCell:(ARTClassTreeCell *)classTreeCell didClickLink:(NSString *)link rightMouse:(BOOL)rightMouse
{
    ARTURL *url = [[ARTURL alloc] initWithString:link];
    if ([url.scheme isEqualToString:kSchemeAction]) {
        CDOCClass *data = classTreeCell.data;
        if ([url.host isEqualToString:kExpandSubClassAction]) {
            if ([self.outlineView isItemExpanded:data]) {
                [self.outlineView collapseItem:data];
            } else {
                [self.outlineView expandItem:data];
            }
            [classTreeCell updateDataWithClass:data];
        }
        else if ([url.host isEqualToString:kExpandCategoryAction])
        {
            if ([self.outlineView isItemExpanded:data]) {
                data.isCategoryExpanded = !data.isCategoryExpanded;
                if (data.isCategoryExpanded) {
                    [self.outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, data.categories.count)] inParent:data withAnimation:NSTableViewAnimationEffectNone];
                } else {
                    [self.outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, data.categories.count)] inParent:data withAnimation:NSTableViewAnimationEffectNone];
                }
            } else {
                data.isCategoryExpanded = YES;
                [self.outlineView expandItem:data];
                [classTreeCell updateDataWithClass:data];
            }
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(classTreeViewController:didClickItem:link:rightMouse:)])
        {
            [self.delegate classTreeViewController:self didClickItem:classTreeCell.data link:link rightMouse:rightMouse];
        }
    }
}

@end
