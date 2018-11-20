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
#import "ARTRichTextController.h"
#import "ARTFontManager.h"
#import "ClassDumpExtension.h"
#import "CDClassDump.h"
#import "NSAlert+ART.h"

@interface ARTTextViewController ()
<ARTRichTextControllerDelegate>
@property (weak) IBOutlet NSTextView *textView;
@property (weak) IBOutlet ARTButton *menuButton;
@property (weak) IBOutlet ARTButton *goBackButton;
@property (weak) IBOutlet ARTButton *goForwardButton;

@property (nonatomic, strong) ARTRichTextController *richTextController;
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

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.menuStack = [[NSMutableArray alloc] init];
    self.linkStack = [[NSMutableArray alloc] init];
    self.linkMap = [[NSMutableDictionary alloc] init];
    self.maxCount = ULONG_MAX;
    self.currentLinkIndex = -1;

    // storyboard does not work?
    self.textView.font = NSFontManager.sharedFontManager.selectedFont;

    self.richTextController = [[ARTRichTextController alloc] initWithView:self.textView];
    self.richTextController.delegate = self;

    __weak typeof(self) weakSelf = self;
    [self.menuButton setImage:[NSImage imageNamed:@"Default_ARTTextViewController_showAllButtion"] forState:ARTButtonStateNormal];
    [self.menuButton setImage:[NSImage imageNamed:@"Default_ARTTextViewController_showAllButtion_highlighted"] forState:ARTButtonStateHighlighted];
    self.menuButton.eventHandler = ^(__kindof ARTButton * _Nonnull button, ARTControlEventType type, NSEvent * _Nonnull event)
    {
        switch (type) {
            case ARTControlEventTypeMouseUpInside:
                [NSMenu popUpContextMenu:weakSelf.linkStackMenu withEvent:event forView:button];
                break;
            default:
                break;
        }
    };

    [self.goBackButton setImage:[NSImage imageNamed:@"Default_ARTTextViewController_goBackButton"] forState:ARTButtonStateNormal];
    [self.goBackButton setImage:[NSImage imageNamed:@"Default_ARTTextViewController_goBackButton_highlighted"] forState:ARTButtonStateHighlighted];
    [self.goBackButton setImage:[NSImage imageNamed:@"Default_ARTTextViewController_goBackButton_disabled"] forState:ARTButtonStateDisabled];
    [self.goBackButton bind:NSEnabledBinding toObject:self withKeyPath:NSStringFromSelector(@selector(canGoBack)) options:nil];
    self.goBackButton.eventHandler = ^(__kindof ARTButton * _Nonnull button, ARTControlEventType type, NSEvent * _Nonnull event)
    {
        switch (type) {
            case ARTControlEventTypeMouseUpInside:
                [weakSelf goBack:button];
                break;
            default:
                break;
        }
    };

    [self.goForwardButton setImage:[NSImage imageNamed:@"Default_ARTTextViewController_goForwardButton"] forState:ARTButtonStateNormal];
    [self.goForwardButton setImage:[NSImage imageNamed:@"Default_ARTTextViewController_goForwardButton_highlighted"] forState:ARTButtonStateHighlighted];
    [self.goForwardButton setImage:[NSImage imageNamed:@"Default_ARTTextViewController_goForwardButton_disabled"] forState:ARTButtonStateDisabled];
    [self.goForwardButton bind:NSEnabledBinding toObject:self withKeyPath:NSStringFromSelector(@selector(canGoForward)) options:nil];
    self.goForwardButton.eventHandler = ^(__kindof ARTButton * _Nonnull button, ARTControlEventType type, NSEvent * _Nonnull event)
    {
        switch (type) {
            case ARTControlEventTypeMouseUpInside:
                [weakSelf goForward:button];
                break;
            default:
                break;
        }
    };

    [[ARTFontManager sharedFontManager] addObserver:self fontChangeBlock:^(NSFont * _Nonnull (^ _Nonnull updateFontBlock)(NSFont * _Nonnull)) {
        weakSelf.textView.font = updateFontBlock(weakSelf.textView.font);
    }];
}

- (void)swipeWithEvent:(NSEvent *)event
{
    if (event.deltaX < 0) {
        [self goForward:nil];
    } else if (event.deltaX > 0) {
        [self goBack:nil];
    }
}

- (void)willChangeLinkStack
{

}

- (void)didChangeLinkStack
{
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
//        NSImage *image; TODO
         if ([url.scheme isEqualToString:kSchemeStruct]) {
             title = [@"[S] " stringByAppendingString:url.path];
         } else if ([url.scheme isEqualToString:kSchemeUnion]) {
             title = [@"[U] " stringByAppendingString:url.path];
         } else if ([url.scheme isEqualToString:kSchemeCategory]) {
             title = [NSString stringWithFormat:@"[C] %@ (%@)", url.host, url.path];
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
        self.richTextController.text = self.linkMap[link];

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
        self.richTextController.text = self.linkMap[link];

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

    self.richTextController.text = text;
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

- (void)linkStackMenuAction:(NSMenuItem *)item
{
    NSString *link = item.representedObject;
    [self pushLink:link text:self.linkMap[link]];
}

#pragma mark - Public

- (void)updateDataWithLink:(NSString *)link
{
    if (self.currentLinkIndex >= 0 && [self.linkStack[self.currentLinkIndex] isEqualToString:link]) {
        return;
    }

    // check cache
    if (self.linkMap[link]) {
        [self pushLink:link text:self.linkMap[link]];
        return;
    }

    ARTURL *url = [[ARTURL alloc] initWithString:link];
    ARTScheme scheme = url.scheme;
    NSString *host = url.host;

    if ([scheme isEqualToString:kSchemeClass])
    {
        NSString *className = host;
        CDOCClass *class = self.dataController.classForName(className);
        if (class) {
            self.richTextController.text = _SC(@"Loading...", kColorComments);
            [self stringFromData:class completion:^(NSString *text) {
                [self pushLink:link text:text];
            }];
        } else {
            [NSAlert showModalAlertWithTitle:[NSString stringWithFormat:@"未发现类 %@", className] message:[NSString stringWithFormat:@"应该是%@没有link这个类所在的库导致", self.dataController.filePath.lastPathComponent]];
        }
    }
    else if ([scheme isEqualToString:kSchemeProtocol])
    {
        NSString *protocolName = host;
        CDOCProtocol *protocol = self.dataController.allProtocols[protocolName];
        if (protocol) {
            self.richTextController.text = _SC(@"Loading...", kColorComments);
            [self stringFromData:protocol completion:^(NSString *text) {
                [self pushLink:link text:text];
            }];
        } else {
            [NSAlert showModalAlertWithTitle:[NSString stringWithFormat:@"未发现协议 %@", protocolName] message:@"一般出现于该协议没有类接受"];
        }
    }
    else if ([scheme isEqualToString:kSchemeCategory])
    {
        NSString *className = host;
        NSString *categoryName = url.path;
        CDOCClass *class = self.dataController.classForName(className);
        if (class) {
            CDOCCategory *category = nil;
            for (CDOCCategory *oneCategory in class.categories) {
                if ([oneCategory.name isEqualToString:categoryName]) {
                    category = oneCategory;
                    break;
                }
            }
            if (category) {
                self.richTextController.text = _SC(@"Loading...", kColorComments);
                [self stringFromData:category completion:^(NSString *text) {
                    [self pushLink:link text:text];
                }];
            } else {
                [NSAlert showModalAlertWithTitle:[NSString stringWithFormat:@"类%@未找到类别(%@)", className, categoryName] message:@"不应该出现，请提issue"];
            }
        } else {
            [NSAlert showModalAlertWithTitle:[NSString stringWithFormat:@"未找到类别(%@)所属的类%@", categoryName, className] message:@"不应该出现，请提issue"];
        }
    }
    else if ([scheme isEqualToString:kSchemeStruct] || [scheme isEqualToString:kSchemeUnion])
    {
        CDStructureTable *table = self.dataController.typeController.structureTable;
        if ([scheme isEqualToString:kSchemeUnion]) {
            table = self.dataController.typeController.unionTable;
        }

        NSString *name = url.path;
        NSString *typeString = host;

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

#pragma mark - ARTRichTextControllerDelegate

- (void)richTextController:(ARTRichTextController *)richTextController didSelectLink:(NSString *)link rightMouse:(BOOL)rightMouse
{
    if ([self.delegate respondsToSelector:@selector(textViewController:didClickLink:rightMouse:)]) {
        [self.delegate textViewController:self didClickLink:link rightMouse:rightMouse];
    }
}

@end
