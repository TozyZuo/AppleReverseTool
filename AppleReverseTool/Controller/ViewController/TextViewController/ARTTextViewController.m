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
#import "ARTView.h"
#import "ARTButton.h"
#import "ARTURL.h"
#import "CDClassDump.h"
#import "ClassDumpExtension.h"
#import "RTLabel.h"
#import "NSAlert+ART.h"

@interface ARTTextViewController ()
<RTLabelDelegate>
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet RTLabel *label;
@property (weak) IBOutlet ARTButton *menuButton;

@property (nonatomic, strong) NSMutableArray<NSString *> *menuStack;
@property (nonatomic, strong) NSMutableArray<NSString *> *linkStack;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *linkMap;
@property (nonatomic, assign) NSUInteger maxCount;
@property (nonatomic, assign) NSInteger currentLinkIndex;
@property (nonatomic, assign) BOOL canGoBack;
@property (nonatomic, assign) BOOL canGoForward;
@property (readonly) NSMenu *linkStackMenu;
@end

@implementation ARTTextViewController

- (void)viewDidResize:(NSView *)view
{
    [self resizeLabel];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.menuStack = [[NSMutableArray alloc] init];
    self.linkStack = [[NSMutableArray alloc] init];
    self.linkMap = [[NSMutableDictionary alloc] init];
    self.maxCount = ULONG_MAX;
    self.currentLinkIndex = -1;

    self.scrollView.documentView = self.label;
    self.scrollView.contentView.documentView = self.label;

    self.label.font = [NSFont fontWithName:@"Menlo-Regular" size:18];
    self.label.delegate = self;
#if 0
    self.menuButton.eventHandler = ^(__kindof ARTButton * _Nonnull button, ARTButtonEventType type, NSEvent * _Nonnull event)
    {
        switch (type) {
            case ARTButtonEventTypeMouseIn:
                NSLog(@"ARTButtonEventTypeMouseIn");
                break;
            case ARTButtonEventTypeMouseOut:
                NSLog(@"ARTButtonEventTypeMouseOut");
                break;
            case ARTButtonEventTypeMouseDown:
                NSLog(@"ARTButtonEventTypeMouseDown");
                break;
            case ARTButtonEventTypeRightMouseDown:
                NSLog(@"ARTButtonEventTypeRightMouseDown");
                break;
            case ARTButtonEventTypeMouseUpOutside:
                NSLog(@"ARTButtonEventTypeMouseUpOutside");
                break;
            case ARTButtonEventTypeRightMouseUpOutside:
                NSLog(@"ARTButtonEventTypeRightMouseUpOutside");
                break;
            case ARTButtonEventTypeMouseUpInside:
                NSLog(@"ARTButtonEventTypeMouseUpInside");
                break;
            case ARTButtonEventTypeRightMouseUpInside:
                NSLog(@"ARTButtonEventTypeRightMouseUpInside");
                break;
            default:
                break;
        }
    };
#endif
}

- (void)willChangeLinkStack
{

}

- (void)didChangeLinkStack
{
    [self resizeLabel];
    [self.label scrollToTop];
    // trigger button state change
    self.canGoBack = self.canGoBack;
    self.canGoForward = self.canGoForward;
}

#pragma mark - Property

- (BOOL)canGoBack
{
    return self.currentLinkIndex - 1 >= 0;
}

- (BOOL)canGoForward
{
    return self.currentLinkIndex + 1 < self.linkStack.count;
}

- (NSMenu *)linkStackMenu
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];

    [self.menuStack enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString *link, NSUInteger idx, BOOL * _Nonnull stop)
     {
         ARTURL *url = [[ARTURL alloc] initWithString:link];
         NSString *title;
//        NSImage *image;
         if ([url.scheme isEqualToString:kSchemeStruct]) {
             title = [@"[S] " stringByAppendingString:url.path];
         } else if ([url.scheme isEqualToString:kSchemeUnion]) {
             title = [@"[U] " stringByAppendingString:url.path];
         } else {
             title = [@"[C] " stringByAppendingString:url.host];
         }
         NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(linkStackMenuAction:) keyEquivalent:@""];
         item.target = self;
         item.representedObject = link;
         [menu addItem:item];
     }];

    return menu;
}

#pragma mark - Private

- (void)menuStackHandleLink:(NSString *)link
{
    [self.menuStack removeObject:link];
    [self.menuStack addObject:link];
}


- (IBAction)goBack:(id)sender
{
    if (self.canGoBack) {
        [self willChangeLinkStack];

        self.currentLinkIndex = self.currentLinkIndex - 1;
        NSString *link = self.linkStack[self.currentLinkIndex];
        [self menuStackHandleLink:link];
        self.label.text = self.linkMap[link];

        [self didChangeLinkStack];
    }
}

- (IBAction)goForward:(id)sender
{
    if (self.canGoForward) {
        [self willChangeLinkStack];

        self.currentLinkIndex = self.currentLinkIndex + 1;
        NSString *link = self.linkStack[self.currentLinkIndex];
        [self menuStackHandleLink:link];
        self.label.text = self.linkMap[link];

        [self didChangeLinkStack];
    }
}

- (void)pushLink:(NSString *)link text:(NSString *)text
{
    [self willChangeLinkStack];

    [self menuStackHandleLink:link];

    while (self.currentLinkIndex < self.linkStack.count - 1) {
        [self.linkStack removeLastObject];
    }
    [self.linkStack addObject:link];
    if (self.linkStack.count > self.maxCount) {
        [self.linkStack removeObjectAtIndex:0];
    }
    self.linkMap[link] = text;
//    self.currentLinkIndex = self.currentLinkIndex + 1;
    self.currentLinkIndex = self.linkStack.count - 1;

    self.label.text = text;
    [self didChangeLinkStack];
}

- (void)stringFromData:(CDOCProtocol *)data completion:(void (^)(NSString *text))completion
{
    if (completion) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            CDClassDump *classDump = [[CDClassDump alloc] init];
            ARTTextViewControllerVisitor *visitor = [[ARTTextViewControllerVisitor alloc] initWithTypeController:self.dataController.typeController dataController:self.dataController];
            visitor.classDump = classDump;
            [data recursivelyVisit:visitor];
            NSString *text = visitor.resultString;
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(text);
            });
        });
    }
}

- (void)resizeLabel
{
    self.label.height = MAX(self.label.optimumSize.height, self.scrollView.height - 40);
    self.canGoBack = self.canGoBack;
}

- (void)linkStackMenuAction:(NSMenuItem *)item
{
    NSString *link = item.representedObject;
    [self pushLink:link text:self.linkMap[link]];
}

- (IBAction)showLinkStackMenuAction:(NSButton *)sender
{
    [NSMenu popUpContextMenu:self.linkStackMenu withEvent:NSApp.currentEvent forView:sender];
}

#pragma mark - Public

- (void)updateDataWithLink:(NSString *)link
{
    // check cache
    if (self.linkMap[link]) {
//        [self pushLink:link text:self.linkMap[link]];
//        return;
    }

    ARTURL *url = [[ARTURL alloc] initWithString:link];
    ARTScheme scheme = url.scheme;
    NSString *value = url.host;

    if ([scheme isEqualToString:kSchemeClass])
    {
        CDOCClass *class = self.dataController.classForName(value);
        if (class) {
            self.label.text = _SC(@"Loading...", kColorComments);
            [self stringFromData:class completion:^(NSString *text) {
                [self pushLink:link text:text];
            }];
        } else {
            [NSAlert showModalAlertWithTitle:[NSString stringWithFormat:@"未发现类 %@", value] message:[NSString stringWithFormat:@"应该是%@没有link这个类所在的库导致", self.dataController.filePath.lastPathComponent]];
        }
    }
    else if ([scheme isEqualToString:kSchemeProtocol])
    {
        CDOCProtocol *protocol = self.dataController.allProtocols[value];
        if (protocol) {
            self.label.text = _SC(@"Loading...", kColorComments);
            [self stringFromData:protocol completion:^(NSString *text) {
                [self pushLink:link text:text];
            }];
        } else {
            [NSAlert showModalAlertWithTitle:[NSString stringWithFormat:@"未发现协议 %@", value] message:@"一般出现于该协议没有类接受"];
        }
    }
    else if ([scheme isEqualToString:kSchemeStruct] || [scheme isEqualToString:kSchemeUnion])
    {
        CDStructureTable *table = self.dataController.typeController.structureTable;
        if ([scheme isEqualToString:kSchemeUnion]) {
            table = self.dataController.typeController.unionTable;
        }

        NSString *name = url.path;
        NSString *typeString = value;

        CDStructureInfo *info = table.namedStructureInfo[name];
        if (!info) {
            info = table.nameExceptions[typeString];
            if (!info) {
                info = table.anonStructureInfo[typeString];
                if (!info) {
                    info = table.anonExceptions[typeString];
                }
            }
        }

        if (info) {
            NSString *text = [self.dataController.typeController structDisplayDescriptionWithStructureInfo:info];
            [self pushLink:link text:text];
        } else {
            [NSAlert showModalAlertWithTitle:@"未找到结构体类型" message:[NSString stringWithFormat:@"%@ %@", name, typeString]];
        }
    }
}

#pragma mark - RTLabelDelegate

- (void)label:(RTLabel *)label didSelectLink:(NSString *)link rightMouse:(BOOL)rightMouse
{
    if ([self.delegate respondsToSelector:@selector(textViewController:didClickLink:rightMouse:)]) {
        [self.delegate textViewController:self didClickLink:link rightMouse:rightMouse];
    }
}

@end
