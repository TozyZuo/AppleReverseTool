//
//  ARTMainViewController.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/1.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTMainViewController.h"
#import "ARTDataController.h"
#import "ARTClassTreeViewController.h"
#import "ARTRelationshipTreeViewController.h"
#import "ARTTextViewController.h"
#import "ARTButton.h"
#import "NSColor+ART.h"

@interface ARTMainViewController ()
<
    ARTClassTreeViewControllerDelegate,
    ARTRelationshipTreeViewControllerDelegate,
    ARTTextViewControllerDelegate
>
@property (nonatomic, strong) ARTDataController *dataController;
@property (readonly) ARTClassTreeViewController *classTreeViewController;
@property (readonly) ARTRelationshipTreeViewController *relationshipTreeViewController;
@property (readonly) ARTTextViewController *textViewController;
@property (weak) IBOutlet NSTextField *stateLabel;
@property (weak) IBOutlet ARTButton *classTreeButton;
@property (weak) IBOutlet ARTButton *relationshipTreeButton;
@end

@implementation ARTMainViewController
@synthesize classTreeViewController = _classTreeViewController;
@synthesize relationshipTreeViewController = _relationshipTreeViewController;
@synthesize textViewController = _textViewController;

- (ARTClassTreeViewController *)classTreeViewController
{
    if (!_classTreeViewController) {
        for (NSViewController *vc in self.childViewControllers) {
            if ([vc isKindOfClass:ARTClassTreeViewController.class]) {
                _classTreeViewController = (ARTClassTreeViewController *)vc;
                _classTreeViewController.delegate = self;
            }
        }
    }
    return _classTreeViewController;
}

- (ARTRelationshipTreeViewController *)relationshipTreeViewController
{
    if (!_relationshipTreeViewController) {
        for (NSViewController *vc in self.childViewControllers) {
            if ([vc isKindOfClass:ARTRelationshipTreeViewController.class]) {
                _relationshipTreeViewController = (ARTRelationshipTreeViewController *)vc;
                _relationshipTreeViewController.delegate = self;
            }
        }
    }
    return _relationshipTreeViewController;
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

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.classTreeViewController.view bind:NSHiddenBinding toObject:self.classTreeButton withKeyPath:@"selected" options:@{NSValueTransformerNameBindingOption: NSNegateBooleanTransformerName}];
    [self.relationshipTreeViewController.view bind:NSHiddenBinding toObject:self.relationshipTreeButton withKeyPath:@"selected" options:@{NSValueTransformerNameBindingOption: NSNegateBooleanTransformerName}];
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

//        id c = [[NSClassFromString(@"CDOCClass") alloc] init];
//        [(NSImage *)c setName:@"NSObject"];
//        ARTDataController *dc = [[ARTDataController alloc] init];
//        dc[@"classNodes"] = @[c];
//        [self.classTreeViewController updateData:dc];
//        self.classTreeButton.enabled = YES;
//        self.classTreeButton.selected = YES;
//        self.relationshipTreeButton.enabled = YES;
//        self.dataController = dc;
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
             self.stateLabel.stringValue = @"";

             self.classTreeButton.enabled = YES;
             self.relationshipTreeButton.enabled = YES;
             [self classTreeButtonAction:self.classTreeButton];
//             [self relationshipTreeButtonAction:self.relationshipTreeButton];

             [self.classTreeViewController updateData:dataController];
             [self.relationshipTreeViewController updateData:dataController];
         }];
    }
}

#pragma mark - ARTClassTreeViewControllerDelegate

- (void)classTreeViewController:(id)classTreeViewController didClickItem:(CDOCClass *)item link:(NSString *)link rightMouse:(BOOL)rightMouse
{
    if (rightMouse) {
        // TODO
    } else {
        [self.textViewController updateDataWithLink:link];
    }
}

#pragma mark - ARTRelationshipTreeViewControllerDelegate

- (void)relationshipTreeViewController:(ARTRelationshipTreeViewController *)relationshipTreeViewController didClickItem:(id)item link:(NSString *)link rightMouse:(BOOL)rightMouse
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
