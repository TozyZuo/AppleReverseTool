//
//  NSColor+ART.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define RGBAVColor(rgbValue, _alpha) [NSColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:_alpha]
#define RGBVColor(rgbValue) RGBAVColor(rgbValue, 1)

#define RGBAColor(r, g, b, _alpha) [NSColor colorWithRed:((float)(r))/255.0 green:((float)(g))/255.0 blue:((float)(b))/255.0 alpha:_alpha]
#define RGBColor(r, g, b) RGBAColor(r, g, b, 1)

NS_ASSUME_NONNULL_BEGIN

@interface NSColor (ART)
@end

NS_ASSUME_NONNULL_END
