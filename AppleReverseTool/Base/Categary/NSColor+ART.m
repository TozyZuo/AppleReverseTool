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

+ (NSColor *)filteredCharacterBackgroundColor
{
    return RGBAColor(252, 227, 154, .5);
//    return RGBColor(251, 244, 208);
}

+ (NSColor *)bundleColor
{
    return RGBColor(128, 128, 128);
}

- (NSString *)hexValue
{
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    return [NSString stringWithFormat:@"%x%x%x%x", (unsigned)(255 * r), (unsigned)(255 * g), (unsigned)(255 * b), (unsigned)(255 * a)];
}

@end
