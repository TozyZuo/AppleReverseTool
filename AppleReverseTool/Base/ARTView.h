//
//  ARTView.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/4.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSViewController (ARTView)
- (void)viewDidResize:(NSView *)view;
@end

IB_DESIGNABLE
@interface ARTView : NSView
@property (nonatomic, strong) IBInspectable NSColor *backgroundColor;
@end

NS_ASSUME_NONNULL_END
