//
//  ARTRelationshipTreeViewController.m
//  Rcode
//
//  Created by TozyZuo on 2018/10/12.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTRelationshipTreeViewController.h"
#import "ARTRelationshipTreeCell.h"
#import "ARTClassPickerViewController.h"
#import "ARTDataController.h"
#import "ARTURL.h"
#import "ARTRelationshipTreeModel.h"
#import "ARTConfigManager.h"
#import "ARTPopover.h"
#import "ClassDumpExtension.h"
#import "CDOCInstanceVariable.h"
#import "CDTypeLexer.h"
#import "CDTypeName.h"

@interface ARTRelationshipTreeViewController ()
<
    NSOutlineViewDataSource,
    NSOutlineViewDelegate,
    ARTRichTextCellDelegate
>
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic,  weak ) ARTDataController *dataController;
@property (nonatomic, strong) NSFont *font;
@property (nonatomic, strong) NSArray<ARTRelationshipTreeModel *> *data;
@property (nonatomic, strong) ARTClassPickerViewController *classPickerViewController;
@property (nonatomic, strong) ARTPopover *popover;
@end

@implementation ARTRelationshipTreeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.font = ARTFontManager.sharedFontManager.themeFont;

    self.classPickerViewController = [[ARTClassPickerViewController alloc] init];

    self.popover = [[ARTPopover alloc] initWithContentViewController:self.classPickerViewController];

    weakifySelf();
    [[ARTFontManager sharedFontManager] addObserver:self fontChangeBlock:^(NSFont * _Nonnull (^ _Nonnull updateFontBlock)(NSFont * _Nonnull)) {
        weakSelf.font = updateFontBlock(weakSelf.font);
        [weakSelf.outlineView reloadData];
    }];

    [self observe:ARTConfigManager.sharedManager keyPath:@"hideUnexpandedVariables" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change)
    {
        BOOL new = [change[NSKeyValueChangeNewKey] boolValue];
        BOOL old = [change[NSKeyValueChangeOldKey] boolValue];
        if (new != old) {
            [weakSelf refreshData:weakSelf.data];

            NSMutableArray *modelData = weakSelf.data.mutableCopy;
            [modelData sortUsingComparator:^NSComparisonResult(ARTRelationshipTreeModel * _Nonnull obj1, ARTRelationshipTreeModel * _Nonnull obj2)
             {
                 return obj1.canBeExpanded ? NSOrderedAscending : NSOrderedDescending;
             }];
            weakSelf.data = modelData;
            [weakSelf.outlineView reloadData];
        }
    }];
}

#pragma mark - Private

- (void)refreshData:(NSArray<ARTRelationshipTreeModel *> *)data
{
    BOOL hideUnexpandedVariables = ARTConfigManager.sharedManager.hideUnexpandedVariables;
    for (ARTRelationshipTreeModel *model in data) {
        if (model.subNodes) {
            [self refreshData:model.subNodes];
        }
        model.hideUnexpandedVariables = hideUnexpandedVariables;
        [model recreateSubNodesForcibly:NO];
    }
}

#pragma mark - Public

- (void)updateData:(ARTDataController *)dataController
{
    self.dataController = dataController;
    self.classPickerViewController.dataController = dataController;

    BOOL hideUnexpandedVariables = ARTConfigManager.sharedManager.hideUnexpandedVariables;
    NSMutableArray *modelData = [[NSMutableArray alloc] init];
    for (CDOCClass *class in dataController.relationshipNodes) {
        ARTRelationshipTreeModel *model = [[ARTRelationshipTreeModel alloc] initWithData:class dataController:self.dataController];
        model.hideUnexpandedVariables = hideUnexpandedVariables;
        [modelData addObject:model];
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

#pragma mark - ARTRichTextCellDelegate

- (void)richTextCell:(ARTRelationshipTreeCell *)relationshipTreeCell didClickLink:(NSString *)link rightMouse:(BOOL)rightMouse
{
    ARTURL *url = [[ARTURL alloc] initWithString:link];
    if ([url.scheme isEqualToString:kSchemeAction]) {
        ARTRelationshipTreeModel *data = relationshipTreeCell.data;
        if ([url.host isEqualToString:kExpandSubNodeAction]) {
            if ([self.outlineView isItemExpanded:data]) {
                [self.outlineView collapseItem:data];
            } else {
                [relationshipTreeCell.data createSubNodes];
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

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)obj
{
    NSTextField *textField = obj.object;
    if (textField.stringValue.length) {
        [self.popover displayPopoverInWindow:self.view.window atPoint:[textField.superview convertPoint:NSMakePoint(textField.width * .5, textField.height) toView:nil]];

        weakifySelf();
        [self.classPickerViewController setFilterString:textField.stringValue completion:^(CDOCClass * _Nullable aClass)
        {
            strongifySelf();
            [self.popover closePopover:nil];

            if (aClass) {
                textField.stringValue = aClass.name;
            }
        }];
    } else {
        [self.popover closePopover:nil];
    }
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    static NSArray *commandSelectorArray;
    static NSString *cancelOperation = @"cancelOperation:";
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        commandSelectorArray = @[NSStringFromSelector(@selector(insertNewline:)),
                                 NSStringFromSelector(@selector(moveUp:)),
                                 NSStringFromSelector(@selector(moveDown:)),];
    });

    if ([NSStringFromSelector(commandSelector) isEqualToString:cancelOperation] && control.stringValue.length)
    {
        if (self.popover.isVisible) {
            [self.popover closePopover:nil];
        } else {
            [self.popover displayPopoverInWindow:self.view.window atPoint:[control.superview convertPoint:NSMakePoint(control.width * .5, control.height) toView:nil]];
        }
    }

    if ([commandSelectorArray containsObject:NSStringFromSelector(commandSelector)] && self.popover.isVisible)
    {
        TZWarningIgnore(-Warc-performSelector-leaks)
        [self.classPickerViewController performSelector:commandSelector withObject:nil];
        TZWarningIgnoreEnd
        return YES;
    }
    return NO;
}

@end
