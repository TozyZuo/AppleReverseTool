//
//  CRNode.m
//  ClassGraph
//
//  Created by TozyZuo on 2017/8/17.
//  Copyright © 2017年 TozyZuo. All rights reserved.
//

#import "CRNode.h"
#import <objc/runtime.h>

@interface ARTDefaultNode : NSObject
<ARTNode>
{
    NSMutableSet *_subNodes;
}
@end
@implementation ARTDefaultNode
@synthesize name = _name;
@synthesize superNode = _superNode;

- (instancetype)initWithName:(NSString *)name superNode:(id<ARTNode>)superNode
{
    self = [super init];
    if (self) {
        _name = name;
        _superNode = superNode;
        _subNodes = [[NSMutableSet alloc] init];
    }
    return self;
}

- (NSSet<id<ARTNode>> *)subNodes
{
    return _subNodes;
}

- (void)addSubNode:(id<ARTNode>)node
{
    [_subNodes addObject:node];
}

- (NSString *)description
{
    return DescriptionWithNodes(@[self]);
}

@end

@interface ARTDefaultNodeProvider : NSObject
<ARTNodeProvider>
@property (nonatomic, strong) NSBundle *bundle;
- (instancetype)initWithBundle:(NSBundle *)bundle;
@end
@implementation ARTDefaultNodeProvider

- (instancetype)initWithBundle:(NSBundle *)bundle
{
    self = [super init];
    if (self) {
        self.bundle = bundle;
    }
    return self;
}

- (Class)nodeClass
{
    return ARTDefaultNode.class;
}

- (NSArray<NSString *> *)nodeNames
{
    NSBundle *bundle = self.bundle;
    NSString *bundleName = bundle.executableURL.absoluteString.lastPathComponent;
    NSMutableArray *classes = [[NSMutableArray alloc] init];

    UInt count = 0;
    Class *allClass = objc_copyClassList(&count);

    for (int i = 0; i < count; i++) {

        Class class = allClass[i];
        if (!bundle || [[@(class_getImageName(class) ?: "") lastPathComponent] isEqualToString:bundleName])
        {
            [classes addObject:NSStringFromClass(class)];
        }
    }

    free(allClass);

    return classes;
}

- (NSString *)superNodeNameForNodeName:(NSString *)name
{
    return NSStringFromClass(class_getSuperclass(NSClassFromString(name)));
}

@end

NSMutableDictionary<NSString *, id<ARTNode>> *_nodeMap;


id<ARTNode> NodeForName(NSString *nodeName, id<ARTNodeProvider> provider, NSMutableArray *result)
{
    NSString *superNodeName = [provider superNodeNameForNodeName:nodeName];

    if (!superNodeName || [superNodeName isEqualToString:nodeName]) {
        id<ARTNode> rootNode = [[provider.nodeClass alloc] initWithName:nodeName superNode:nil];
        _nodeMap[nodeName] = rootNode;
        [result addObject:rootNode];
        return rootNode;
    }

    id<ARTNode> superNode = _nodeMap[superNodeName];
    if (!superNode) {
        superNode = NodeForName(superNodeName, provider, result);
    }
    id<ARTNode> node = [[provider.nodeClass alloc] initWithName:nodeName superNode:superNode];

    node.superNode = superNode;
    [superNode addSubNode:node];
    _nodeMap[nodeName] = node;

    return node;
}

void CacheNode(id<ARTNode> node, id<ARTNodeProvider> provider, NSMutableArray *result)
{
    if ([node.name isEqualToString:@"HAHConfigParser"]) {

    }
    id<ARTNode> superNode = [provider superNodeForNode:node];

    if (!superNode || [superNode isEqual:node]) {
        _nodeMap[node.name] = node;
        [result addObject:node];
        return;
    }

    if (!_nodeMap[superNode.name]) {
        CacheNode(superNode, provider, result);
    }

    node.superNode = superNode;
    [superNode addSubNode:node];
    _nodeMap[node.name] = node;
}

NSArray<id<ARTNode>> *NodesInBundle(NSBundle *bundle)
{
    return NodesWithProvider([[ARTDefaultNodeProvider alloc] initWithBundle:bundle]);
}

NSArray<id<ARTNode>> *NodesWithProvider(id<ARTNodeProvider> provider)
{
    _nodeMap = [[NSMutableDictionary alloc] init];

    NSMutableArray *result = [[NSMutableArray alloc] init];

    if ([provider respondsToSelector:@selector(nodeNames)]) {
        for (NSString *nodeName in provider.nodeNames) {
            if (!_nodeMap[nodeName]) {
                NodeForName(nodeName, provider, result);
            }
        }
    } else if ([provider respondsToSelector:@selector(nodes)]) {
        for (id<ARTNode> node in provider.nodes) {
            if (!_nodeMap[node.name]) {
                CacheNode(node, provider, result);
            }
        }
    }

    [_nodeMap removeAllObjects];
    _nodeMap = nil;

    return result.copy;
}


NSString *CRNodeDescription(NSMutableString *string, id<ARTNode> node, NSArray<NSNumber *> *depth)
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

        CRNodeDescription(string, subNode, [depth arrayByAddingObject:i == count-1 ? @NO : @YES]);
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

NSString *DescriptionWithNode(id<ARTNode> node)
{
    return CRNodeDescription([[NSMutableString alloc] init], node, @[]);
}

NSString *DescriptionWithNodes(NSArray<id<ARTNode>> *nodes)
{
    NSMutableString *str = [[NSMutableString alloc] initWithString:@"Class Relationship:\n"];
    for (id<ARTNode> node in nodes) {
        [str appendFormat:@"%@\n", DescriptionWithNode(node)];
    }
    return str;
}
