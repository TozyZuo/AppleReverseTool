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

@interface ARTView : NSView
- (void)initialize;
@end

NS_ASSUME_NONNULL_END
