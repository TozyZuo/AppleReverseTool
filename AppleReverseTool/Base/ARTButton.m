//
//  ARTButton.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/9.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTButton.h"
#import <objc/runtime.h>
/*
@interface NSButtonCell (art)
- (void)_updateImageViewImageInView:(NSView *)view;
- (void)_updateMouseInside:(BOOL)inside;
@end

@interface ARTImageView : NSImageView

@end
@implementation ARTImageView

- (void)setImage:(NSImage *)image
{
    [super setImage:image];
}

@end


@interface ARTButtonCell : NSButtonCell
@property (nonatomic, weak) NSButton *button;
@end

@implementation ARTButtonCell

- (void)mouseEntered:(NSEvent *)event
{
    [super mouseEntered:event];
}

- (void)mouseExited:(NSEvent *)event
{
    [super mouseExited:event];
}

- (void)_updateImageViewImageInView:(NSView *)view
{
    [super _updateImageViewImageInView:view];

    Ivar ivar = class_getInstanceVariable(self.class, "_bcFlags2");
    if (ivar) {
        _BCFlags2 *_bcFlags2 = (void *)&((char *)(__bridge void *)self)[ivar_getOffset(ivar)];
        BOOL mouseInside = _bcFlags2->mouseInside;
        NSLog(@"@@@ %d", mouseInside);
    }
}

- (void)_updateMouseInside:(BOOL)inside
{
    [super _updateMouseInside:inside];
}

@end
*/
@interface ARTButton ()
@property (strong) NSTrackingArea *trackingArea;
@end

@implementation ARTButton
@synthesize mouseIn = _mouseIn;

//+ (void)load
//{
//    [self setCellClass:ARTButtonCell.class];
//}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self initialize];
}

- (void)initialize
{
    self.enabled = self.enabled;

//    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
//    [self addTrackingArea:self.trackingArea];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    if (enabled) {
        self.image = self.enabledImage;
    } else {
        self.image = self.disabledImage;
    }
}
/*
- (void)mouseDown:(NSEvent *)event
{
    [super mouseDown:event];

    if (self.eventHandler) {
        self.eventHandler(self, ARTButtonEventTypeMouseDown, event);
    }
}

- (void)mouseUp:(NSEvent *)event
{
    [super mouseUp:event];

    if (self.eventHandler) {
        if (_mouseIn) {
            self.eventHandler(self, ARTButtonEventTypeMouseUpInside, event);
        } else {
            self.eventHandler(self, ARTButtonEventTypeMouseUpOutside, event);
        }
    }
}

- (void)rightMouseDown:(NSEvent *)event
{
    [super rightMouseDown:event];

    if (self.eventHandler) {
        self.eventHandler(self, ARTButtonEventTypeRightMouseDown, event);
    }
}

- (void)rightMouseUp:(NSEvent *)event
{
    [super rightMouseUp:event];

    if (self.eventHandler) {
        if (_mouseIn) {
            self.eventHandler(self, ARTButtonEventTypeRightMouseUpInside, event);
        } else {
            self.eventHandler(self, ARTButtonEventTypeRightMouseUpOutside, event);
        }
    }
}

- (void)mouseEntered:(NSEvent *)event
{
    [super mouseEntered:event];

    if (!_mouseIn) {
        _mouseIn = YES;
        if (self.eventHandler) {
            self.eventHandler(self, ARTButtonEventTypeMouseIn, event);
        }
    }
}

- (void)mouseExited:(NSEvent *)event
{
    [super mouseExited:event];

    if (_mouseIn) {
        _mouseIn = NO;
        if (self.eventHandler) {
            self.eventHandler(self, ARTButtonEventTypeMouseOut, event);
        }
    }
}

- (void)updateTrackingAreas
{
//    if (!CGRectEqualToRect(self.trackingArea.rect, self.bounds)) {
        [self removeTrackingArea:self.trackingArea];
        self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
        [self addTrackingArea:self.trackingArea];
        [super updateTrackingAreas];
//    }
}
*/
@end
