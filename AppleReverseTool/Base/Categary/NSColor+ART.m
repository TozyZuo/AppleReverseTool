//
//  NSColor+ART.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "NSColor+ART.h"

#define RGBAVColor(rgbValue, _alpha) [NSColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:_alpha]
#define RGBVColor(rgbValue) RGBAVColor(rgbValue, 1)

#define RGBAColor(r, g, b, _alpha) [NSColor colorWithRed:((float)(r))/255.0 green:((float)(g))/255.0 blue:((float)(b))/255.0 alpha:_alpha]
#define RGBColor(r, g, b) RGBAColor(r, g, b, 1)

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
