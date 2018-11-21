//
//  ARTClassTreeViewController.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/1.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTClassTreeViewController.h"
#import "ARTClassTreeCell.h"
#import "ARTURL.h"
#import "ARTRichTextController.h"
#import "ARTDataController.h"
#import "ARTConfigManager.h"
#import "ClassDumpExtension.h"

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
@property (nonatomic,  weak ) ARTDataController *dataController;
@property (nonatomic, strong) NSFont *font;
@property (nonatomic, strong) NSArray<CDOCClass *> *data;
@property (nonatomic, strong) NSArray<CDOCClass *> *filteredData;
@property (nonatomic, strong) NSString *filterConditionText;
@property (nonatomic, strong) NSOperationQueue *filterQueue;
@end

@implementation ARTClassTreeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.font = NSFontManager.sharedFontManager.selectedFont;

    self.filterQueue = [[NSOperationQueue alloc] init];
    self.filterQueue.maxConcurrentOperationCount = 1;

    __weak typeof(self) weakSelf = self;
    [[ARTFontManager sharedFontManager] addObserver:self fontChangeBlock:^(NSFont * _Nonnull (^ _Nonnull updateFontBlock)(NSFont * _Nonnull)) {
        weakSelf.font = updateFontBlock(weakSelf.font);
        [weakSelf.outlineView reloadData];
    }];

    [self observe:ARTConfigManager.sharedManager keyPath:NSStringFromSelector(@selector(showBundle)) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change)
     {
         BOOL new = [change[NSKeyValueChangeNewKey] boolValue];
         BOOL old = [change[NSKeyValueChangeOldKey] boolValue];
         if (new != old) {
             [weakSelf reloadData];
         }
     }];
}

#pragma mark - Private

- (void)reloadData
{
    [self.outlineView reloadData];
    [self.outlineView expandItem:nil expandChildren:YES];
}

#pragma mark Filter

- (void)filterWithText:(NSString *)text
{
    if (!text.length) {
        self.filteredData = nil;
        self.filterConditionText = nil;
        [self reloadData];
    }
    else if (![self.filterConditionText isEqualToString:text])
    {
        self.filterConditionText = text;

        [self.filterQueue cancelAllOperations];
        __weak typeof(self) weakSelf = self;

        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            NSMutableArray<CDOCClass */*classCopy*/> *result = [[NSMutableArray alloc] init];
            for (CDOCClass *class in weakSelf.data) {
                [weakSelf filterClass:class conditionText:text result:result];
            }

            NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
            for (CDOCClass *class in result) {
                resultDictionary[class.name] = class;
            }

            weakSelf.filteredData = (NSArray<CDOCClass *> *)NodesWithProviderBlock(^NSArray<id<ARTNode>> *{
                return result;
            }, ^id<ARTNode>(CDOCClass *node) {
                CDOCClass *superClass = resultDictionary[node.superClassName];
                if (!superClass) {
                    superClass = weakSelf.dataController.classForName(node.superClassName).copy;
                    if (superClass) {
                        resultDictionary[node.superClassName] = superClass;
                    }
                }
                return superClass;
            });
        }];

        operation.completionBlock = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf reloadData];
            });
        };

        [self.filterQueue addOperation:operation];
    }
}

- (void)filterClass:(CDOCClass *)class conditionText:(NSString *)conditionText result:(NSMutableArray<CDOCClass *> *)result
{
    if (class.subNodes.count) {
        for (CDOCClass *subClass in class.subNodes) {
            [self filterClass:subClass conditionText:conditionText result:result];
        }
    }

    if (class.categories.count) {
        BOOL isClassMetCondition = NO;
        NSMutableArray *filteredCategories = [[NSMutableArray alloc] init];
        for (CDOCCategory *category in class.categories) {
            if ([self isCategory:category metTheFilterCondition:conditionText]) {
                [filteredCategories addObject:category.copy];
//                NSLog(@"%@ match category %@ %@", conditionText, category.name, class.name);
                isClassMetCondition = YES;
            }
        }
        if (isClassMetCondition) {
            CDOCClass *classCopy = class.copy;
            classCopy.isCategoryExpanded = YES;
            for (CDOCCategory *category in filteredCategories) {
                category.classReference = classCopy;
                [classCopy addCategory:category];
            }
            [result addObject:classCopy];
            return;
        }
    }
    if ([self isString:class.name metTheFilterCondition:conditionText]) {
//        NSLog(@"%@ match class %@", conditionText, class.name);
        [result addObject:class.copy];
    }
}

- (BOOL)isCategory:(CDOCCategory *)category metTheFilterCondition:(NSString *)conditionText
{
    return [self isString:category.name metTheFilterCondition:conditionText];
}

- (BOOL)isString:(NSString *)string metTheFilterCondition:(NSString *)conditionText
{
    return [ARTRichTextController isString:string metTheFilterCondition:conditionText];
}

#pragma mark - Public

- (void)updateData:(ARTDataController *)dataController
{
    self.dataController = dataController;
    self.data = dataController.classNodes;
    [self reloadData];
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
        return self.filteredData ? self.filteredData.count : self.data.count;
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
        return self.filteredData ? self.filteredData[index] : self.data[index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(CDOCClass *)item
{
    if ([item isKindOfClass:CDOCCategory.class]) {
        return NO;
    }

    if (item.subNodes.count) {
        return YES;
    } else {
        return item.categories.count > 0;
    }
//    return item.subNodes.count > 0 ?: item.categories.count > 0; // unknown crash
}

#pragma mark - NSOutlineViewDelegate

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(CDOCClass *)item
{
    ARTClassTreeCell *cell = [outlineView makeViewWithIdentifier:@"CellID" owner:self];
    cell.outlineView = outlineView;
    cell.delegate = self;
    cell.textView.font = self.font;
    if ([item isKindOfClass:CDOCClass.class]) {
        [cell updateDataWithClass:item filterConditionText:self.filterConditionText totalCategoriesCount:self.dataController.classForName(item.name).categories.count];
    } else {
        [cell updateDataWithCategory:(CDOCCategory *)item filterConditionText:self.filterConditionText];
    }

    NSTableColumn *column = outlineView.tableColumns.firstObject;
    if (column.width < cell.optimumSize.width) {
        column.width = cell.optimumSize.width;
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
            [classTreeCell updateDataWithClass:data filterConditionText:self.filterConditionText totalCategoriesCount:self.dataController.classForName(data.name).categories.count];
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
                [classTreeCell updateDataWithClass:data filterConditionText:self.filterConditionText totalCategoriesCount:self.dataController.classForName(data.name).categories.count];
            }
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(classTreeViewController:didClickItem:link:rightMouse:)])
        {
            [self.delegate classTreeViewController:self didClickItem:classTreeCell.data link:link rightMouse:rightMouse];
        }
    }
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)obj
{
    [self filterWithText:[obj.object stringValue]];
}

@end
