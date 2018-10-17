//
//  ARTClassTreeCell.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTClassTreeCell.h"
#import "ARTURL.h"
#import "ARTRichTextController.h"
#import "ClassDumpExtension.h"
#import "CDOCClassReference.h"

@interface ARTClassTreeCell ()
<ARTRichTextControllerDelegate>
@property (weak) IBOutlet NSTextView *textView;
@property (nonatomic, strong) ARTRichTextController *richTextController;
@property (nonatomic,  weak ) CDOCClass *aClass;
@property (nonatomic,  weak ) CDOCCategory *category;
@end

@implementation ARTClassTreeCell

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib
{
    [self initialize];
}

- (void)initialize
{
    NSTextView *textView = [[NSTextView alloc] initWithFrame:self.bounds];
    textView.autoresizingMask = NSViewWidthSizable| NSViewHeightSizable;
    textView.font = [NSFont fontWithName:@"Menlo-Regular" size:18];
    textView.selectable = YES;
    textView.editable = NO;
    textView.textContainer.lineBreakMode = NSLineBreakByClipping;
    [self addSubview:textView];
    self.textView = textView;

    self.richTextController = [[ARTRichTextController alloc] initWithView:self.textView];
    self.richTextController.delegate = self;
}

- (NSString *)prefixWithCategory:(CDOCCategory *)category
{
    NSString *prefix = @"";
    CDOCClass *class = category.classRef.classObject;
    CDOCClass *node = class;

    while (node) {
        BOOL isLastNode = !node.superNode || ([node.superNode.subNodes indexOfObject:node] == (node.superNode.subNodes.count - 1));
        prefix = isLastNode ? [@" \t" stringByAppendingString:prefix] : [@"<font color=connectingLine>│</font>\t" stringByAppendingString:prefix];
        node = (CDOCClass *)node.superNode;
    }

    return [prefix stringByAppendingFormat:@"<font color=connectingLine>│</font>\t<font color=connectingLine>%@</font>", [class.categories indexOfObject:category] == (class.categories.count - 1) ? @"└" : @"├"];
}

- (NSString *)prefixWithClass:(CDOCClass *)data
{
    NSString *prefix = @"";
    CDOCClass *node = data;

    while (node.superNode) {
        node = (CDOCClass *)node.superNode;
        BOOL isLastNode = !node.superNode || ([node.superNode.subNodes indexOfObject:node] == (node.superNode.subNodes.count - 1));
        prefix = isLastNode ? [@" \t" stringByAppendingString:prefix] : [@"<font color=connectingLine>│</font>\t" stringByAppendingString:prefix];
    }

    return [prefix stringByAppendingString:[self expandButtonStringForData:data]];
}

- (NSString *)expandButtonStringForData:(CDOCClass *)data
{
    if (data.superNode) {

        BOOL isLastNode = [data.superNode.subNodes indexOfObject:data] == (data.superNode.subNodes.count - 1);

        if (data.subNodes.count) {
            if ([self.outlineView isItemExpanded:data]) {
                return [NSString stringWithFormat:@"<a href='%@://%@' color=expandButton>%@</a>", kSchemeAction, kExpandSubClassAction, isLastNode ? @"└" : @"├"];
            } else {
                return [NSString stringWithFormat:@"<a href='%@://%@' color=expandButton>%@</a>", kSchemeAction, kExpandSubClassAction, isLastNode ? @"┴" : @"┼"];
            }
        } else {
            return isLastNode ? @"<font color=connectingLine>└</font>" : @"<font color=connectingLine>├</font>";
        }
    } else {
        if ([self.outlineView isItemExpanded:data]) {
            return [NSString stringWithFormat:@"<a href='%@://%@' color=expandButton>-</a>", kSchemeAction, kExpandSubClassAction];
        } else {
            return [NSString stringWithFormat:@"<a href='%@://%@' color=expandButton>+</a>", kSchemeAction, kExpandSubClassAction];
        }
    }
}

- (NSString *)categoryLinkButtonWithData:(CDOCClass *)data
{
    return data.categories.count ? [NSString stringWithFormat:@" (<a href='%@://%@' color=%@>%ld</a>)", kSchemeAction, kExpandCategoryAction, kColorNumbers, data.categories.count] : @"";
}

#pragma mark - Public

- (CDOCProtocol *)data
{
    return self.aClass ?: self.category.classRef.classObject;
}

- (void)updateDataWithClass:(CDOCClass *)class
{
    self.aClass = class;

    self.richTextController.text = [NSString stringWithFormat:@"%@ <a href='%@://%@' color=%@>%@</a>%@", [self prefixWithClass:class], kSchemeClass, class.name, class.isInsideMainBundle ? kColorClass : kColorOtherClass, class.name, [self categoryLinkButtonWithData:class]];
}

- (void)updateDataWithCategory:(CDOCCategory *)category
{
    self.richTextController.text = [NSString stringWithFormat:@"%@ (<a href='%@://%@/%@' color=%@>%@</a>)", [self prefixWithCategory:category], kSchemeCategory, category.className, category.name, category.isInsideMainBundle ? kColorClass : kColorOtherClass, category.name];
}

#pragma mark - ARTRichTextControllerDelegate

- (void)richTextController:(ARTRichTextController *)richTextController didSelectLink:(NSString *)link rightMouse:(BOOL)rightMouse
{
    if ([self.delegate respondsToSelector:@selector(classTreeCell:didClickLink:rightMouse:)]) {
        [self.delegate classTreeCell:self didClickLink:link rightMouse:rightMouse];
    }
}

@end
