//
//  NSColor+ART.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "NSColor+ART.h"


@implementation NSColor (ART)

+ (NSColor *)classColor
{
    return RGBColor(80, 129, 135);
}

+ (NSColor *)otherClassColor
{
    return RGBColor(111, 65, 167);
}

+ (NSColor *)connectingLineColor
{
    return RGBColor(128, 128, 128);
}

+ (NSColor *)expandButtonColor
{
    return RGBColor(64, 64, 64);
}

+ (NSColor *)stringsColor
{
    return RGBColor(207, 49, 37);
}

+ (NSColor *)keywordsColor
{
    return RGBColor(184, 51, 161);
}

+ (NSColor *)commentsColor
{
    return RGBColor(0, 131, 18);
}

+ (NSColor *)numbersColor
{
    return RGBColor(41, 52, 212);
}

@end
