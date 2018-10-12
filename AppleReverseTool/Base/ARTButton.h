//
//  ARTButton.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/9.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ARTControl.h"

typedef NS_ENUM(NSInteger, ARTButtonState) {
    ARTButtonStateNormal        =   0,
    ARTButtonStateMouseIn       =   1 << 0,
    ARTButtonStateHighlighted   =   1 << 1,
    ARTButtonStateSelected      =   1 << 2,
    ARTButtonStateDisabled      =   1 << 3,
};

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface ARTButton : ARTControl

@property (readonly) ARTButtonState state;
@property (nonatomic, assign) IBInspectable BOOL selected;

- (void)setAttributedTitle:(nullable NSAttributedString *)title forState:(ARTButtonState)state;
- (void)setImage:(nullable NSImage *)image forState:(ARTButtonState)state;

@end

NS_ASSUME_NONNULL_END
