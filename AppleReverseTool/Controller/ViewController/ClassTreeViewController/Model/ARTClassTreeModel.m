//
//  ARTClassTreeModel.m
//  Rcode
//
//  Created by TozyZuo on 2018/12/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTClassTreeModel.h"
#import "ARTConfigManager.h"
#import "ARTRichTextController.h"
#import "ClassDumpExtension.h"
#import "NSColor+ART.h"

@interface ARTClassTreeModelClass : ARTClassTreeModel
@end

@interface ARTClassTreeModelCategory : ARTClassTreeModel
@end

@interface ARTClassTreeModel ()
@property (nonatomic, strong) __kindof CDOCProtocol *data;
- (instancetype)initWithdata:(__kindof CDOCProtocol *)data;
@end

@implementation ARTClassTreeModel

+ (instancetype)modelWithData:(CDOCClass *)data
{
    if ([data isKindOfClass:CDOCClass.class]) {
        return [[ARTClassTreeModelClass alloc] initWithdata:data];
    } else if ([data isKindOfClass:CDOCCategory.class]) {
        return [[ARTClassTreeModelCategory alloc] initWithdata:data];
    }

    return nil;
}

- (instancetype)initWithdata:(__kindof CDOCProtocol *)data
{
    self = [super init];
    if (self) {
        self.data = data;
    }
    return self;
}

- (void)setFilterConditionText:(NSString *)filterConditionText
{
    if (![_filterConditionText isEqualToString:filterConditionText]) {
        _filterConditionText = filterConditionText;
        self.richTextController.filterConditionText = filterConditionText;
    }
}

- (void)setRichTextController:(ARTRichTextController *)richTextController
{
    _richTextController = richTextController;
    richTextController.text = self.text;
    richTextController.filterConditionText = self.filterConditionText;
}

@end


@interface ARTClassTreeModelClass ()
@property (nonatomic, strong) CDOCClass *data;
@end

@implementation ARTClassTreeModelClass
@dynamic data;

- (NSString *)text
{
    CDOCClass *data = self.data;
    return _S([self prefixWithClass:data], _CL(data), _BL(data), [self categoryLinkButtonWithData:data isFiltered:self.filterConditionText.length totalCount:data.categories.count], nil);
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
            if (self.expanded) {
                return [NSString stringWithFormat:@"<a href='%@://%@' color=expandButton>%@</a>", kSchemeAction, kExpandSubClassAction, isLastNode ? @"└" : @"├"];
            } else {
                return [NSString stringWithFormat:@"<a href='%@://%@' color=expandButton>%@</a>", kSchemeAction, kExpandSubClassAction, isLastNode ? @"┴" : @"┼"];
            }
        } else {
            return isLastNode ? @"<font color=connectingLine>└</font>" : @"<font color=connectingLine>├</font>";
        }
    } else {
        if (self.expanded) {
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

@end


@interface ARTClassTreeModelCategory ()

@property (nonatomic, strong) CDOCCategory *data;
@end

@implementation ARTClassTreeModelCategory
@dynamic data;

- (NSString *)text
{
    CDOCCategory *category = self.data;
    return _SF(@"%@(%@%@)", [self prefixWithCategory:category], _CGL(category), _BL(category));
}

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

    return [prefix stringByAppendingFormat:@"<font color=connectingLine>│</font>\t<font color=#%@>%@</font> ", [NSColor.connectingLineColor blendedColorWithFraction:.5 ofColor:NSColor.numbersColor].hexValue, [class.categories indexOfObject:category] == (class.categories.count - 1) ? @"└" : @"├"];
}


@end
