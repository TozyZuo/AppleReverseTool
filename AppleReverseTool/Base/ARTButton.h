//
//  ARTButton.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/9.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, ARTButtonEventType) {
    ARTButtonEventTypeMouseIn,
    ARTButtonEventTypeMouseOut,
    ARTButtonEventTypeMouseDown,
    ARTButtonEventTypeMouseUpInside,
    ARTButtonEventTypeMouseUpOutside,
    ARTButtonEventTypeRightMouseDown,
    ARTButtonEventTypeRightMouseUpInside,
    ARTButtonEventTypeRightMouseUpOutside,
};

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface ARTButton : NSButton

@property (nullable, strong) IBInspectable NSImage *enabledImage;
@property (nullable, strong) IBInspectable NSImage *disabledImage;

@property (readonly) BOOL mouseIn;
@property (nonatomic, copy) void (^eventHandler)(__kindof ARTButton *button, ARTButtonEventType type, NSEvent *event);

@end

NS_ASSUME_NONNULL_END
