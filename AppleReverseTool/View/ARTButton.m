//
//  ARTButton.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTButton.h"

@interface ARTButton ()
@property (strong) NSTrackingArea *trackingArea;
@end

@implementation ARTButton
@synthesize mouseIn = _mouseIn, mouseDown = _mouseDown;

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _mouseDown = NO;
    _mouseIn = NO;
    _rightMouseDown = NO;

    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    [self addTrackingArea:self.trackingArea];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (!_mouseDown) {
        _mouseDown = YES;
        if (self.eventHandler) {
            self.eventHandler(self, ARTButtonEventTypeMouseDown);
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (_mouseDown) {
        _mouseDown = NO;
        if (self.eventHandler) {
            if (_mouseIn) {
                self.eventHandler(self, ARTButtonEventTypeMouseUpInside);
            } else {
                self.eventHandler(self, ARTButtonEventTypeMouseUpOutside);
            }
        }
    }
}

- (void)rightMouseDown:(NSEvent *)event
{
    if (!_rightMouseDown) {
        _rightMouseDown = YES;
        if (self.eventHandler) {
            self.eventHandler(self, ARTButtonEventTypeRightMouseDown);
        }
    }
}

- (void)rightMouseUp:(NSEvent *)event
{
    if (_rightMouseDown) {
        _rightMouseDown = NO;
        if (self.eventHandler) {
            if (_mouseIn) {
                self.eventHandler(self, ARTButtonEventTypeRightMouseUpInside);
            } else {
                self.eventHandler(self, ARTButtonEventTypeRightMouseUpOutside);
            }
        }
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    if (!_mouseIn) {
        _mouseIn = YES;
        if (self.eventHandler) {
            self.eventHandler(self, ARTButtonEventTypeMouseIn);
        }
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    if (_mouseIn) {
        _mouseIn = NO;
        if (self.eventHandler) {
            self.eventHandler(self, ARTButtonEventTypeMouseOut);
        }
    }
}

- (void)updateTrackingAreas
{
    if (!CGRectEqualToRect(self.trackingArea.rect, self.bounds)) {
        [self removeTrackingArea:self.trackingArea];
        self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
        [self addTrackingArea:self.trackingArea];
        [super updateTrackingAreas];
    }
}

@end

