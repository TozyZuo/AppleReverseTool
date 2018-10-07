//
//  ARTOutlineViewCell.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTOutlineViewCell.h"
#import "RTLabel.h"
#import "ClassDumpExtension.h"
#import "ARTClass.h"


@interface ARTOutlineViewCell ()
<RTLabelDelegate>
@property (nonatomic, strong) RTLabel *label;
@property (nonatomic,  weak ) CDOCClass *data;
@property (nonatomic,  weak ) id closureTarget;
@property (nonatomic, assign) SEL closureAction;
@end

@implementation ARTOutlineViewCell

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
    self.label = [[RTLabel alloc] initWithFrame:self.bounds];
    self.label.delegate = self;
    self.label.font = [NSFont fontWithName:@"Menlo-Regular" size:18];
    self.label.lineBreakMode = RTTextLineBreakModeCharWrapping;
    self.label.autoresizingMask = NSViewWidthSizable| NSViewHeightSizable;
    [self addSubview:self.label];
}

- (void)updateData:(CDOCClass *)data
{
    self.data = data;

    self.label.text = [NSString stringWithFormat:@"%@ <a href='%@://%@' color=%@>%@</a>", [self prefixWithData:data], kSchemeClass, data.name, data.isInsideMainBundle ? kColorClass : kColorOtherClass, data.name];

//    self.label.text = @"<font color=class><a href=ddd://sss>objc</a></font>";
}

- (NSString *)prefixWithData:(CDOCClass *)data
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
                return [NSString stringWithFormat:@"<a href='%@://%@' color=expandButton>%@</a>", kSchemeAction, kClosureAction, isLastNode ? @"└" : @"├"];
            } else {
                return [NSString stringWithFormat:@"<a href='%@://%@' color=expandButton>%@</a>", kSchemeAction, kClosureAction, isLastNode ? @"┴" : @"┼"];
            }
        } else {
            return isLastNode ? @"<font color=connectingLine>└</font>" : @"<font color=connectingLine>├</font>";
        }
    } else {
        if ([self.outlineView isItemExpanded:data]) {
            return [NSString stringWithFormat:@"<a href='%@://%@' color=expandButton>-</a>", kSchemeAction, kClosureAction];
        } else {
            return [NSString stringWithFormat:@"<a href='%@://%@' color=expandButton>+</a>", kSchemeAction, kClosureAction];
        }
    }
}

#pragma mark - RTLabelDelegate

- (void)label:(RTLabel *)label didSelectLinkWithURL:(NSURL *)url rightMouse:(BOOL)rightMouse
{
    if ([url.scheme isEqualToString:kSchemeAction]) {
        if ([url.host isEqualToString:kClosureAction]) {
            CDOCClass *data = self.data;
            if ([self.outlineView isItemExpanded:data]) {
                [self.outlineView collapseItem:data];
            } else {
                [self.outlineView expandItem:data];
            }
            [self updateData:self.data];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(outlineViewCell:didClickLinkWithURL:rightMouse:)]) {
            [self.delegate outlineViewCell:self didClickLinkWithURL:url rightMouse:rightMouse];
        }
    }
}

@end
