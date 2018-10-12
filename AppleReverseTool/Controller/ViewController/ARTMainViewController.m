//
//  ARTMainViewController.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/1.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTMainViewController.h"
#import "ARTDataController.h"
#import "ARTOutlineViewController.h"
#import "ARTTextViewController.h"
#import "ARTButton.h"
#import "NSColor+ART.h"


@interface ARTMainViewController ()
<ARTOutlineViewControllerDelegate, ARTTextViewControllerDelegate>
@property (nonatomic, strong) ARTDataController *dataController;
@property (readonly) ARTOutlineViewController *outlineViewController;
@property (readonly) ARTTextViewController *textViewController;
@property (weak) IBOutlet NSTextField *stateLabel;
@property (weak) IBOutlet ARTButton *classTreeButton;
@property (weak) IBOutlet ARTButton *relationshipTreeButton;
@end

@implementation ARTMainViewController
@synthesize outlineViewController = _outlineViewController;
@synthesize textViewController = _textViewController;

- (ARTOutlineViewController *)outlineViewController
{
    if (!_outlineViewController) {
        for (NSViewController *vc in self.childViewControllers) {
            if ([vc isKindOfClass:ARTOutlineViewController.class]) {
                _outlineViewController = (ARTOutlineViewController *)vc;
                _outlineViewController.delegate = self;
            }
        }
    }
    return _outlineViewController;
}

- (ARTTextViewController *)textViewController
{
    if (!_textViewController) {
        for (NSViewController *vc in self.childViewControllers) {
            if ([vc isKindOfClass:ARTTextViewController.class]) {
                _textViewController = (ARTTextViewController *)vc;
                _textViewController.delegate = self;
                _textViewController.dataController = self.dataController;
            }
        }
    }
    return _textViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    __weak typeof(self) weakSelf = self;

    [self.classTreeButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"类树" attributes:@{NSFontAttributeName: [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica" traits:0 weight:0 size:13], NSForegroundColorAttributeName: RGBColor(128, 128, 128)}] forState:ARTButtonStateNormal];
    [self.classTreeButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"类树" attributes:@{NSFontAttributeName: [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica Neue" traits:NSBoldFontMask weight:0 size:13], NSForegroundColorAttributeName: RGBColor(49, 49, 49)}] forState:ARTButtonStateHighlighted];
    [self.classTreeButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"类树" attributes:@{NSFontAttributeName: [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica Neue" traits:NSBoldFontMask weight:0 size:13], NSForegroundColorAttributeName: RGBColor(50, 137, 240)}] forState:ARTButtonStateSelected];
    self.classTreeButton.eventHandler = ^(__kindof ARTControl * _Nonnull button, ARTControlEventType type, NSEvent * _Nonnull event) {
        if (type == ARTControlEventTypeMouseUpInside) {
            [weakSelf classTreeButtonAction:button];
        }
    };

    [self.relationshipTreeButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"关系树" attributes:@{NSFontAttributeName: [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica" traits:0 weight:0 size:13], NSForegroundColorAttributeName: RGBColor(128, 128, 128)}] forState:ARTButtonStateNormal];
    [self.relationshipTreeButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"关系树" attributes:@{NSFontAttributeName: [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica Neue" traits:NSBoldFontMask weight:0 size:13], NSForegroundColorAttributeName: RGBColor(49, 49, 49)}] forState:ARTButtonStateHighlighted];
    [self.relationshipTreeButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"关系树" attributes:@{NSFontAttributeName: [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica Neue" traits:NSBoldFontMask weight:0 size:13], NSForegroundColorAttributeName: RGBColor(50, 137, 240)}] forState:ARTButtonStateSelected];
    self.relationshipTreeButton.eventHandler = ^(__kindof ARTControl * _Nonnull button, ARTControlEventType type, NSEvent * _Nonnull event) {
        if (type == ARTControlEventTypeMouseUpInside) {
            [weakSelf relationshipTreeButtonAction:button];
        }
    };
}

- (IBAction)classTreeButtonAction:(ARTButton *)button
{
    if (!button.selected) {
        button.selected = YES;
        self.relationshipTreeButton.selected = NO;
    }
}

- (IBAction)relationshipTreeButtonAction:(ARTButton *)button
{
    if (!button.selected) {
        button.selected = YES;
        self.classTreeButton.selected = NO;
    }
}

- (void)setFileURL:(NSURL *)fileURL
{
    if (!_fileURL && fileURL) {
        _fileURL = fileURL;

//        [self.outlineViewController updateData:nil];
//        self.classTreeButton.enabled = YES;
//        self.classTreeButton.selected = YES;
//        self.relationshipTreeButton.enabled = YES;
//        return;

        self.dataController = [[ARTDataController alloc] init];

        [self.dataController processDataWithFilePath:fileURL.path progress:^(ARTDataControllerProcessState state, NSString * _Nullable framework, NSString * _Nullable class, NSString * _Nullable iVar, NSString * _Nullable type)
         {
             switch (state) {
                 case ARTDataControllerProcessStateWillProcess:
                     self.stateLabel.stringValue = @"准备分析数据...";
                     break;
                 case ARTDataControllerProcessStateProcessingData:
                     self.stateLabel.stringValue = [NSString stringWithFormat:@"分析 [%@] %@ %@", framework, class ?: @"", iVar ?: @""];
                     break;
                 case ARTDataControllerProcessStateProcessingType:
                     self.stateLabel.stringValue = [NSString stringWithFormat:@"分析类型 [%@] %@ %@", framework, class ?: @"", type ?: @""];
                     break;
                 case ARTDataControllerProcessStateProcessingStructsAndUnions:
                     self.stateLabel.stringValue = @"分析结构体和联合体类型";
                     break;
                 case ARTDataControllerProcessStateDidProcess:
                     self.stateLabel.stringValue = @"数据整理中...";
                     break;
                 default:
                     break;
             }
         } completion:^(ARTDataController * _Nonnull dataController) {
             self.classTreeButton.enabled = YES;
             self.relationshipTreeButton.enabled = YES;
             self.classTreeButton.selected = YES;
             self.stateLabel.stringValue = @"";
             [self.outlineViewController updateData:dataController.classNodes];
         }];
    }
}

#pragma mark - ARTOutlineViewControllerDelegate

- (void)outlineViewController:(id)outlineViewController didClickItem:(CDOCClass *)item link:(NSString *)link rightMouse:(BOOL)rightMouse
{
    if (rightMouse) {
        // TODO
    } else {
        [self.textViewController updateDataWithLink:link];
    }
}

#pragma mark - ARTTextViewControllerDelegate

- (void)textViewController:(ARTTextViewController *)textViewController didClickLink:(NSString *)link rightMouse:(BOOL)rightMouse
{
    if (rightMouse) {
        // TODO
    } else {
        [self.textViewController updateDataWithLink:link];
    }
}
@end
