//
//  ARTView.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/4.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTView.h"

@implementation NSViewController (ARTView)

- (void)viewDidResize:(NSView *)view
{

}

@end

@implementation ARTView

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
    self.wantsLayer = YES;
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];

    [self.viewController viewDidResize:self];
}

@end
