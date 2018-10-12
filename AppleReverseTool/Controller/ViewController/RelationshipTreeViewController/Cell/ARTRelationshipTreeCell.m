//
//  ARTRelationshipTreeCell.m
//  Rcode
//
//  Created by TozyZuo on 2018/10/12.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTRelationshipTreeCell.h"
#import "RTLabel.h"

@interface ARTRelationshipTreeCell ()
<RTLabelDelegate>
@property (nonatomic, strong) RTLabel *label;
@property (nonatomic, strong) id data;
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

- (void)updateData:(id)data
{
    self.data = data;
}

#pragma mark - RTLabelDelegate

- (void)label:(RTLabel *)label didSelectLink:(NSString *)link rightMouse:(BOOL)rightMouse
{
    if ([self.delegate respondsToSelector:@selector(relationshipTreeCell:didClickLink:rightMouse:)]) {
        [self.delegate relationshipTreeCell:self didClickLink:link rightMouse:rightMouse];
    }
}

@end
