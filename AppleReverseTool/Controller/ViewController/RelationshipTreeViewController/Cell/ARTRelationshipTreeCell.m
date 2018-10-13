//
//  ARTRelationshipTreeCell.m
//  Rcode
//
//  Created by TozyZuo on 2018/10/12.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTRelationshipTreeCell.h"
#import "RTLabel.h"
#import "ARTRelationshipTreeModel.h"
#import "ARTDataController.h"
#import "ClassDumpExtension.h"
#import "CDOCInstanceVariable.h"


@interface ARTRelationshipTreeCell ()
<RTLabelDelegate>
@property (nonatomic, strong) RTLabel *label;
@property (nonatomic, strong) ARTRelationshipTreeModel *data;
@end

@implementation ARTRelationshipTreeCell

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

#pragma mark - Public

- (void)updateData:(ARTRelationshipTreeModel *)data
{
    self.data = data;

    if (data.iVarData) {
        self.label.text = _S([self prefixFromData:data], [self textFromiVarData:data.iVarData], nil);
    } else if (data.classData) {
        self.label.text = _S([self prefixFromData:data], [self textFromClassData:data.classData], nil);
    }
}

- (NSString *)prefixFromData:(ARTRelationshipTreeModel *)data
{
    NSString *prefix = @"";
    ARTRelationshipTreeModel *node = data;

    while (node.superNode) {
        node = (ARTRelationshipTreeModel *)node.superNode;
        BOOL isLastNode = !node.superNode || ([node.superNode.subNodes indexOfObject:node] == (node.superNode.subNodes.count - 1));
        prefix = isLastNode ? [@" \t" stringByAppendingString:prefix] : [@"<font color=connectingLine>│</font>\t" stringByAppendingString:prefix];
    }

    return [prefix stringByAppendingString:[self expandButtonStringForData:data]];
}

- (NSString *)expandButtonStringForData:(ARTRelationshipTreeModel *)data
{
    if (data.superNode) {

        BOOL isLastNode = [data.superNode.subNodes indexOfObject:data] == (data.superNode.subNodes.count - 1);

        if (data.canBeExpanded) {
            if ([self.outlineView isItemExpanded:data]) {
                return [NSString stringWithFormat:@"<a href='%@://%@' color=expandButton>%@</a>", kSchemeAction, kExpandSubNodeAction, isLastNode ? @"└" : @"├"];
            } else {
                return [NSString stringWithFormat:@"<a href='%@://%@' color=expandButton>%@</a>", kSchemeAction, kExpandSubNodeAction, isLastNode ? @"┴" : @"┼"];
            }
        } else {
            return isLastNode ? @"<font color=connectingLine>└</font>" : @"<font color=connectingLine>├</font>";
        }
    } else {
        if (data.canBeExpanded) {
            if ([self.outlineView isItemExpanded:data]) {
                return [NSString stringWithFormat:@"<a href='%@://%@' color=expandButton>-</a>", kSchemeAction, kExpandSubNodeAction];
            } else {
                return [NSString stringWithFormat:@"<a href='%@://%@' color=expandButton>+</a>", kSchemeAction, kExpandSubNodeAction];
            }
        } else {
            return _SC(@"-", kColorConnectingLine);
        }
    }
}

- (NSString *)textFromClassData:(CDOCClass *)classData
{
    return [NSString stringWithFormat:@" <a href='%@://%@' color=%@>%@</a>", kSchemeClass, classData.name, classData.isInsideMainBundle ? kColorClass : kColorOtherClass, classData.name];
}

- (NSString *)textFromiVarData:(CDOCInstanceVariable *)iVarData
{
    NSMutableString *text = [[NSMutableString alloc] init];
    CDType *type = iVarData.type;
    type.isParsing = YES;
    [iVarData appendToString:text typeController:self.dataController.typeController];
    type.isParsing = NO;
    [text deleteCharactersInRange:NSMakeRange(0, 3)];
    return text;
}

#pragma mark - RTLabelDelegate

- (void)label:(RTLabel *)label didSelectLink:(NSString *)link rightMouse:(BOOL)rightMouse
{
    if ([self.delegate respondsToSelector:@selector(relationshipTreeCell:didClickLink:rightMouse:)]) {
        [self.delegate relationshipTreeCell:self didClickLink:link rightMouse:rightMouse];
    }
}

@end
