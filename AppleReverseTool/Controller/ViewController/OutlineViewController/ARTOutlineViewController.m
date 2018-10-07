//
//  ARTOutlineViewController.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/1.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTOutlineViewController.h"
#import "ClassDumpExtension.h"
#import "ARTClass.h"
#import "ARTOutlineViewCell.h"

@interface ARTOutlineViewController ()
<NSOutlineViewDataSource, NSOutlineViewDelegate, ARTOutlineViewCellDelegate>
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, strong) NSArray<CDOCClass *> *data;
@end

@implementation ARTOutlineViewController

- (void)awakeFromNib
{

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
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
        return item.subNodes.count;
    } else {
        return self.data.count;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable CDOCClass *)item
{
    if (item) {
        return item.subNodes[index];
    } else {
        return self.data[index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(ARTClass *)item
{
    return item.subNodes.count ? YES : NO;
}

#pragma mark - NSOutlineViewDelegate

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(CDOCClass *)item NS_AVAILABLE_MAC(10_7)
{
    ARTOutlineViewCell *cell = [outlineView makeViewWithIdentifier:@"CellID" owner:self];
    cell.outlineView = outlineView;
    [cell updateData:item];
    cell.delegate = self;

    return cell;
}

#pragma mark - ARTOutlineViewCellDelegate

- (void)outlineViewCell:(ARTOutlineViewCell *)outlineViewCell didClickLinkWithURL:(NSURL *)url rightMouse:(BOOL)rightMouse
{
    if ([self.delegate respondsToSelector:@selector(outlineViewController:didClickItem:url:rightMouse:)])
    {
        [self.delegate outlineViewController:self didClickItem:outlineViewCell.data url:url rightMouse:rightMouse];
    }
}

@end
