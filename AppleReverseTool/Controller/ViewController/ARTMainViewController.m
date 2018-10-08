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
#import "CDOCClass.h"

@interface ARTMainViewController ()
<ARTOutlineViewControllerDelegate, ARTTextViewControllerDelegate>
@property (nonatomic, strong) ARTDataController *dataController;
@property (readonly) ARTOutlineViewController *outlineViewController;
@property (readonly) ARTTextViewController *textViewController;
@property IBOutlet NSTextField *stateLabel;
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
    // Do view setup here.
}

- (void)setFileURL:(NSURL *)fileURL
{
    if (!_fileURL && fileURL) {
        _fileURL = fileURL;

//        [self.outlineViewController updateData:nil];
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
                 case ARTDataControllerProcessStateDidProcess:
                     self.stateLabel.stringValue = @"数据整理中...";
                     break;
                 default:
                     break;
             }
         } completion:^(ARTDataController * _Nonnull dataController) {
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
