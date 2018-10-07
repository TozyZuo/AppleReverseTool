//
//  ARTClass.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/29.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTClass.h"
#import "CRNode.h"
#import "CDOCClass.h"

@interface ARTClass ()
{
    NSMutableArray *_subNodes;
}
@end
@implementation ARTClass
@synthesize superNode = _superNode;

- (instancetype)initWithClass:(CDOCClass *)class bundleName:(NSString *)bundleName
{
    self = [super init];
    if (self) {
        _subNodes = [[NSMutableArray alloc] init];
        self.className = class.name;
        self.superClassName = class.superClassName;
        self.bundleName = bundleName;
        // TODO
//        self.instanceVariables
    }
    return self;
}

- (NSString *)description
{
    return [self descriptionWithString:[NSMutableString string] node:self depth:@[]];
}

- (NSString *)descriptionWithString:(NSMutableString *)string node:(id<ARTNode>)node depth:(NSArray<NSNumber *> *)depth
{
#if 1
    [string appendFormat:@" %@\n", node.name];

    NSUInteger depthCount = depth.count;
    NSUInteger count = node.subNodes.count;
    NSArray<id<ARTNode>> *subNodes = node.subNodes;

    for (NSUInteger i = 0; i < count; i++) {

        id<ARTNode> subNode = subNodes[i];

        for (NSUInteger j = 0; j < depthCount; j++) {
            if ([depth[j] boolValue]) {
                [string appendString:@"\t│"];
            } else {
                [string appendString:@"\t "];
            }
        }

        if (i == count - 1) {
            [string appendFormat:@"\t└"];
        } else {
            [string appendFormat:@"\t├"];
        }

        [self descriptionWithString:string node:subNode depth:[depth arrayByAddingObject:i == count-1 ? @NO : @YES]];
    }
#else
    [string appendFormat:@" %@\n", node.name];
    [node.subNodes enumerateObjectsUsingBlock:^(id<ARTNode>  _Nonnull obj, BOOL * _Nonnull stop)
     {
         NSUInteger count = depth.count + 1;
         for (NSUInteger i = 0; i < count; i++) {
             [string appendString:@"\t|"];
         }

         [self descriptionWithString:string node:obj depth:[depth arrayByAddingObject:@0]];
     }];
#endif

    return string;
}

#pragma mark - ARTNode

- (NSString *)name
{
    return self.className;
}

- (NSArray<id<ARTNode>> *)subNodes
{
    return _subNodes;
}

- (void)addSubNode:(id<ARTNode>)node
{
    [_subNodes addObject:node];
}

@end
