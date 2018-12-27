//
//  ARTRelationshipTreeCell.m
//  Rcode
//
//  Created by TozyZuo on 2018/10/12.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTRelationshipTreeCell.h"
#import "ARTRelationshipTreeModel.h"
#import "ARTDataController.h"
#import "ClassDumpExtension.h"
#import "CDOCInstanceVariable.h"

@interface ARTRelationshipTreeCell ()
<TZRichTextControllerDelegate>
@property (nonatomic, strong) ARTRelationshipTreeModel *data;
@end

@implementation ARTRelationshipTreeCell

#pragma mark - Public

- (void)updateData:(ARTRelationshipTreeModel *)data
{
    self.data = data;

    if (data.ivarData) {
        // ivarData must be ARTRelationshipTreeModelTypeReference
        self.richTextController.text = _S([self prefixFromData:data], [self textFromIvarData:data.ivarData], nil);
    } else if (data.classData) {
        switch (data.type) {
            case ARTRelationshipTreeModelTypeReference:
                self.richTextController.text = _S([self prefixFromData:data], [self textFromClassData:data.classData], data.showHint ? _SF(@" (%@)", _SC(@"Reference", kColorKeywords)) : nil, nil);
                break;
            case ARTRelationshipTreeModelTypeReferer:
            {
                NSString *suffix = @"";
                if (data.showHint) {
                    suffix = _SF(@" (%@)", _SC(@"Referers", kColorKeywords));
                } else if (data.classData.subClasses.count) {
                    suffix = _SF(@" (<a href='%@://%@' color=%@>%ld</a>)", kSchemeAction, kExpandSubClassAction, kColorNumbers, data.classData.subClasses.count);
                }
                self.richTextController.text = _S([self prefixFromData:data], [self textFromClassData:data.classData], suffix, nil);
            }
                break;
            case ARTRelationshipTreeModelTypeSubclass:
                self.richTextController.text = _S([self prefixFromData:data], [self textFromClassData:data.classData], data.classData.subClasses.count ? _SF(@" (<a href='%@://%@' color=%@>%ld</a>)", kSchemeAction, kExpandSubClassAction, kColorNumbers, data.classData.subClasses.count) : nil, nil);
                break;
        }
    }
}

- (NSMutableString *)lineStringForData:(ARTRelationshipTreeModel *)data
{
    if (data.superNode) {
        static unichar line1Char;
        static unichar line2Char;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            line1Char = [@"├" characterAtIndex:0];
            line2Char = [@"└" characterAtIndex:0];
        });

        NSMutableString *prefix = [self lineStringForData:data.superNode];

        if (prefix.length) {
            if ([prefix characterAtIndex:prefix.length - 1] == line1Char) {
                [prefix replaceCharactersInRange:NSMakeRange(prefix.length - 1, 1) withString:@"│"];
            } else if ([prefix characterAtIndex:prefix.length - 1] == line2Char) {
                [prefix replaceCharactersInRange:NSMakeRange(prefix.length - 1, 1) withString:@" "];
            }
        }

        [prefix appendString:@"\t"];

        switch (data.type) {
            case ARTRelationshipTreeModelTypeSubclass:
            {
                NSString *previousLine = data.superNode.canExpandeSubNodes ? @"│" : @" ";
                NSArray *subclassNodes = data.superNode.subclassNodes;
                BOOL isLast = [subclassNodes indexOfObject:data] == (subclassNodes.count - 1);
                [prefix appendFormat:@"%@\t%@", previousLine, isLast ? @"└" : @"├"];
            }
                break;
            case ARTRelationshipTreeModelTypeReference:
            case ARTRelationshipTreeModelTypeReferer:
            {
                NSArray *subNodes = data.superNode.subNodes;
                BOOL isLast = [subNodes indexOfObject:data] == (subNodes.count - 1);
                [prefix appendFormat:@"%@", isLast ? @"└" : @"├"];
            }
                break;
        }

        return prefix;
    } else {
        return [[NSMutableString alloc] init];
    }
}

- (NSString *)prefixFromData:(ARTRelationshipTreeModel *)data
{
    NSMutableString *prefix = [self lineStringForData:data];
    if (prefix.length) {
        [prefix deleteCharactersInRange:NSMakeRange(prefix.length - 1, 1)];
    }
    [prefix replaceOccurrencesOfString:@"│" withString:@"<font color=connectingLine>│</font>" options:0 range:NSMakeRange(0, prefix.length)];
    [prefix appendString:[self expandButtonStringForData:data]];
    return prefix;
}

- (NSString *)expandButtonStringForData:(ARTRelationshipTreeModel *)data
{
    if (data.superNode) {

        BOOL isLastNode = [data.superNode.subNodes indexOfObject:data] == (data.superNode.subNodes.count - 1);

        if (data.type == ARTRelationshipTreeModelTypeSubclass) {
            isLastNode = [data.superNode.subclassNodes indexOfObject:data] == (data.superNode.subclassNodes.count - 1);
        }

        if (data.canExpandeSubNodes) {
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

- (NSString *)textFromIvarData:(CDOCInstanceVariable *)ivarData
{
    NSMutableString *text = [[NSMutableString alloc] init];
    CDType *type = ivarData.type;
    type.isParsing = YES;
    [ivarData appendToString:text typeController:self.dataController.typeController];
    type.isParsing = NO;
    [text deleteCharactersInRange:NSMakeRange(0, 3)]; // delete white space
    return text;
}

@end
