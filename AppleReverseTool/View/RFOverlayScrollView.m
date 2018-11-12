//
//  RFOverlayScrollView.m
//  RFOverlayScrollView
//
//  Created by Tim Brückmann on 31.12.12.
//  Copyright (c) 2012 Rheinfabrik. All rights reserved.
//

#import <objc/objc-class.h>
#import "RFOverlayScrollView.h"
#import "RFOverlayScroller.h"

#define RFOverlayScrollerWidth 15

@interface RFOverlayScrollView ()

@end

@implementation RFOverlayScrollView

static NSComparisonResult scrollerAboveSiblingViewsComparator(NSView *view1, NSView *view2, void *context)
{
    if ([view1 isKindOfClass:[RFOverlayScroller class]]) {
        return NSOrderedDescending;
    } else if ([view2 isKindOfClass:[RFOverlayScroller class]]) {
        return NSOrderedAscending;
    }
//    else if ([view1 isMemberOfClass:[NSView class]]) {
//        return NSOrderedAscending;
//    }

    return NSOrderedSame;
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib
{
    [self initialize];
}

- (void)initialize
{
    self.wantsLayer = YES;
    _headerOffset = [self tableHeaderOffsetFromSuperview];
}

- (void)tile
{
	[super tile];

    CGSize size = self.bounds.size;
    CGFloat headerOffset = self.headerOffset;
    [self.verticalScroller setFrame:(NSRect) {
        size.width - RFOverlayScrollerWidth,
        headerOffset,
        RFOverlayScrollerWidth,
        size.height - headerOffset
    }];
    [self.horizontalScroller setFrame:(NSRect) {
        0,
        self.isFlipped ? size.height - RFOverlayScrollerWidth : 0,
        size.width - RFOverlayScrollerWidth,
        RFOverlayScrollerWidth
    }];

    // Move scroller to front
    [self sortSubviewsUsingFunction:scrollerAboveSiblingViewsComparator context:NULL];
}

- (NSInteger)tableHeaderOffsetFromSuperview
{
    for (NSView *subView in [self subviews])
    {
        if ([subView isKindOfClass:[NSClipView class]])
        {   for (NSView *subView2 in [subView subviews])
            {   if ([subView2 isKindOfClass:[NSTableView class]])
                {
                    return [(NSTableView *)subView2 headerView].frame.size.height;
                }
            }
        }
    }
    return 0;
}

@end
