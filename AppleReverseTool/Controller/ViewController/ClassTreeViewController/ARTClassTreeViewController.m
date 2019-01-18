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

@interface NSMutableDictionary (ARTClassTreeViewController)
@property NSValue *range;
@property NSString *string;
@property NSNumber *row;
@end

typedef NSMutableDictionary ARTIndexModel;

ImplementCategory(NSMutableDictionary, ARTClassTreeViewController, range, string, row)

@interface ARTClassTreeViewController ()
<
    NSOutlineViewDataSource,
    NSOutlineViewDelegate,
    NSTextFieldDelegate,
    ARTRichTextCellDelegate,
    NSTextFinderClient
>
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic,  weak ) ARTDataController *dataController;
@property (nonatomic, strong) NSFont *font;
@property (nonatomic, strong) NSArray<CDOCClass *> *data;
@property (nonatomic, strong) NSArray<CDOCClass *> *filteredData; // keep origin state
@property (nonatomic, strong) NSString *filterConditionText;
@property (nonatomic, strong) NSOperationQueue *filterQueue;
// TextFinder
@property (strong) IBOutlet NSTextFinder *textFinder;
@property (nonatomic, assign) NSUInteger stringLength;
@property (nonatomic, strong) NSMutableArray<ARTIndexModel<NSString *, id> *> *finderIndex;
@end

@implementation ARTClassTreeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.font = ARTFontManager.sharedFontManager.themeFont;

    self.filterQueue = [[NSOperationQueue alloc] init];
    self.filterQueue.maxConcurrentOperationCount = 1;

//    self.finderIndex = [[NSMutableArray alloc] init];
    self.finderIndex = [NSMutableArray vectorWithType:@ArrayType(<NSMutableDictionary<NSString *, id> *>)];

    weakifySelf();
    [[ARTFontManager sharedFontManager] addObserver:self fontChangeBlock:^(NSFont * _Nonnull (^ _Nonnull updateFontBlock)(NSFont * _Nonnull)) {
        weakSelf.font = updateFontBlock(weakSelf.font);
        [weakSelf.outlineView reloadData];
    }];

    [self observe:ARTConfigManager.sharedManager keyPath:@keypath(ARTConfigManager.sharedManager, showBundle) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change)
     {
         BOOL new = [change[NSKeyValueChangeNewKey] boolValue];
         BOOL old = [change[NSKeyValueChangeOldKey] boolValue];
         if (new != old) {
             [weakSelf reloadData];
         }
     }];
}

- (IBAction)performFindPanelAction:(id)sender
{
    [self performTextFinderAction:sender];
}

- (void)performTextFinderAction:(id)sender
{
    [self prepareForTextFinder];
    [self.textFinder performAction:[sender tag]];
}

#pragma mark - Private

- (void)reloadData
{
    [self.outlineView reloadData];
    [self.outlineView expandItem:nil expandChildren:YES];
}

- (void)prepareForTextFinder
{
    [self.finderIndex removeAllObjects];

    NSInteger rowCount = self.outlineView.numberOfRows;
    NSRange range = NSMakeRange(0, 0);
    NSString *string;

    for (int i = 0; i < rowCount; i++) {
        CDOCProtocol *item = [self.outlineView itemAtRow:i];
        string = item.name;
        range = NSMakeRange(NSMaxRange(range), string.length);
        self.finderIndex[i].string = string;
        self.finderIndex[i].range = [NSValue valueWithRange:range];
        self.finderIndex[i].row = @(i);
    }

    self.stringLength = NSMaxRange(range);
}

#pragma mark Filter

- (void)filterWithText:(NSString *)text
{
    [self.textFinder noteClientStringWillChange];
    if (!text.length) {
        self.filteredData = nil;
        self.filterConditionText = nil;
        [self reloadData];
    }
    else if (![self.filterConditionText isEqualToString:text])
    {
        self.filterConditionText = text;

        [self.filterQueue cancelAllOperations];
        weakifySelf();

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
    return [ARTRichTextController priorityForFilterCondition:conditionText string:string] > 0;
}

#pragma mark - Public

- (void)updateData:(ARTDataController *)dataController
{
    self.dataController = dataController;
    self.data = dataController.classNodes;
    [self reloadData];
    [self prepareForTextFinder];
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

#pragma mark - ARTRichTextCellDelegate

- (void)richTextCell:(ARTClassTreeCell *)classTreeCell didClickLink:(NSString *)link rightMouse:(BOOL)rightMouse
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

#pragma mark - NSTextFinderClient

- (BOOL)isEditable
{
    return NO;
}

- (ARTIndexModel *)modelForIndex:(NSUInteger)index
{
    for (ARTIndexModel *model in self.finderIndex) {
        NSRange range = model.range.rangeValue;
        if (index >= range.location && index < NSMaxRange(range)) {
            return model;
        }
    }
    return nil;
}

- (NSString *)stringAtIndex:(NSUInteger)characterIndex effectiveRange:(NSRangePointer)outRange endsWithSearchBoundary:(BOOL *)outFlag
{
    ARTIndexModel *model = [self modelForIndex:characterIndex];
    if (model) {
        *outRange = model.range.rangeValue;
        *outFlag = YES;
        return model.string;
    }
    return nil;
}

- (void)scrollRangeToVisible:(NSRange)range
{
    ARTIndexModel *model = [self modelForIndex:range.location];
    if (model) {
        [self.outlineView scrollRowToVisible:model.row.integerValue];
    }
}

- (NSView *)contentViewAtIndex:(NSUInteger)index effectiveCharacterRange:(NSRangePointer)outRange
{
    ARTIndexModel *model = [self modelForIndex:index];
    if (model) {
        *outRange = model.range.rangeValue;
        ARTClassTreeCell *cell = [self.outlineView viewAtColumn:0 row:model.row.integerValue makeIfNecessary:YES];
        return cell.textView;
    }
    return nil;
}

- (NSArray<NSValue *> *)rectsForCharacterRange:(NSRange)range
{
    ARTIndexModel *model = [self modelForIndex:range.location];
    if (model) {
        NSRange modelRange = model.range.rangeValue;
        ARTClassTreeCell *cell = [self.outlineView viewAtColumn:0 row:model.row.integerValue makeIfNecessary:YES];
        NSRange nameRange = [cell.textView.string rangeOfString:cell.data.name];
        return [cell.textView rectsForCharacterRange:NSMakeRange(range.location - modelRange.location + nameRange.location, range.length)];
    }
    return nil;
}

@end
