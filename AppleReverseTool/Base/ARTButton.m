//
//  ARTButton.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/9.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTButton.h"

@interface ARTButton ()
@property (nonatomic, assign) ARTButtonState state;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSAttributedString *> *titleMap;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSImage *> *imageMap;
@property (nonatomic, strong) NSMapTable<id, NSValue *> *sizeMap;
@property (nonatomic, copy) void (^buttonEventHandler)(__kindof ARTControl *button, ARTControlEventType type, NSEvent *event);
@end

@implementation ARTButton
@synthesize mouseIn = _mouseIn;

- (void)initialize
{
    [super initialize];
    
    self.titleMap = [[NSMutableDictionary alloc] init];
    self.imageMap = [[NSMutableDictionary alloc] init];
    self.sizeMap = [NSMapTable strongToStrongObjectsMapTable];

    weakifySelf();
    [super setEventHandler:^(__kindof ARTControl *button, ARTControlEventType type, NSEvent *event) {

        switch (type) {
            case ARTControlEventTypeMouseIn:
                weakSelf.state = ARTButtonStateMouseIn | weakSelf.state;
                break;
            case ARTControlEventTypeMouseOut:
                weakSelf.state = ~ARTButtonStateMouseIn & weakSelf.state;
                break;
            case ARTControlEventTypeMouseDown:
            case ARTControlEventTypeRightMouseDown:
                weakSelf.state = ARTButtonStateHighlighted | weakSelf.state;
                break;
            case ARTControlEventTypeMouseUpOutside:
            case ARTControlEventTypeRightMouseUpOutside:
            case ARTControlEventTypeMouseUpInside:
            case ARTControlEventTypeRightMouseUpInside:
                weakSelf.state = ~ARTButtonStateHighlighted & weakSelf.state;
                break;
            default:
                break;
        }

        if (weakSelf.buttonEventHandler) {
            weakSelf.buttonEventHandler(weakSelf, type, event);
        }
    }];
}

- (void)setSelected:(BOOL)selected
{
    if (_selected != selected) {
        _selected = selected;
        if (selected) {
            self.state = ARTButtonStateSelected | self.state;
        } else {
            self.state = ~ARTButtonStateSelected & self.state;
        }
    }
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    if (enabled) {
        self.state = ~ARTButtonStateDisabled & self.state;
    } else {
        self.state = ARTButtonStateDisabled | self.state;
    }
}

- (void)setEventHandler:(void (^)(__kindof ARTControl * _Nonnull, ARTControlEventType, NSEvent * _Nonnull))eventHandler
{
    self.buttonEventHandler = eventHandler;
}

- (void)setState:(ARTButtonState)state
{
    if (_state != state) {
        ARTButtonState oldState = _state;
        _state = state;
        if (state & ARTButtonStateSelected) {
            _selected = YES;
        } else {
            _selected = NO;
        }
        self.needsDisplay = [self needsDisplayFromState:oldState toState:state];
    }
}

- (BOOL)needsDisplayFromState:(ARTButtonState)fromState toState:(ARTButtonState)toState
{
    if (self.titleMap.count) {
        return [self titleForState:fromState] != [self titleForState:toState];
    } else if (self.imageMap.count) {
        return [self imageForState:fromState] != [self imageForState:toState];
    }
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    if (self.titleMap.count) {
        NSAttributedString *title = [self titleForState:self.state];
        NSSize size = [self.sizeMap objectForKey:title].sizeValue;
        [title drawAtPoint:NSMakePoint((NSWidth(self.bounds) - size.width) * .5, (NSHeight(self.bounds) - size.height) * .5)];
    } else if (self.imageMap.count) {
        NSImage *image = [self imageForState:self.state];
        [image.representations.firstObject drawAtPoint:NSMakePoint((NSWidth(self.bounds) - image.size.width) / 2, (NSHeight(self.bounds) - image.size.height) / 2)];
    }
}

- (NSAttributedString *)titleForState:(ARTButtonState)state
{
    NSAttributedString *title;/* = self.titleMap[@(self.state)];*/
//    if (!title) {
        ARTButtonState normal = state & (~ARTButtonStateHighlighted) & (~ARTButtonStateMouseIn);
        if (state & ARTButtonStateMouseIn) {
            if (state & ARTButtonStateHighlighted) {
                title = self.titleMap[@(ARTButtonStateHighlighted)];
            } else {
                title = self.titleMap[@(ARTButtonStateMouseIn)];
            }
        }
        if (!title) {
            title = self.titleMap[@(normal)];
        }
//    }
    return title;
}

- (NSImage *)imageForState:(ARTButtonState)state
{
    NSImage *image;/* = self.imageMap[@(self.state)];*/
//    if (!image) {
        ARTButtonState normal = state & (~ARTButtonStateHighlighted) & (~ARTButtonStateMouseIn);
        if (state & ARTButtonStateMouseIn) {
            if (state & ARTButtonStateHighlighted) {
                image = self.imageMap[@(ARTButtonStateHighlighted)];
            } else {
                image = self.imageMap[@(ARTButtonStateMouseIn)];
            }
        }
        if (!image) {
            image = self.imageMap[@(normal)];
        }
//    }
    return image;
}

#pragma mark - Public

- (void)setAttributedTitle:(NSAttributedString *)title forState:(ARTButtonState)state
{
    self.titleMap[@(state)] = title;

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)title);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, MAXFLOAT, MAXFLOAT));
    CTFrameRef textFrame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0,0), path, NULL);
    CGPathRelease(path);
    CFRelease(framesetter);
    CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(CTFrameGetLines(textFrame), 0);
    CGFloat ascent;
    CGFloat descent;
    CGFloat leading;
    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    CFRelease(textFrame);

    [self.sizeMap setObject:[NSValue valueWithSize:NSMakeSize(title.size.width, ascent + descent)] forKey:title];
}

- (void)setImage:(NSImage *)image forState:(ARTButtonState)state
{
    self.imageMap[@(state)] = image;
}

@end
