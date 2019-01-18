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
#import "ARTStackController.h"
#import "ARTView.h"
#import "ARTCategoryView.h"
#import "ARTButton.h"
#import "ARTURL.h"
#import "ARTRichTextController.h"
#import "ARTFontManager.h"
#import "ARTConfigManager.h"
#import "ClassDumpExtension.h"
#import "CDClassDump.h"
#import "NSAlert+ART.h"
#import "NSColor+ART.h"

@interface NSMutableDictionary<K, V> (ARTTextViewController)
- (NSMutableDictionary<NSAttributedString *, NSMutableDictionary *> *)character;
- (NSMutableDictionary<NSNumber *, NSImage *> *)isInsideMainBundle;
@end

@interface ARTTextViewController ()
<TZRichTextControllerDelegate>
@property (weak) IBOutlet NSTextView *textView;
@property (weak) IBOutlet ARTButton *menuButton;
@property (weak) IBOutlet ARTButton *goBackButton;
@property (weak) IBOutlet ARTButton *goForwardButton;

@property (nonatomic, strong) ARTRichTextController *richTextController;
@property (nonatomic, strong) ARTStackController<NSString *> *stack;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *linkCache;
/**
 *  @{
 *      NSString *character : @{
 *          NSNumber *isInsideMainBundle : NSImage *image,
 *      }
 *  }
 */
@property (class, readonly) NSMutableDictionary<NSAttributedString */*character*/, NSMutableDictionary<NSNumber */*isInsideMainBundle*/, NSImage *> *> *imageCache;
@property (readonly) NSMenu *linkStackMenu;
@end

@implementation ARTTextViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.stack = [[ARTStackController alloc] init];
    self.linkCache = [[NSMutableDictionary alloc] init];

    self.textView.font = ARTFontManager.sharedFontManager.themeFont;

    self.richTextController = [[ARTRichTextController alloc] initWithView:self.textView];
    self.richTextController.delegate = self;

    weakifySelf();
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
    [self.goBackButton bind:NSEnabledBinding toObject:self.stack withKeyPath:@keypath(self.stack, canGoBack) options:nil];
    self.goBackButton.eventHandler = ^(__kindof ARTButton * _Nonnull button, ARTControlEventType type, NSEvent * _Nonnull event)
    {
        switch (type) {
            case ARTControlEventTypeMouseUpInside:
                [weakSelf refreshLink:[weakSelf.stack goBack]];
                break;
            default:
                break;
        }
    };

    [self.goForwardButton setImage:[NSImage imageNamed:@"Default_ARTTextViewController_goForwardButton"] forState:ARTButtonStateNormal];
    [self.goForwardButton setImage:[NSImage imageNamed:@"Default_ARTTextViewController_goForwardButton_highlighted"] forState:ARTButtonStateHighlighted];
    [self.goForwardButton setImage:[NSImage imageNamed:@"Default_ARTTextViewController_goForwardButton_disabled"] forState:ARTButtonStateDisabled];
    [self.goForwardButton bind:NSEnabledBinding toObject:self.stack withKeyPath:@keypath(self.stack, canGoForward) options:nil];
    self.goForwardButton.eventHandler = ^(__kindof ARTButton * _Nonnull button, ARTControlEventType type, NSEvent * _Nonnull event)
    {
        switch (type) {
            case ARTControlEventTypeMouseUpInside:
                [weakSelf refreshLink:[weakSelf.stack goForward]];
                break;
            default:
                break;
        }
    };

    [[ARTFontManager sharedFontManager] addObserver:self fontChangeBlock:^(NSFont * _Nonnull (^ _Nonnull updateFontBlock)(NSFont * _Nonnull)) {
        weakSelf.textView.font = updateFontBlock(weakSelf.textView.font);
    }];

    [self observe:ARTConfigManager.sharedManager
         keyPaths:@[@keypath(ARTConfigManager.sharedManager, showBundle),
                    @keypath(ARTConfigManager.sharedManager, hideComments),]
          options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
            block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change)
    {
        BOOL new = [change[NSKeyValueChangeNewKey] boolValue];
        BOOL old = [change[NSKeyValueChangeOldKey] boolValue];
        if (new != old) {
            [weakSelf.linkCache removeAllObjects];
            [weakSelf refreshLink:weakSelf.stack.currentObject];
        }
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

- (IBAction)performFindPanelAction:(id)sender
{
    [self performTextFinderAction:sender];
}

- (void)performTextFinderAction:(id)sender
{
    [self.textView performTextFinderAction:sender];
}

#pragma mark - Property

+ (NSMutableDictionary<NSAttributedString *,NSMutableDictionary<NSNumber *,NSImage *> *> *)imageCache
{
    static id imageCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageCache = [NSMutableDictionary vectorWithType:@MapType(<NSAttributedString */*character*/, NSMutableDictionary<NSNumber */*isInsideMainBundle*/, NSImage *> *>)];
    });
    return imageCache;
}

- (NSMenu *)linkStackMenu
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];

    [self.stack.menuStack enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString *link, NSUInteger idx, BOOL * _Nonnull stop)
     {
         ARTURL *url = [[ARTURL alloc] initWithString:link];
         NSString *title;
         if ([url.scheme isEqualToString:kSchemeStruct]) {
             title = url.path;
         } else if ([url.scheme isEqualToString:kSchemeUnion]) {
             title = url.path;
         } else if ([url.scheme isEqualToString:kSchemeCategory]) {
             title = [NSString stringWithFormat:@"%@ (%@)", url.host, url.path];
         } else if ([url.scheme isEqualToString:kSchemeProtocol]) {
             title = url.host;
         } else {
             title = url.host;
         }
         NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(linkStackMenuAction:) keyEquivalent:@""];
         item.target = self;
         item.representedObject = link;
         item.image = [self imageForLink:link];
         [menu addItem:item];
     }];

    return menu;
}

#pragma mark - Private

- (void)pushLink:(NSString *)link text:(NSString *)text
{
    if (!(link.length && text.length)) {
        return;
    }

    [self.stack push:link];
    self.linkCache[link] = text;
    self.richTextController.text = text;
}

- (void)refreshLink:(NSString *)link
{
    if (link) {
        [self textForLink:link needPlaceholder:YES completion:^(NSString *text) {
            self.linkCache[link] = text;
            self.richTextController.text = text;
        }];
    }
}

- (NSImage *)imageForLink:(NSString *)link
{
    ARTURL *url = [[ARTURL alloc] initWithString:link];
    NSAttributedString *character;
    BOOL isInsideMainBundle;
    if ([url.scheme isEqualToString:kSchemeStruct])
    {
        character = [[NSAttributedString alloc] initWithString:@"S"];
        isInsideMainBundle = NO;
    }
    else if ([url.scheme isEqualToString:kSchemeUnion])
    {
        character = [[NSAttributedString alloc] initWithString:@"U"];
        isInsideMainBundle = NO;
    }
    else if ([url.scheme isEqualToString:kSchemeCategory])
    {
        character = [[NSAttributedString alloc] initWithString:@"C" attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}];
        isInsideMainBundle = self.dataController.classForName(url.host).categoryForName(url.path).isInsideMainBundle;
    }
    else if ([url.scheme isEqualToString:kSchemeProtocol])
    {
        character = [[NSAttributedString alloc] initWithString:@"P"];
        isInsideMainBundle = self.dataController.allProtocols[url.host].isInsideMainBundle;
    }
    else if ([url.scheme isEqualToString:kSchemeClass])
    {
        character = [[NSAttributedString alloc] initWithString:@"C"];
        isInsideMainBundle = self.dataController.classForName(url.host).isInsideMainBundle;
    }
    else
    {
        NSAssert(0, @"handle this");
        return nil;
    }

    NSImage *image = ARTTextViewController.imageCache.character[character].isInsideMainBundle[@(isInsideMainBundle)];
    if (!image) {
        ARTCategoryView *view = [[ARTCategoryView alloc] initWithFrame:NSMakeRect(0, 0, 16, 16)];
        view.strokeColor = RGBColor(240, 240, 240);
        view.character = character;
        view.color = isInsideMainBundle ? NSColor.classColor : NSColor.otherClassColor;
        image = view.image;
        ARTTextViewController.imageCache.character[character].isInsideMainBundle[@(isInsideMainBundle)] = image;
    }

    return image;
}

- (void)textForLink:(NSString *)link needPlaceholder:(BOOL)needPlaceholder completion:(void (^)(NSString *text))completion
{
    // check cache
    NSString *text = self.linkCache[link];
    if (text) {
        completion(text);
        return;
    }
    if (needPlaceholder) {
        self.richTextController.text = _SC(@"Loading...", kColorComments);
    }

    ARTURL *url = [[ARTURL alloc] initWithString:link];
    ARTScheme scheme = url.scheme;
    NSString *host = url.host;

    if ([scheme isEqualToString:kSchemeClass])
    {
        NSString *className = host;
        CDOCClass *class = self.dataController.classForName(className);
        if (class) {
            [self stringFromData:class completion:completion];
        } else {
            [NSAlert showModalAlertWithTitle:[NSString stringWithFormat:@"未发现类 %@", className] message:[NSString stringWithFormat:@"应该是%@没有link这个类所在的库导致", self.dataController.filePath.lastPathComponent]];
            completion(nil);
        }
    }
    else if ([scheme isEqualToString:kSchemeProtocol])
    {
        NSString *protocolName = host;
        CDOCProtocol *protocol = self.dataController.allProtocols[protocolName];
        if (protocol) {
            [self stringFromData:protocol completion:completion];
        } else {
            [NSAlert showModalAlertWithTitle:[NSString stringWithFormat:@"未发现协议 %@", protocolName] message:@"一般出现于该协议没有类接受"];
            completion(nil);
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
                [self stringFromData:category completion:completion];
            } else {
                [NSAlert showModalAlertWithTitle:[NSString stringWithFormat:@"类%@未找到类别(%@)", className, categoryName] message:@"不应该出现，请提issue"];
                completion(nil);
            }
        } else {
            [NSAlert showModalAlertWithTitle:[NSString stringWithFormat:@"未找到类别(%@)所属的类%@", categoryName, className] message:@"不应该出现，请提issue"];
            completion(nil);
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
            completion([self.dataController.typeController structDisplayDescriptionWithStructureInfo:info]);
        } else {
            [NSAlert showModalAlertWithTitle:@"未找到结构体类型" message:[NSString stringWithFormat:@"%@ %@", name, typeString]];
            completion(nil);
        }
    }
    /*
    else if ([scheme isEqualToString:kSchemeBundle])
    {
        // TODO
    }
    */
    else {
        completion(nil);
    }
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

#pragma mark Action

- (void)linkStackMenuAction:(NSMenuItem *)item
{
    NSString *link = item.representedObject;
    [self updateDataWithLink:link];
}

- (IBAction)goBack:(id)sender
{
    [self refreshLink:[self.stack goBack]];
}

- (IBAction)goForward:(id)sender
{
    [self refreshLink:[self.stack goForward]];
}

#pragma mark - Public

- (void)updateDataWithLink:(NSString *)link
{
    if (self.stack.index >= 0 && [self.stack.currentObject isEqualToString:link]) {
        return;
    }

    [self textForLink:link needPlaceholder:YES completion:^(NSString *text) {
        if (text) {
            [self pushLink:link text:text];
        } else {
            [self refreshLink:self.stack.currentObject];
        }
    }];
}

#pragma mark - TZRichTextControllerDelegate

- (void)richTextController:(ARTRichTextController *)richTextController didSelectLink:(NSString *)link rightMouse:(BOOL)rightMouse
{
    if ([self.delegate respondsToSelector:@selector(textViewController:didClickLink:rightMouse:)]) {
        [self.delegate textViewController:self didClickLink:link rightMouse:rightMouse];
    }
}

@end
