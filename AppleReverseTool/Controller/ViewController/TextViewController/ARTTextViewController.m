//
//  ARTTextViewController.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/1.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTTextViewController.h"
#import "ARTTextViewControllerVisitor.h"
#import "ARTDataController.h"
#import "CDClassDump.h"
#import "ClassDumpExtension.h"
#import "RTLabel.h"
#import "ARTView.h"

@interface ARTTextViewController ()
<RTLabelDelegate>
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet RTLabel *label;
@property (weak) CDOCProtocol *data;
@end

@implementation ARTTextViewController

- (void)viewDidResize:(NSView *)view
{
    [self resizeLabel];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.scrollView.documentView = self.label;
    self.scrollView.contentView.documentView = self.label;

    self.label.font = [NSFont fontWithName:@"Menlo-Regular" size:18];
    self.label.delegate = self;
}

- (void)updateData:(CDOCProtocol *)data
{
    self.data = data;

    CDClassDump *classDump = [[CDClassDump alloc] init];
    ARTTextViewControllerVisitor *visitor = [[ARTTextViewControllerVisitor alloc] initWithTypeController:self.dataController.typeController dataController:self.dataController];
    visitor.classDump = classDump;
    [data recursivelyVisit:visitor];

    self.label.text = visitor.resultString;
    [self resizeLabel];
    [self.label scrollToTop];
    
//    self.label.text = [visitor.resultString stringByAppendingString:visitor.resultString];
}

- (void)updateStruct:(NSString *)structName typeString:(NSString *)typeString
{
    [self updateFromStructTable:self.dataController.typeController.structureTable name:structName typeString:typeString];
}

- (void)updateUnion:(NSString *)unionName typeString:(NSString *)typeString
{
    [self updateFromStructTable:self.dataController.typeController.unionTable name:unionName typeString:typeString];
}

- (void)updateFromStructTable:(CDStructureTable *)table name:(NSString *)name typeString:(NSString *)typeString
{
    CDStructureInfo *info = table.namedStructureInfo[name];
    if (!info) {
        info = table.nameExceptions[typeString];
        if (!info) {
            info = table.anonStructureInfo[typeString];
            if (!info) {
                info = table.anonExceptions[typeString];
                if (!info) {
                    NSAlert *alert = [[NSAlert alloc] init];
                    alert.messageText = @"未找到结构体类型";
                    alert.informativeText = [NSString stringWithFormat:@"%@ %@", name, typeString];
                    [alert runModal];
                    return;
                }
            }
        }
    }

    self.label.text = [self.dataController.typeController structDisplayDescriptionWithStructureInfo:info];
    [self resizeLabel];
}

- (void)resizeLabel
{
    self.label.height = MAX(self.label.optimumSize.height, self.scrollView.height);
}

#pragma mark - RTLabelDelegate

- (void)label:(RTLabel *)label didSelectLink:(NSString *)link rightMouse:(BOOL)rightMouse
{
    if ([self.delegate respondsToSelector:@selector(textViewController:didClickLink:rightMouse:)]) {
        [self.delegate textViewController:self didClickLink:link rightMouse:rightMouse];
    }
}

@end
