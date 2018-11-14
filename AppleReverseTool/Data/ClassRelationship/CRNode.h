//
//  CRNode.h
//  ClassGraph
//
//  Created by TozyZuo on 2017/8/17.
//  Copyright © 2017年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ARTNode <NSObject>
@required
@property (nonatomic, readonly) NSString *name;
@property (nonatomic,   weak  ) id<ARTNode> superNode;
@property (nonatomic, readonly) NSArray<id<ARTNode>> *subNodes;
- (void)addSubNode:(id<ARTNode>)node;
@optional
- (instancetype)initWithName:(NSString *)name superNode:(id<ARTNode>)superNode;
@end

@protocol ARTNodeProvider <NSObject>
@optional
@property (readonly) NSArray<NSString *> *nodeNames;
@property (readonly) Class nodeClass;
- (NSString *)superNodeNameForNodeName:(NSString *)name;

@property (readonly) NSArray<id<ARTNode>> *nodes;
- (id<ARTNode>)superNodeForNode:(id<ARTNode>)node;
@end

NSArray<id<ARTNode>> *NodesInBundle(NSBundle *bundle);
NSArray<id<ARTNode>> *NodesWithProvider(id<ARTNodeProvider> provider);
NSArray<id<ARTNode>> *NodesWithProviderBlock(NSArray<id<ARTNode>> *(^nodes)(void), id<ARTNode> (^superNodeForNode)(id<ARTNode> node));
NSString *DescriptionWithNodes(NSArray<id<ARTNode>> *nodes);
