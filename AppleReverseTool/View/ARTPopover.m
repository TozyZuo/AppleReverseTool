//
//  ARTPopover.m
//  Rcode
//
//  Created by TozyZuo on 2018/11/30.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTPopover.h"

@interface ARTEventMonitor : NSObject
@property (nonatomic, strong) id globalMonitor;
@property (nonatomic, strong) id localMonitor;
@property (nonatomic, assign) NSEventMask mask;
@property (nonatomic,  copy ) void (^handler)(NSEvent *);
@end

@implementation ARTEventMonitor

- (instancetype)initWithMask:(NSEventMask)mask handler:(void (^)(NSEvent *))handler
{
    self = [super init];
    if(self){
        self.mask = mask;
        self.handler = handler;
    }
    return self;
}

- (void)start
{
    @weakify(self);
    self.localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:self.mask handler:^NSEvent * _Nullable(NSEvent * _Nonnull event)
    {
        @strongify(self);
        if (self.handler) {
            self.handler(event);
        }
        return event;
    }];
    self.globalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:self.mask handler:self.handler];
}

- (void)stop
{
    if (self.localMonitor) {
        [NSEvent removeMonitor:self.localMonitor];
        self.localMonitor = nil;
    }
    if(self.globalMonitor){
        [NSEvent removeMonitor:self.globalMonitor];
        self.globalMonitor = nil;
    }
}

@end

@interface ARTPopover ()
@property (nonatomic, strong) ARTEventMonitor *monitor;
@end

@implementation ARTPopover

- (instancetype)initWithContentViewController:(NSViewController *)contentViewController
{
    if (self = [super initWithContentViewController:contentViewController]) {
        self.backgroundColor = NSColor.whiteColor;
        self.position = SFBPopoverPositionTop;

        @weakify(self);
        self.monitor = [[ARTEventMonitor alloc] initWithMask:NSEventMaskLeftMouseDown|NSEventMaskRightMouseDown handler:^(NSEvent *event)
        {
            @strongify(self);
            NSWindow *popoverWindow = self[@"popoverWindow"];
            NSView *view = popoverWindow.contentView;
            NSPoint p = [view convertPoint:event.locationInWindow fromView:nil];
            if(self.isVisible && ![view mouse:p inRect:view.visibleRect]){
                [self closePopover:event];
            }
        }];
    }
    return self;
}


- (void)displayPopoverInWindow:(NSWindow *)window atPoint:(NSPoint)point chooseBestLocation:(BOOL)chooseBestLocation makeKey:(BOOL)makeKey
{
    [super displayPopoverInWindow:window atPoint:point chooseBestLocation:chooseBestLocation makeKey:makeKey];
    [self.monitor start];

    @weakify(self);
    NSViewController *contentViewController = self[@"contentViewController"];
    [self observe:contentViewController.view keyPath:@"frame" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change)
     {
         @strongify(self);
         CGRect newFrame = [change[NSKeyValueChangeNewKey] rectValue];
         CGRect oldFrame = [change[NSKeyValueChangeOldKey] rectValue];
         if (!CGRectEqualToRect(newFrame, oldFrame)) {
             CGFloat deltaX = oldFrame.size.width - newFrame.size.width;
             CGFloat deltaY = oldFrame.size.height - newFrame.size.height;
             NSWindow *popoverWindow = self[@"popoverWindow"];
             popoverWindow.contentView.height -= deltaY;
             popoverWindow.contentView.width -= deltaX;

             CGRect windowFrame = popoverWindow.frame;
             windowFrame.size.width -= deltaX;
             windowFrame.size.height -= deltaY;
             [popoverWindow setFrame:windowFrame display:YES];
         }
     }];
}

- (void)closePopover:(id)sender
{
    [super closePopover:sender];
    [self.monitor stop];
    [self unobserveAll];
}

@end
