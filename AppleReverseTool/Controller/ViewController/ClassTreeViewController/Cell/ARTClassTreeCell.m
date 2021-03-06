//
//  ARTClassTreeCell.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTClassTreeCell.h"
#import "ARTURL.h"
#import "ARTConfigManager.h"
#import "ClassDumpExtension.h"
#import "NSColor+ART.h"

@interface ARTClassTreeCell ()
<TZRichTextControllerDelegate>
@property (nonatomic,  weak ) CDOCClass *aClass;
@property (nonatomic,  weak ) CDOCCategory *category;
@end

@implementation ARTClassTreeCell

- (NSString *)prefixWithCategory:(CDOCCategory *)category
{
    NSString *prefix = @"";
    CDOCClass *class = category.classReference;
    CDOCClass *node = class;

    while (node) {
        BOOL isLastNode = !node.superNode || ([node.superNode.subNodes indexOfObject:node] == (node.superNode.subNodes.count - 1));
        prefix = isLastNode ? [@" \t" stringByAppendingString:prefix] : [@"<font color=connectingLine>│</font>\t" stringByAppendingString:prefix];
        node = (CDOCClass *)node.superNode;
    }

    return [prefix stringByAppendingFormat:@"<font color=connectingLine>│</font>\t<font color=numbers>%@</font> ", [class.categories indexOfObject:category] == (class.categories.count - 1) ? @"└" : @"├"];
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

    return [prefix stringByAppendingFormat:@"%@ ", [self expandButtonStringForData:data]];
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

- (NSString *)categoryLinkButtonWithData:(CDOCClass *)data isFiltered:(BOOL)isFiltered totalCount:(NSUInteger)totalCount
{
    return data.categories.count ? [NSString stringWithFormat:@" (<a href='%@://%@' color=%@>%@</a>)", kSchemeAction, kExpandCategoryAction, kColorNumbers, isFiltered ? [NSString stringWithFormat:@"%ld/%ld", data.categories.count, totalCount] : [NSString stringWithFormat:@"%ld", data.categories.count]] : @"";
}

#pragma mark - Public

- (CDOCProtocol *)data
{
    return self.aClass ?: self.category.classReference;
}

- (void)updateDataWithClass:(CDOCClass *)class filterConditionText:(NSString *)filterConditionText totalCategoriesCount:(NSUInteger)totalCategoriesCount
{
    self.category = nil;
    self.aClass = class;

    self.richTextController.text = _S([self prefixWithClass:class], _CL(class), _BL(class), [self categoryLinkButtonWithData:class isFiltered:filterConditionText.length totalCount:totalCategoriesCount], nil);

    self.richTextController.filterConditionText = filterConditionText;
}

- (void)updateDataWithCategory:(CDOCCategory *)category filterConditionText:(NSString *)filterConditionText
{
    self.aClass = nil;
    self.category = category;

//    self.richTextController.text = _S([self prefixWithCategory:category], @"(", _CGL(category), _BL(category),@")", nil);
    self.richTextController.text = _SF(@"%@(%@%@)", [self prefixWithCategory:category], _CGL(category), _BL(category));

    self.richTextController.filterConditionText = filterConditionText;
}

@end
