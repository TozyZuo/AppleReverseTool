//
//  ARTOutlineViewController.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/1.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTOutlineViewController.h"
#import "ClassDumpExtension.h"
#import "ARTOutlineViewCell.h"
#import "ARTURL.h"

@interface CDOCClass (ARTOutlineViewController)
@property (nonatomic, assign) BOOL isCategoryExpanded;
@end
@implementation CDOCClass (ARTOutlineViewController)

- (BOOL)isCategoryExpanded
{
    return [self[ARTAssociatedKeyForSelector(_cmd)] boolValue];
}

- (void)setIsCategoryExpanded:(BOOL)isCategoryExpanded
{
    self[ARTAssociatedKeyForSelector(@selector(isCategoryExpanded))] = @(isCategoryExpanded);
}

@end

@interface ARTOutlineViewController ()
<NSOutlineViewDataSource, NSOutlineViewDelegate, ARTOutlineViewCellDelegate>
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, strong) NSArray<CDOCClass *> *data;
@end

@implementation ARTOutlineViewController

- (void)awakeFromNib
{

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
    self.outlineView.headerView = nil;
}

#pragma mark - Public

- (void)updateData:(NSArray<CDOCClass *> *)data
{
    self.data = data;
//    self.data = @[@1];
    [self.outlineView reloadData];
    [self.outlineView expandItem:nil expandChildren:YES];
}

#pragma mark - NSOutlineViewDataSource

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

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(CDOCClass *)item NS_AVAILABLE_MAC(10_7)
{
    ARTOutlineViewCell *cell = [outlineView makeViewWithIdentifier:@"CellID" owner:self];
    cell.outlineView = outlineView;
    if ([item isKindOfClass:CDOCClass.class]) {
        [cell updateDataWithClass:item];
    } else {
        [cell updateDataWithCategory:(CDOCCategory *)item];
    }
    cell.delegate = self;

    return cell;
}

#pragma mark - ARTOutlineViewCellDelegate

- (void)outlineViewCell:(ARTOutlineViewCell *)outlineViewCell didClickLink:(NSString *)link rightMouse:(BOOL)rightMouse
{
    ARTURL *url = [[ARTURL alloc] initWithString:link];
    if ([url.scheme isEqualToString:kSchemeAction]) {
        CDOCClass *data = outlineViewCell.data;
        if ([url.host isEqualToString:kExpandSubClassAction]) {
            if ([self.outlineView isItemExpanded:data]) {
                [self.outlineView collapseItem:data];
            } else {
                [self.outlineView expandItem:data];
            }
            [outlineViewCell updateDataWithClass:data];
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
                [outlineViewCell updateDataWithClass:data];
            }
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(outlineViewController:didClickItem:link:rightMouse:)])
        {
            [self.delegate outlineViewController:self didClickItem:outlineViewCell.data link:link rightMouse:rightMouse];
        }
    }
}

@end
