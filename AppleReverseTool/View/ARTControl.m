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
            self.eventHandler(self, ARTControlEventTypeMouseDown);
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (_mouseDown) {
        _mouseDown = NO;
        if (self.eventHandler) {
            if (_mouseIn) {
                self.eventHandler(self, ARTControlEventTypeMouseUpInside);
            } else {
                self.eventHandler(self, ARTControlEventTypeMouseUpOutside);
            }
        }
    }
}

- (void)rightMouseDown:(NSEvent *)event
{
    if (!_rightMouseDown) {
        _rightMouseDown = YES;
        if (self.eventHandler) {
            self.eventHandler(self, ARTControlEventTypeRightMouseDown);
        }
    }
}

- (void)rightMouseUp:(NSEvent *)event
{
    if (_rightMouseDown) {
        _rightMouseDown = NO;
        if (self.eventHandler) {
            if (_mouseIn) {
                self.eventHandler(self, ARTControlEventTypeRightMouseUpInside);
            } else {
                self.eventHandler(self, ARTControlEventTypeRightMouseUpOutside);
            }
        }
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    if (!_mouseIn) {
        _mouseIn = YES;
        if (self.eventHandler) {
            self.eventHandler(self, ARTControlEventTypeMouseIn);
        }
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    if (_mouseIn) {
        _mouseIn = NO;
        if (self.eventHandler) {
            self.eventHandler(self, ARTControlEventTypeMouseOut);
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

