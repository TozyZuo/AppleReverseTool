//
//  ARTRichTextController.m
//  TextViewDemo
//
//  Created by TozyZuo on 2018/10/15.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTRichTextController.h"


@interface ARTTextComponent : NSObject
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *tagLabel;
@property (nonatomic) NSMutableDictionary *attributes;
@property (nonatomic, assign) NSInteger position;
@property (nonatomic, assign) NSRect rect;

- (id)initWithString:(NSString*)aText tag:(NSString*)aTagLabel attributes:(NSMutableDictionary*)theAttributes;
+ (id)componentWithString:(NSString*)aText tag:(NSString*)aTagLabel attributes:(NSMutableDictionary*)theAttributes;
- (id)initWithTag:(NSString*)aTagLabel position:(NSInteger)_position attributes:(NSMutableDictionary*)_attributes;
+ (id)componentWithTag:(NSString*)aTagLabel position:(NSInteger)aPosition attributes:(NSMutableDictionary*)theAttributes;

@end


@interface ARTRichTextController ()
@property (nonatomic, strong) NSString *plainText;
@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, strong) NSArray<ARTTextComponent *> *textComponents;
@property (nonatomic, strong) NSArray<ARTTextComponent *> *linkComponents;
@property (nonatomic, strong) NSMutableArray<NSTrackingArea *> *trackingAreas;
@property (nonatomic, strong) id eventMonitor;
@property (nonatomic, assign) CGSize optimumSize;
@property (nonatomic,  weak ) ARTTextComponent *mouseDownComponent;
@property (readonly) NSEdgeInsets textInsets;
@property (readonly) CGFloat lineSpacing;
@property (readonly) CGFloat extraLineSpacing;
@property (class, readonly) NSSet *validTags;
@end

@implementation ARTRichTextController

- (void)dealloc
{
    [_view removeObserver:self forKeyPath:@"frame"];
    [_view removeObserver:self forKeyPath:@"font"];
    [NSEvent removeMonitor:self.eventMonitor];
}

- (instancetype)init
{
    return [self initWithView:nil];
}

- (instancetype)initWithView:(NSView<ARTRichTextViewProtocol> *)view
{
    self = [super init];
    if (self) {
        self.linkComponents = [[NSMutableArray alloc] init];
        self.trackingAreas = [[NSMutableArray alloc] init];
        self.textColor = view.textColor;
        self.view = view;

        __weak typeof(self) weakSelf = self;
        self.eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown|NSEventMaskLeftMouseUp|NSEventMaskRightMouseDown|NSEventMaskRightMouseUp|NSEventTypeOtherMouseDown|NSEventTypeOtherMouseUp handler:^NSEvent * _Nullable(NSEvent * _Nonnull event)
        {
            return [weakSelf handleMonitorEvent:event];
        }];
    }
    return self;
}

+ (NSSet *)validTags
{
    static NSSet *validTags;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        validTags = [NSSet setWithObjects:
                     @"i",
                     @"b",
                     @"bi",
                     @"a",
                     @"u",
                     @"uu",
                     @"font",
                     @"p",
                     @"center",
                     @"/i",
                     @"/b",
                     @"/bi",
                     @"/a",
                     @"/u",
                     @"/uu",
                     @"/font",
                     @"/p",
                     @"/center",
                     nil];
    });
    return validTags;
}

- (CGFloat)lineSpacing
{
    if ([self.view respondsToSelector:@selector(lineSpacing)]) {
        return self.view.lineSpacing;
    }
    return 0;
}

- (CGFloat)extraLineSpacing
{
    if ([self.view respondsToSelector:@selector(extraLineSpacing)]) {
        return self.view.extraLineSpacing;
    }
    return 0;
}

- (NSEdgeInsets)textInsets
{
    if ([self.view respondsToSelector:@selector(textInsets)]) {
        return self.view.textInsets;
    }
    return NSEdgeInsetsMake(0, 0, 0, 0);
}

- (void)setView:(NSView<ARTRichTextViewProtocol> *)view
{
    if (![_view isEqual:view]) {
        [_view removeObserver:self forKeyPath:@"frame"];
        [_view removeObserver:self forKeyPath:@"font"];
        [view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
        [view addObserver:self forKeyPath:@"font" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
        _view = view;
    }
}

#pragma mark - Private

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"frame"]) {
        [self calculateTrackingArea];
    } else if ([keyPath isEqualToString:@"font"]) {
        NSMutableAttributedString *attributedText = self.attributedText.mutableCopy;
        [attributedText addAttribute:NSFontAttributeName value:self.view.font range:NSMakeRange(0, self.attributedText.length)];
        self.attributedText = attributedText;
    }
}

- (void)parseText:(NSString*)data paragraphReplacement:(NSString*)paragraphReplacement
{
    NSString *originString = data;
    NSString *tag = nil;
    NSMutableArray *components = [NSMutableArray array];
    NSInteger last_position = 0;
    NSInteger startCursor = 0;
    NSInteger endCursor = 0;
    NSInteger lastCursor = 0;
    NSInteger length = originString.length;

    static NSInteger (^calculateCount)(NSString *string, NSString *characterString);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        calculateCount = ^(NSString *string, NSString *characterString) {
            unichar character = [characterString characterAtIndex:0];
            NSInteger count = 0;
            for (int i = 0; i < string.length; i++) {
                if ([string characterAtIndex:i] == character) {
                    count++;
                }
            }
            return count;
        };
    });

    while (startCursor < length)
    {
        NSString *text = nil;

        NSRange startRange = [originString rangeOfString:@"<" options:0 range:NSMakeRange(startCursor, length - startCursor)];

        if (startRange.location == NSNotFound) {
            break;
        }

        startCursor = startRange.location;
        endCursor = startCursor;

        while (endCursor < length) {
            NSRange endRange = [originString rangeOfString:@">" options:0 range:NSMakeRange(endCursor, length - endCursor)];
            if (endRange.location == NSNotFound) {
                break;
            }
            endCursor = endRange.location;
            NSString *innerString = [originString substringWithRange:NSMakeRange(startCursor + 1, endCursor - startCursor - 1)];
            if (calculateCount(innerString, @"<") == calculateCount(innerString, @">")) {
                text = [originString substringWithRange:NSMakeRange(startCursor, endCursor - startCursor)];
                startCursor = endCursor + 1;
                break;
            }
            endCursor = NSMaxRange(endRange);
        }

        if (!text.length) {
            break;
        }

        NSString *delimiter = [NSString stringWithFormat:@"%@>", text];
        NSInteger position = [data rangeOfString:delimiter options:0 range:NSMakeRange(last_position, data.length - last_position)].location;
        if (![ARTRichTextController.validTags containsObject:[[text substringFromIndex:1] componentsSeparatedByString:@" "].firstObject])
        {
            lastCursor++;
            startCursor = lastCursor;
            continue;
        }

        lastCursor = endCursor + 1;
        if (position!=NSNotFound)
        {
            if ([delimiter rangeOfString:@"<p"].location==0)
            {
                data = [data stringByReplacingOccurrencesOfString:delimiter withString:paragraphReplacement options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, position+delimiter.length-last_position)];
            }
            else
            {
                data = [data stringByReplacingOccurrencesOfString:delimiter withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, position+delimiter.length-last_position)];
            }

            data = [data stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
            data = [data stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
        }

        if ([text rangeOfString:@"</"].location==0)
        {
            // end of tag
            tag = [text substringFromIndex:2];
            if (position!=NSNotFound)
            {
                for (NSInteger i=[components count]-1; i>=0; i--)
                {
                    ARTTextComponent *component = components[i];
                    if (component.text == nil && [component.tagLabel isEqualToString:tag])
                    {
                        NSString *text2 = [data substringWithRange:NSMakeRange(component.position, position-component.position)];
                        component.text = text2;
                        break;
                    }
                }
            }
        }
        else
        {
//            <a href=Struct://{unique_ptr<WebKit::NavigationState, std::__1::default_delete<WebKit::NavigationState>>="__ptr_"{__compressed_pair<WebKit::NavigationState *, std::__1::default_delete<WebKit::NavigationState>>="__first_"^{NavigationState}}}/unique_ptr<WebKit::NavigationState, std::__1::default_delete<WebKit::NavigationState>>>
            NSString *string = [text substringFromIndex:1];
            NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
            NSScanner *scanner = [[NSScanner alloc] initWithString:string];
            [scanner scanUpToString:@" " intoString:&tag];

            while (!scanner.isAtEnd) {
                NSString *key, *value;
                [scanner scanUpToString:@"=" intoString:&key];
                scanner.scanLocation = scanner.scanLocation + 1;
                if ((char)[string characterAtIndex:scanner.scanLocation] == '\'') {
                    scanner.scanLocation = scanner.scanLocation + 1;
                    [scanner scanUpToString:@"'" intoString:&value];
                    [scanner scanUpToString:@" " intoString:nil];
                } else {
                    [scanner scanUpToString:@" " intoString:&value];
                    value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, MIN(1, value.length))];
                    value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange(MAX(0, (NSInteger)[value length]-1), MIN(1, value.length))];
                }
                if (!scanner.isAtEnd) {
                    scanner.scanLocation = scanner.scanLocation + 1;
                }

                attributes[key] = value ?: key;
            }

            ARTTextComponent *component = [ARTTextComponent componentWithString:nil tag:tag attributes:attributes];
            component.position = position;
            [components addObject:component];
        }
        last_position = position;
    }

    self.textComponents = components;
    self.plainText = data;
}

- (NSAttributedString *)attributedTextWithComponents:(NSArray<ARTTextComponent *> *)components plainText:(NSString *)plainText
{
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:plainText];

    // color
    [attrString addAttribute:NSForegroundColorAttributeName value:self.textColor ?: NSColor.blackColor range:NSMakeRange(0, plainText.length)];

    // font
    [attrString addAttribute:NSFontAttributeName value:self.view.font range:NSMakeRange(0, attrString.length)];

    // paragraph
    [self applyParagraphStyleToText:attrString attributes:nil atPosition:0 withLength:attrString.length];

    NSMutableArray *links = [NSMutableArray array];

    for (ARTTextComponent *component in components)
    {
        if ([component.tagLabel caseInsensitiveCompare:@"i"] == NSOrderedSame)
        {
            // make font italic
            [self applyItalicStyleToText:attrString atPosition:component.position withLength:[component.text length]];
        }
        else if ([component.tagLabel caseInsensitiveCompare:@"b"] == NSOrderedSame)
        {
            // make font bold
            [self applyBoldStyleToText:attrString atPosition:component.position withLength:[component.text length]];
        }
        else if ([component.tagLabel caseInsensitiveCompare:@"bi"] == NSOrderedSame)
        {
            [self applyBoldItalicStyleToText:attrString atPosition:component.position withLength:[component.text length]];
        }
        else if ([component.tagLabel caseInsensitiveCompare:@"a"] == NSOrderedSame)
        {
            [self applyFontAttributes:component.attributes toText:attrString atPosition:component.position withLength:component.text.length];

            NSString *value = component.attributes[@"href"];
            value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];

            if(value) component.attributes[@"href"] = value;

            [links addObject:component];
        }
        else if ([component.tagLabel caseInsensitiveCompare:@"u"] == NSOrderedSame || [component.tagLabel caseInsensitiveCompare:@"uu"] == NSOrderedSame)
        {
            // underline
            if ([component.tagLabel caseInsensitiveCompare:@"u"] == NSOrderedSame)
            {
                [self applySingleUnderlineText:attrString atPosition:component.position withLength:[component.text length]];
            }
            else if ([component.tagLabel caseInsensitiveCompare:@"uu"] == NSOrderedSame)
            {
                [self applyDoubleUnderlineText:attrString atPosition:component.position withLength:[component.text length]];
            }

            if ((component.attributes)[@"color"])
            {
                NSString *value = (component.attributes)[@"color"];
                [self applyUnderlineColor:value toText:attrString atPosition:component.position withLength:[component.text length]];
            }
        }
        else if ([component.tagLabel caseInsensitiveCompare:@"font"] == NSOrderedSame)
        {
            [self applyFontAttributes:component.attributes toText:attrString atPosition:component.position withLength:[component.text length]];
        }
        else if ([component.tagLabel caseInsensitiveCompare:@"p"] == NSOrderedSame)
        {
            [self applyParagraphStyleToText:attrString attributes:component.attributes atPosition:component.position withLength:[component.text length]];
        }
        else if ([component.tagLabel caseInsensitiveCompare:@"center"] == NSOrderedSame)
        {
            [self applyCenterStyleToText:attrString attributes:component.attributes atPosition:component.position withLength:[component.text length]];
        }
    }

    self.linkComponents = links;

    return attrString;
}

//#define TrackingAreaDebug

- (void)calculateTrackingArea
{
    for (NSTrackingArea *trackingArea in self.trackingAreas) {
#ifdef TrackingAreaDebug
        [trackingArea.userInfo[@"view"] removeFromSuperview];
#endif
        [self.view removeTrackingArea:trackingArea];
    }
    [self.trackingAreas removeAllObjects];

    NSSize size = self.view.bounds.size;
    NSEdgeInsets insets = self.textInsets;
    NSSize insetsSize = NSMakeSize(size.width - insets.left - insets.right, size.height - insets.top - insets.bottom);

    // Create the framesetter with the attributed string.
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attributedText);

    CGSize suggestFrameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, self.plainText.length), nil, CGSizeMake(insetsSize.width, CGFLOAT_MAX), NULL);
    CGSize optimumSize = NSMakeSize(suggestFrameSize.width + insets.left + insets.right, suggestFrameSize.height + insets.top + insets.bottom);
    self.optimumSize = optimumSize;

    // Initialize a rectangular path.
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, NSMakeRect(0, 0, insetsSize.width, suggestFrameSize.height));

    // Create the frame and draw it into the graphics context
    //CTFrameRef
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0, 0), path, NULL);

    for (ARTTextComponent *linkableComponent in self.linkComponents)
    {
        CGFloat y;
        if (self.view.isFlipped) {
            y = insets.top;
        } else {
            y = insets.bottom;
        }

        CFArrayRef frameLines = CTFrameGetLines(frame);
        for (CFIndex i = 0; i < CFArrayGetCount(frameLines); i++)
        {
            CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(frameLines, i);
            CFRange lineRange = CTLineGetStringRange(line);
            CGFloat ascent;
            CGFloat descent;
            CGFloat leading;

            CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
            CGPoint origin;
            CTFrameGetLineOrigins(frame, CFRangeMake(i, 1), &origin);

            if ( (linkableComponent.position<lineRange.location && linkableComponent.position+linkableComponent.text.length>(u_int16_t)(lineRange.location)) || (linkableComponent.position>=lineRange.location && linkableComponent.position<lineRange.location+lineRange.length))
            {
                CGFloat left = CTLineGetOffsetForStringIndex(CFArrayGetValueAtIndex(frameLines,i), linkableComponent.position, NULL);
                CGFloat right = CTLineGetOffsetForStringIndex(CFArrayGetValueAtIndex(frameLines,i), linkableComponent.position + linkableComponent.text.length, NULL);

                NSRect rect = NSMakeRect(insets.left + origin.x + left, 0, right - left, ascent + descent);
                if (self.view.isFlipped) {
                    rect.origin.y = y;
                } else {
                    rect.origin.y = y; // TODO
                }

                linkableComponent.rect = rect;
#ifdef TrackingAreaDebug
                NSView *view = [[NSView alloc] initWithFrame:rect];
                view.wantsLayer = YES;
                view.layer.backgroundColor = [self.textColor colorWithAlphaComponent:.5].CGColor;
                [self.view addSubview:view];
                NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:rect options:NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:@{@"component": linkableComponent, @"view": view}];
#else
                NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:rect options:NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:@{@"component": linkableComponent}];
#endif
                [self.view addTrackingArea:trackingArea];
                [self.trackingAreas addObject:trackingArea];
            }

            y = y + ascent + descent + leading + self.lineSpacing + self.extraLineSpacing;
            y = ceil(y);
        }
    }

    //    self.visibleRange = CTFrameGetVisibleStringRange(frame);
}

#pragma mark  Event

- (void)mouseEntered:(NSEvent *)theEvent
{
    self.view.selectable = NO;

    ARTTextComponent *component = theEvent.trackingArea.userInfo[@"component"];
    NSString *colorValue = component.attributes[@"color"];
    if (!colorValue) {
        for (ARTTextComponent *cpt in self.textComponents) {
            if (cpt.position == component.position) {
                colorValue = cpt.attributes[@"color"];
                break;
            }
        }
    }
    if (colorValue) {
        NSMutableAttributedString *string = self.attributedText.mutableCopy;
        [self applyNSColor:[[self colorFromAttributesValue:colorValue] blendedColorWithFraction:.3 ofColor:NSColor.whiteColor] toText:string atPosition:component.position withLength:component.text.length];
        self.view.attributedStringValue = string;
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    self.view.selectable = YES;

    ARTTextComponent *component = theEvent.trackingArea.userInfo[@"component"];
    NSString *colorValue = component.attributes[@"color"];
    if (!colorValue) {
        for (ARTTextComponent *cpt in self.textComponents) {
            if (cpt.position == component.position) {
                colorValue = cpt.attributes[@"color"];
                break;
            }
        }
    }
    if (colorValue) {
        NSMutableAttributedString *string = self.attributedText.mutableCopy;
        [self applyNSColor:[self colorFromAttributesValue:colorValue] toText:string atPosition:component.position withLength:component.text.length];
        self.view.attributedStringValue = string;
    }
}

- (NSEvent *)handleMonitorEvent:(NSEvent *)event
{
    if (event.window == self.view.window) {
        NSPoint p = [self.view convertPoint:event.locationInWindow fromView:event.window.contentView];
        NSEventType type = event.type;
        if ([self.view hitTest:p] &&
            (type == NSEventTypeLeftMouseDown ||
             type == NSEventTypeLeftMouseUp ||
             type == NSEventTypeRightMouseDown ||
             type == NSEventTypeRightMouseUp))
        {
            ARTTextComponent *component = nil;
            for (ARTTextComponent *cpt in self.linkComponents) {
                if (CGRectContainsPoint(cpt.rect, p)) {
                    component = cpt;
                    break;
                }
            }
            if (component) {
                switch (event.type) {
                    case NSEventTypeLeftMouseDown:
                    case NSEventTypeRightMouseDown:
                    {
                        NSString *colorValue = component.attributes[@"color"];
                        if (!colorValue) {
                            for (ARTTextComponent *cpt in self.textComponents) {
                                if (cpt.position == component.position) {
                                    colorValue = cpt.attributes[@"color"];
                                    break;
                                }
                            }
                        }
                        if (colorValue) {
                            NSMutableAttributedString *string = self.attributedText.mutableCopy;
                            [self applyNSColor:[[self colorFromAttributesValue:colorValue] blendedColorWithFraction:.3 ofColor:NSColor.blackColor] toText:string atPosition:component.position withLength:component.text.length];
                            self.view.attributedStringValue = string;
                        }
                        self.mouseDownComponent = component;
                    }
                        return nil;
                    case NSEventTypeLeftMouseUp:
                    case NSEventTypeRightMouseUp:
                    {
                        if (component == self.mouseDownComponent) {
                            NSString *colorValue = component.attributes[@"color"];
                            if (!colorValue) {
                                for (ARTTextComponent *cpt in self.textComponents) {
                                    if (cpt.position == component.position) {
                                        colorValue = cpt.attributes[@"color"];
                                        break;
                                    }
                                }
                            }
                            if (colorValue) {
                                NSMutableAttributedString *string = self.attributedText.mutableCopy;
                                [self applyNSColor:[self colorFromAttributesValue:colorValue] toText:string atPosition:component.position withLength:component.text.length];
                                self.view.attributedStringValue = string;
                            }
                            if ([self.delegate respondsToSelector:@selector(richTextController:didSelectLink:rightMouse:)]) {
                                [self.delegate richTextController:self didSelectLink:component.attributes[@"href"] rightMouse:type == NSEventTypeRightMouseUp];
                            }
                            return nil;
                        }
                    }
                        break;
                    default:
                        break;
                }
            }
        }
    }
    return event;
}

#pragma mark styling

- (void)applyParagraphStyleToText:(NSMutableAttributedString *)text attributes:(NSMutableDictionary*)attributes atPosition:(NSInteger)position withLength:(NSInteger)length
{
    // leading
    CGFloat firstLineIndent = 0.0;
    NSTextAlignment textAlignment = self.view.alignment;
    NSLineBreakMode lineBreakMode = self.view.lineBreakMode;

    for (NSUInteger i=0; i<[[attributes allKeys] count]; i++)
    {
        NSString *key = [attributes allKeys][i];
        id value = attributes[key];
        if ([key caseInsensitiveCompare:@"align"] == NSOrderedSame)
        {
            if ([value caseInsensitiveCompare:@"left"] == NSOrderedSame)
            {
                textAlignment = NSTextAlignmentLeft;
            }
            else if ([value caseInsensitiveCompare:@"right"] == NSOrderedSame)
            {
                textAlignment = NSTextAlignmentRight;
            }
            else if ([value caseInsensitiveCompare:@"justify"] == NSOrderedSame)
            {
                textAlignment = NSTextAlignmentJustified;
            }
            else if ([value caseInsensitiveCompare:@"center"] == NSOrderedSame)
            {
                textAlignment = NSTextAlignmentCenter;
            }
        }
        else if ([key caseInsensitiveCompare:@"indent"] == NSOrderedSame)
        {
            firstLineIndent = [value floatValue];
        }
        else if ([key caseInsensitiveCompare:@"linebreakmode"] == NSOrderedSame)
        {
            if ([value caseInsensitiveCompare:@"wordwrap"] == NSOrderedSame)
            {
                lineBreakMode = NSLineBreakByWordWrapping;
            }
            else if ([value caseInsensitiveCompare:@"charwrap"] == NSOrderedSame)
            {
                lineBreakMode = NSLineBreakByCharWrapping;
            }
            else if ([value caseInsensitiveCompare:@"clipping"] == NSOrderedSame)
            {
                lineBreakMode = NSLineBreakByClipping;
            }
            else if ([value caseInsensitiveCompare:@"truncatinghead"] == NSOrderedSame)
            {
                lineBreakMode = NSLineBreakByTruncatingHead;
            }
            else if ([value caseInsensitiveCompare:@"truncatingtail"] == NSOrderedSame)
            {
                lineBreakMode = NSLineBreakByTruncatingTail;
            }
            else if ([value caseInsensitiveCompare:@"truncatingmiddle"] == NSOrderedSame)
            {
                lineBreakMode = NSLineBreakByTruncatingMiddle;
            }
        }
    }

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = textAlignment;
    paragraphStyle.lineBreakMode = lineBreakMode;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.lineSpacing = self.lineSpacing;
    paragraphStyle.firstLineHeadIndent = firstLineIndent;
    paragraphStyle.headIndent = 0;
    paragraphStyle.tailIndent = 0;
    paragraphStyle.lineHeightMultiple = 1;
    paragraphStyle.minimumLineHeight = 0;
    paragraphStyle.maximumLineHeight = 0;
    paragraphStyle.paragraphSpacing = 0;
    paragraphStyle.paragraphSpacingBefore = 0;

    [text addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(position, length)];
}

- (void)applyCenterStyleToText:(NSMutableAttributedString *)text attributes:(NSMutableDictionary*)attributes atPosition:(NSInteger)position withLength:(NSInteger)length
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = self.view.lineBreakMode;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.lineSpacing = self.lineSpacing;
    paragraphStyle.firstLineHeadIndent = 0;
    paragraphStyle.headIndent = 0;
    paragraphStyle.tailIndent = 0;
    paragraphStyle.lineHeightMultiple = 1;
    paragraphStyle.minimumLineHeight = 0;
    paragraphStyle.maximumLineHeight = 0;
    paragraphStyle.paragraphSpacing = 0;
    paragraphStyle.paragraphSpacingBefore = 0;

    [text addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(position, length)];
}

- (void)applySingleUnderlineText:(NSMutableAttributedString *)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    [text addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(position, length)];
}

- (void)applyDoubleUnderlineText:(NSMutableAttributedString *)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    [text addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleDouble) range:NSMakeRange(position, length)];
}

- (void)applyItalicStyleToText:(NSMutableAttributedString *)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    NSFont *font = [text attribute:NSFontAttributeName atIndex:position effectiveRange:nil];
    NSFont *italicFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSItalicFontMask];
    if (!italicFont) {
        //fallback to system italic font
        italicFont = [[NSFontManager sharedFontManager] fontWithFamily:self.view.font.familyName traits:NSItalicFontMask weight:0 size:font.pointSize];
    }
    [text addAttribute:NSFontAttributeName value:italicFont range:NSMakeRange(position, length)];
}

- (void)applyFontAttributes:(NSDictionary*)attributes toText:(NSMutableAttributedString *)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    for (NSString *key in attributes)
    {
        NSString *value = attributes[key];
        value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];

        if ([key caseInsensitiveCompare:@"color"] == NSOrderedSame)
        {
            [self applyColor:value toText:text atPosition:position withLength:length];
        }
        else if ([key caseInsensitiveCompare:@"stroke"] == NSOrderedSame)
        {
            [text addAttribute:NSStrokeWidthAttributeName value:@([attributes[@"stroke"] floatValue]) range:NSMakeRange(position, length)];
        }
        else if ([key caseInsensitiveCompare:@"kern"] == NSOrderedSame)
        {
            [text addAttribute:NSKernAttributeName value:@([attributes[@"kern"] floatValue]) range:NSMakeRange(position, length)];
        }
        else if ([key caseInsensitiveCompare:@"underline"] == NSOrderedSame)
        {
            NSInteger numberOfLines = [value intValue];
            if (numberOfLines==1)
            {
                [self applySingleUnderlineText:text atPosition:position withLength:length];
            }
            else if (numberOfLines==2)
            {
                [self applyDoubleUnderlineText:text atPosition:position withLength:length];
            }
        }
        else if ([key caseInsensitiveCompare:@"style"] == NSOrderedSame)
        {
            if ([value caseInsensitiveCompare:@"bold"] == NSOrderedSame)
            {
                [self applyBoldStyleToText:text atPosition:position withLength:length];
            }
            else if ([value caseInsensitiveCompare:@"italic"] == NSOrderedSame)
            {
                [self applyItalicStyleToText:text atPosition:position withLength:length];
            }
        }
    }

    NSFont *font = nil;
    if (attributes[@"face"] && attributes[@"size"])
    {
        NSString *fontName = attributes[@"face"];
        fontName = [fontName stringByReplacingOccurrencesOfString:@"'" withString:@""];
        font = [NSFont fontWithName:fontName size:[attributes[@"size"] intValue]];
    }
    else if (attributes[@"face"] && !attributes[@"size"])
    {
        NSString *fontName = attributes[@"face"];
        fontName = [fontName stringByReplacingOccurrencesOfString:@"'" withString:@""];
        font = [NSFont fontWithName:fontName size:self.view.font.pointSize];
    }
    else if (!attributes[@"face"] && attributes[@"size"])
    {
        font = [NSFont fontWithName:[self.view.font fontName] size:[attributes[@"size"] intValue]];
    }
    if (font)
    {
        [text addAttribute:NSFontAttributeName value:font range:NSMakeRange(position, length)];
    }
}

- (void)applyBoldStyleToText:(NSMutableAttributedString *)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    NSFont *font = [text attribute:NSFontAttributeName atIndex:position effectiveRange:nil];
    NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
    if (!boldFont) {
        //fallback to system italic font
        boldFont = [[NSFontManager sharedFontManager] fontWithFamily:self.view.font.familyName traits:NSBoldFontMask weight:0 size:font.pointSize];
    }
    [text addAttribute:NSFontAttributeName value:boldFont range:NSMakeRange(position, length)];
}

- (void)applyBoldItalicStyleToText:(NSMutableAttributedString *)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    NSFont *font = [text attribute:NSFontAttributeName atIndex:position effectiveRange:nil];
    NSFont *boldItalicFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask | NSItalicFontMask];
    if (!boldItalicFont) {
        //fallback to system italic font
        boldItalicFont = [NSFont fontWithName:[NSString stringWithFormat:@"%@-BoldOblique", self.view.font.fontName] size:self.view.font.pointSize];
    }
    if (boldItalicFont) {
        [text addAttribute:NSFontAttributeName value:boldItalicFont range:NSMakeRange(position, length)];
    }
}

- (void)applyColor:(NSString*)value toText:(NSMutableAttributedString *)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    NSColor *color = [self colorFromAttributesValue:value];
    if (color) {
        [self applyNSColor:color toText:text atPosition:position withLength:length];
    }
}

- (void)applyNSColor:(NSColor *)color toText:(NSMutableAttributedString *)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    [text addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(position, length)];
}

- (NSColor *)colorFromAttributesValue:(NSString *)value
{
    if ([value rangeOfString:@"#"].location==0)
    {
        value = [value stringByReplacingOccurrencesOfString:@"#" withString:@""];
        NSArray<NSNumber *> *colorComponents = [self colorForHex:value];
        return [NSColor colorWithRed:colorComponents[0].floatValue green:colorComponents[1].floatValue blue:colorComponents[2].floatValue alpha:colorComponents[3].floatValue];
    } else {
        value = [value stringByAppendingString:@"Color"];
        SEL colorSel = NSSelectorFromString(value);
        if ([NSColor respondsToSelector:colorSel]) {
            return [NSColor performSelector:colorSel];
        }
    }
    return nil;
}

- (void)applyUnderlineColor:(NSString*)value toText:(NSMutableAttributedString *)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    NSColor *color = [self colorFromAttributesValue:value];
    if (color) {
        [text addAttribute:NSUnderlineColorAttributeName value:color range:NSMakeRange(position, length)];
    }
}

- (NSArray*)colorForHex:(NSString *)hexColor
{
    hexColor = [[hexColor stringByTrimmingCharactersInSet:
                 [NSCharacterSet whitespaceAndNewlineCharacterSet]
                 ] uppercaseString];

    NSRange range;
    range.location = 0;
    range.length = 2;

    NSString *rString = [hexColor substringWithRange:range];

    range.location = 2;
    NSString *gString = [hexColor substringWithRange:range];

    range.location = 4;
    NSString *bString = [hexColor substringWithRange:range];

    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];

    NSArray *components = @[@((float) r / 255.0f),@((float) g / 255.0f),@((float) b / 255.0f),@1.0f];
    return components;
}

#pragma mark - Public

- (void)setText:(NSString *)text
{
    if (![_text isEqualToString:text]) {
        _text = [text stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
        [self parseText:_text paragraphReplacement:@"\n"];
        self.attributedText = [self attributedTextWithComponents:self.textComponents plainText:self.plainText];
    }
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    if (![_attributedText isEqualToAttributedString:attributedText]) {
        _attributedText = attributedText;
        [self calculateTrackingArea];
        self.view.attributedStringValue = attributedText;
    }
}

@end

@implementation ARTTextComponent

- (id)initWithString:(NSString*)aText tag:(NSString*)aTagLabel attributes:(NSMutableDictionary*)theAttributes
{
    self = [super init];
    if (self) {
        _text = aText;
        _tagLabel = aTagLabel;
        _attributes = theAttributes;
    }
    return self;
}

+ (id)componentWithString:(NSString*)aText tag:(NSString*)aTagLabel attributes:(NSMutableDictionary*)theAttributes
{
    return [[self alloc] initWithString:aText tag:aTagLabel attributes:theAttributes];
}

- (id)initWithTag:(NSString*)aTagLabel position:(NSInteger)aPosition attributes:(NSMutableDictionary*)theAttributes
{
    self = [super init];
    if (self) {
        _tagLabel = aTagLabel;
        _position = aPosition;
        _attributes = theAttributes;
    }
    return self;
}

+ (id)componentWithTag:(NSString*)aTagLabel position:(NSInteger)aPosition attributes:(NSMutableDictionary*)theAttributes
{
    return [[self alloc] initWithTag:aTagLabel position:aPosition attributes:theAttributes];
}

- (NSString*)description
{
    NSMutableString *desc = [NSMutableString string];
    [desc appendFormat:@"text: %@", self.text];
    [desc appendFormat:@", position: %@", @(self.position)];
    if (self.tagLabel) [desc appendFormat:@", tag: %@", self.tagLabel];
    if (self.attributes) [desc appendFormat:@", attributes: %@", self.attributes];
    return desc;
}

@end

@implementation NSTextField (ARTRichTextController)

// TODO

- (NSEdgeInsets)textInsets
{
    return NSEdgeInsetsMake(5, 2, 5, 2);
}

- (CGFloat)extraLineSpacing
{
    return 5.55; // font size 15
}

@end

@implementation NSTextView (ARTRichTextController)

- (NSAttributedString *)attributedStringValue
{
    return self.textStorage;
}

- (void)setAttributedStringValue:(NSAttributedString *)attributedStringValue
{
    self.textStorage.attributedString = attributedStringValue;
}

- (NSLineBreakMode)lineBreakMode
{
    return self.textContainer.lineBreakMode;
}

- (CGFloat)lineSpacing
{
    return self.defaultParagraphStyle.lineSpacing;
}

- (NSEdgeInsets)textInsets
{
    CGFloat lineFragmentPadding = self.textContainer.lineFragmentPadding;
    return NSEdgeInsetsMake(0, lineFragmentPadding, 0, lineFragmentPadding);
}

@end
