//
//  ARTButton.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/2.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTControl.h"

@interface ARTControl ()
@property (strong) NSTrackingArea *trackingArea;
@end

@implementation ARTControl
@synthesize mouseIn = _mouseIn, mouseDown = _mouseDown;

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    _mouseDown = NO;
    _mouseIn = NO;
    _rightMouseDown = NO;

    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    [self addTrackingArea:self.trackingArea];
}

- (void)mouseDown:(NSEvent *)event
{
    if (!_mouseDown && self.enabled) {
        _mouseDown = YES;
        if (self.eventHandler) {
            self.eventHandler(self, ARTControlEventTypeMouseDown, event);
        }
    }
}

- (void)mouseUp:(NSEvent *)event
{
    if (_mouseDown) {
        _mouseDown = NO;
        if (self.eventHandler) {
            if (_mouseIn) {
                self.eventHandler(self, ARTControlEventTypeMouseUpInside, event);
            } else {
                self.eventHandler(self, ARTControlEventTypeMouseUpOutside, event);
            }
        }
    }
}

- (void)rightMouseDown:(NSEvent *)event
{
    if (!_rightMouseDown) {
        _rightMouseDown = YES;
        if (self.eventHandler) {
            self.eventHandler(self, ARTControlEventTypeRightMouseDown, event);
        }
    }
}

- (void)rightMouseUp:(NSEvent *)event
{
    if (_rightMouseDown) {
        _rightMouseDown = NO;
        if (self.eventHandler) {
            if (_mouseIn) {
                self.eventHandler(self, ARTControlEventTypeRightMouseUpInside, event);
            } else {
                self.eventHandler(self, ARTControlEventTypeRightMouseUpOutside, event);
            }
        }
    }
}

- (void)mouseEntered:(NSEvent *)event
{
    if (!_mouseIn && self.enabled) {
        _mouseIn = YES;
        if (self.eventHandler) {
            self.eventHandler(self, ARTControlEventTypeMouseIn, event);
        }
    }
}

- (void)mouseExited:(NSEvent *)event
{
    if (_mouseIn) {
        _mouseIn = NO;
        if (self.eventHandler) {
            self.eventHandler(self, ARTControlEventTypeMouseOut, event);
        }
    }
}

- (void)updateTrackingAreas
{
    if (self.trackingArea) {
        [self removeTrackingArea:self.trackingArea];
        self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited | NSTrackingEnabledDuringMouseDrag owner:self userInfo:nil];
        [self addTrackingArea:self.trackingArea];
    }
}

@end

