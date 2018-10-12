//
//  ARTButton.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ARTControlEventType) {
    ARTControlEventTypeMouseIn,
    ARTControlEventTypeMouseOut,
    ARTControlEventTypeMouseDown,
    ARTControlEventTypeMouseUpInside,
    ARTControlEventTypeMouseUpOutside,
    ARTControlEventTypeRightMouseDown,
    ARTControlEventTypeRightMouseUpInside,
    ARTControlEventTypeRightMouseUpOutside,
};

IB_DESIGNABLE
@interface ARTControl : NSControl

@property (readonly) BOOL mouseIn;
@property (readonly) BOOL mouseDown;
@property (readonly) BOOL rightMouseDown;
@property (nonatomic, copy) void (^eventHandler)(__kindof ARTControl *button, ARTControlEventType type, NSEvent *event);

- (void)initialize;

@end

NS_ASSUME_NONNULL_END
