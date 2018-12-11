//
//  ARTPickClassViewController.m
//  Rcode
//
//  Created by TozyZuo on 2018/11/28.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTClassPickerViewController.h"
#import "ARTDataController.h"
#import "ARTClassPickerCell.h"
#import "ARTConfigManager.h"
#import "CDOCClass.h"
#import "NSColor+ART.h"

@interface ARTClassPickerViewController ()
<NSTableViewDelegate, NSTableViewDataSource>
@property (weak) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) NSFont *font;
@property (nonatomic, strong) NSString *filterString;
@property (nonatomic, strong) NSOperationQueue *filterQueue;
@property (nonatomic, strong) NSMutableArray<CDOCClass *> *results;
@property (nonatomic,  copy ) void (^completion)(CDOCClass * _Nullable);
@end

@implementation ARTClassPickerViewController

- (void)viewDidLoad
{
    self.font = ARTFontManager.sharedFontManager.themeFont;

    self.filterQueue = [[NSOperationQueue alloc] init];
    self.filterQueue.maxConcurrentOperationCount = 1;
}

- (void)moveUp:(id)sender
{
    NSInteger row = (self.tableView.selectedRow - 1 + self.results.count)%self.results.count;
    [self updateSelectedRowColor:row];
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [self.tableView scrollRowToVisible:row];
}

- (void)moveDown:(id)sender
{
    NSInteger row = (self.tableView.selectedRow + 1)%self.results.count;
    [self updateSelectedRowColor:row];
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [self.tableView scrollRowToVisible:row];
}

- (void)insertNewline:(id)sender
{
    ARTClassPickerCell *cell = [self.tableView viewAtColumn:0 row:self.tableView.selectedRow makeIfNecessary:NO];
    self.filterString = nil;
    self.completion(cell.aClass);
}

#pragma mark - Private

- (void)reloadData
{
    self.view.height = ([self tableView:self.tableView heightOfRow:0] + 2/*margin 1+1*/) * (self.results.count >= 8 ? 8 : self.results.count);
    [self.tableView reloadData];
    [self updateSelectedRowColor:0];
    [self.tableView scrollRowToVisible:0];
}

- (void)updateSelectedRowColor:(NSInteger)row
{
    NSTableView *tableView = self.tableView;
    if (tableView.selectedRow >= 0) {
        ARTClassPickerCell *cell = [tableView viewAtColumn:0 row:tableView.selectedRow makeIfNecessary:NO];
        cell.textView.textColor = NSColor.blackColor;
    }
    ARTClassPickerCell *cell = [tableView viewAtColumn:0 row:row makeIfNecessary:YES];
    cell.textView.textColor = NSColor.whiteColor;
}

#pragma mark - Public

- (void)setFilterString:(NSString *)filterString completion:(nonnull void (^)(CDOCClass * _Nullable))completion
{
    if (![self.filterString isEqualToString:filterString]) {
        self.filterString = filterString;

        [self.filterQueue cancelAllOperations];

        weakifySelf();
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            strongifySelf();

            NSMutableArray *results = [[NSMutableArray alloc] init];

            NSArray *allClasses = ARTConfigManager.sharedInstance.allowExpandClassNotInMainBundle ? self.dataController.allClasses.allValues : self.dataController.allClassesInMainFile.allValues;
            for (CDOCClass *aClass in allClasses) {
                if ([ARTRichTextController isString:aClass.name metTheFilterCondition:filterString]) {
                    [results addObject:aClass];
                }
            }

            self.results = results;
        }];

        operation.completionBlock = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                strongifySelf();
                if (!self.results.count) {
                    self.filterString = nil;
                    completion(nil);
                } else {
                    self.completion = completion;
                    [self reloadData];
                }
            });
        };

        [self.filterQueue addOperation:operation];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.results.count;
}

#pragma mark - NSTableViewDelegate

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return self.font.pointSize + 10;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (row > self.results.count) {
        return nil;
    }
    
    ARTClassPickerCell *cell = [tableView makeViewWithIdentifier:@"CellID" owner:self];
    cell.textView.font = self.font;
    cell.aClass = self.results[row];
    cell.richTextController.filterConditionText = self.filterString;
    if (row == tableView.selectedRow) {
        cell.textView.textColor = NSColor.whiteColor;
    } else {
        cell.textView.textColor = NSColor.blackColor;
    }

    return cell;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    [self updateSelectedRowColor:row];
    return YES;
}

@end
