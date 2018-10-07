//
//  ARTButton.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

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

IB_DESIGNABLE
@interface ARTButton : NSControl

@property (readonly) BOOL mouseIn;
@property (readonly) BOOL mouseDown;
@property (readonly) BOOL rightMouseDown;
@property (nonatomic, copy) void (^eventHandler)(__kindof ARTButton *button, ARTButtonEventType type);

@end

NS_ASSUME_NONNULL_END
