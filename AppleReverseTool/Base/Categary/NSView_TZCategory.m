//
//  NSView+TZCategory.m
//  iProgram
//
//  Created by Tozy on 13-8-7.
//  Copyright (c) 2013年 TozyZuo. All rights reserved.
//

#import "NSView_TZCategory.h"

#pragma mark - Categroy (TZFrame)

@implementation NSView (TZFrame)

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)left {
    return self.frame.origin.x;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setLeft:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)top {
    if (self.isFlipped) {
        return self.frame.origin.y;
    } else {
        return self.frame.size.height;
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setTop:(CGFloat)y {
    CGRect frame = self.frame;
    if (self.isFlipped) {
        frame.origin.y = y;
    } else {
        frame.origin.y = y - frame.size.height;
    }
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)right {
    return self.frame.origin.x + self.frame.size.width;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setRight:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)bottom {
    if (self.isFlipped) {
        return self.frame.size.height;
    } else {
        return self.frame.origin.y;
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setBottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    if (self.isFlipped) {
        frame.origin.y = bottom - frame.size.height;
    } else {
        frame.origin.y = bottom;
    }
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////

- (CGPoint)center
{
    return CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
}

- (void)setCenter:(CGPoint)center
{
    CGRect frame = self.frame;
    frame.origin.x = center.x - frame.size.width * .5;
    frame.origin.y = center.y - frame.size.height * .5;
    self.frame = frame;
}

- (CGFloat)centerX {
    return CGRectGetMidX(self.frame);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setCenterX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)centerY {
    return CGRectGetMidY(self.frame);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setCenterY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)width {
    return self.frame.size.width;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)height {
    return self.frame.size.height;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)ttScreenX {
    CGFloat x = 0;
    for (NSView* view = self; view; view = view.superview) {
        x += view.left;
    }
    return x;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)ttScreenY {
    CGFloat y = 0;
    for (NSView* view = self; view; view = view.superview) {
        y += view.top;
    }
    return y;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)screenViewX {
    CGFloat x = 0;
    for (NSView* view = self; view; view = view.superview) {
        x += view.left;
        
        if ([view isKindOfClass:[NSScrollView class]]) {
            NSScrollView* scrollView = (NSScrollView*)view;
            x -= scrollView.visibleRect.origin.x;
        }
    }
    
    return x;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)screenViewY {
    CGFloat y = 0;
    for (NSView* view = self; view; view = view.superview) {
        y += view.top;
        
        if ([view isKindOfClass:[NSScrollView class]]) {
            NSScrollView* scrollView = (NSScrollView*)view;
            y -= scrollView.visibleRect.origin.y;
        }
    }
    return y;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGRect)screenFrame {
    return CGRectMake(self.screenViewX, self.screenViewY, self.width, self.height);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGPoint)origin {
    return self.frame.origin;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGSize)size {
    return self.frame.size;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSView*)descendantOrSelfWithClass:(Class)cls {
    if ([self isKindOfClass:cls])
        return self;
    
    for (NSView* child in self.subviews) {
        NSView* it = [child descendantOrSelfWithClass:cls];
        if (it)
            return it;
    }
    
    return nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSView*)ancestorOrSelfWithClass:(Class)cls {
    if ([self isKindOfClass:cls]) {
        return self;
    } else if (self.superview) {
        return [self.superview ancestorOrSelfWithClass:cls];
    } else {
        return nil;
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)removeAllSubviews {
    while (self.subviews.count) {
        NSView* child = self.subviews.lastObject;
        [child removeFromSuperview];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGPoint)offsetFromView:(NSView*)otherView {
    CGFloat x = 0, y = 0;
    for (NSView* view = self; view && view != otherView; view = view.superview) {
        x += view.left;
        y += view.top;
    }
    return CGPointMake(x, y);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSViewController*)viewController {
    for (NSView* next = self; next; next = next.superview) {
        NSResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[NSViewController class]]) {
            return (NSViewController*)nextResponder;
        }
    }
    return nil;
}
@end

@implementation NSView (TZBackgroundColor)

- (NSColor *)backgroundColor
{
    if (self.layer.backgroundColor) {
        return [NSColor colorWithCGColor:self.layer.backgroundColor];
    }
    return nil;
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    self.wantsLayer = YES;
    self.layer.backgroundColor = backgroundColor.CGColor;
}

@end

@implementation NSView (TZViewToImage)

- (NSImage *)image
{
    return [[NSImage alloc] initWithData:[self dataWithPDFInsideRect:self.bounds]];
}

@end

@implementation NSView (TZViewScroll)

- (void)scrollToTop
{
    if (self.isFlipped) {
        [self scrollPoint:CGPointZero];
    } else {
        [self scrollPoint:NSMakePoint(0, self.height)];
    }
}

@end
