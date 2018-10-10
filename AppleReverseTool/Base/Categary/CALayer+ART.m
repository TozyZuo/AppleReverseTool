//
//  CALayer+ART.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/9.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "CALayer+ART.h"

@implementation CALayer (ART)

- (NSColor *)borderNSColor
{
    return [NSColor colorWithCGColor:self.borderColor];
}

- (void)setBorderNSColor:(NSColor *)borderNSColor
{
    self.borderColor = borderNSColor.CGColor;
}

@end
