//
//  RTLabel.m
//  RTLabelProject
//
/**
 * Copyright (c) 2010 Muh Hon Cheng
 * Created by honcheng on 1/6/11.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining 
 * a copy of this software and associated documentation files (the 
 * "Software"), to deal in the Software without restriction, including 
 * without limitation the rights to use, copy, modify, merge, publish, 
 * distribute, sublicense, and/or sell copies of the Software, and to 
 * permit persons to whom the Software is furnished to do so, subject 
 * to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be 
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT 
 * WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR 
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT 
 * SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
 * IN CONNECTION WITH THE SOFTWARE OR 
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 * @author 		Muh Hon Cheng <honcheng@gmail.com>
 * @copyright	2011	Muh Hon Cheng
 * @version
 * 
 */

#import "RTLabel.h"
#import "ARTControl.h"

@interface RTLabelButton : ARTControl
@property (nonatomic, assign) NSInteger componentIndex;
@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *link;
@end

@implementation RTLabelButton
@end

@implementation RTLabelComponent

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

+(id)componentWithTag:(NSString*)aTagLabel position:(NSInteger)aPosition attributes:(NSMutableDictionary*)theAttributes
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

@implementation RTLabelExtractedComponent

+ (RTLabelExtractedComponent*)rtLabelExtractComponentsWithTextComponent:(NSMutableArray*)textComponents plainText:(NSString*)plainText
{
    RTLabelExtractedComponent *component = [[RTLabelExtractedComponent alloc] init];
    [component setTextComponents:textComponents];
    [component setPlainText:plainText];
    return component;
}

@end

@interface RTLabel()
- (CGFloat)frameHeight:(CTFrameRef)frame;
- (NSArray *)components;
- (void)parse:(NSString *)data valid_tags:(NSArray *)valid_tags;
- (NSArray*) colorForHex:(NSString *)hexColor;
- (void)render;

#pragma mark -
#pragma mark styling

- (void)applyItalicStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applyBoldStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applyBoldItalicStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applyColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applySingleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applyDoubleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applyUnderlineColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applyFontAttributes:(NSDictionary*)attributes toText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length;
- (void)applyParagraphStyleToText:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(NSInteger)position withLength:(NSInteger)length;
@end

NSSet *RTLabelValidTags;

@implementation RTLabel

+ (void)load
{
    RTLabelValidTags = [NSSet setWithObjects:
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
}

- (id)initWithFrame:(CGRect)_frame
{
    self = [super initWithFrame:_frame];
    if (self)
	{
		[self initialize];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{    
    self = [super initWithCoder:aDecoder];
    if (self)
	{
		[self initialize];
    }
    return self;
}

- (void)initialize
{
//    [self setBackgroundColor:[UIColor clearColor]];

	_font = [NSFont systemFontOfSize:15];
	_textColor = [NSColor blackColor];
	_text = @"";
	_textAlignment = RTTextAlignmentLeft;
	_lineBreakMode = RTTextLineBreakModeWordWrapping;
	_lineSpacing = 3;
	_currentSelectedButtonComponentIndex = -1;
    _currentMouseInsideButtonComponentIndex = -1;
	_paragraphReplacement = @"\n";
	
	#if TARGET_OS_IOS
	[self setMultipleTouchEnabled:YES];
#endif
}

- (void)setTextAlignment:(RTTextAlignment)textAlignment
{
	_textAlignment = textAlignment;
	[self setNeedsDisplay:YES];
}

- (void)setLineBreakMode:(RTTextLineBreakMode)lineBreakMode
{
	_lineBreakMode = lineBreakMode;
    [self setNeedsDisplay:YES];
}

- (void)setNeedsDisplay:(BOOL)needsDisplay
{
    [super setNeedsDisplay:needsDisplay];
}

- (void)drawRect:(CGRect)rect 
{
	[self render];
}

- (void)render
{
    if (self.currentSelectedButtonComponentIndex == -1 &&
        self.currentMouseInsideButtonComponentIndex == -1)
    {
        for (id view in [self subviews].copy)
        {
            if ([view isKindOfClass:[NSView class]])
            {
                [view removeFromSuperview];
            }
        }
        for (NSTrackingArea *trackingArea in self.trackingAreas) {
            [self removeTrackingArea:trackingArea];
        }
    }
    if (!self.plainText) return;

    CGContextRef context = [NSGraphicsContext currentContext].CGContext;
    if (context != NULL)
    {
        // Drawing code.
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
//        CGAffineTransform flipVertical = CGAffineTransformMake(1,0,0,-1,0,self.frame.size.height);
//        CGContextConcatCTM(context, flipVertical);
    }
	
	// Initialize an attributed string.
	CFStringRef string = (__bridge CFStringRef)self.plainText;
	CFMutableAttributedStringRef attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
	CFAttributedStringReplaceString (attrString, CFRangeMake(0, 0), string);
	
	CFMutableDictionaryRef styleDict1 = ( CFDictionaryCreateMutable( (0), 0, (0), (0) ) );
	// Create a color and add it as an attribute to the string.
	CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorSpaceRelease(rgbColorSpace);
	CFDictionaryAddValue( styleDict1, kCTForegroundColorAttributeName, [self.textColor CGColor] );
	CFAttributedStringSetAttributes( attrString, CFRangeMake( 0, CFAttributedStringGetLength(attrString) ), styleDict1, 0 ); 
	
	CFMutableDictionaryRef styleDict = ( CFDictionaryCreateMutable( (0), 0, (0), (0) ) );
	
	[self applyParagraphStyleToText:attrString attributes:nil atPosition:0 withLength:CFAttributedStringGetLength(attrString)];
	
	
	CTFontRef thisFont = CTFontCreateWithName ((__bridge CFStringRef)[self.font fontName], [self.font pointSize], NULL); 
	CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFAttributedStringGetLength(attrString)), kCTFontAttributeName, thisFont);
	
	NSMutableArray *links = [NSMutableArray array];
	NSMutableArray *textComponents = nil;
    if (self.highlighted) textComponents = self.highlightedTextComponents;
    else textComponents = self.textComponents;
    
	for (RTLabelComponent *component in textComponents)
	{
		NSInteger index = [textComponents indexOfObject:component];
		component.componentIndex = index;
		
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
            if (self.currentMouseInsideButtonComponentIndex == index)
            {
                // 移动进并选中
                if (self.currentSelectedButtonComponentIndex==index)
                {
                    if (self.selectedLinkAttributes)
                    {
                        [self applyFontAttributes:self.selectedLinkAttributes toText:attrString atPosition:component.position withLength:[component.text length]];
                    }
                    else
                    {
                        NSString *colorValue = component.attributes[@"color"];
                        if (!colorValue) {
                            for (RTLabelComponent *cpt in textComponents) {
                                if (cpt.position == component.position) {
                                    colorValue = cpt.attributes[@"color"];
                                    break;
                                }
                            }
                        }
                        if (colorValue) {
                            [self applyCGColor:[[self colorFromAttributesValue:colorValue] blendedColorWithFraction:.3 ofColor:NSColor.blackColor].CGColor toText:attrString atPosition:component.position withLength:[component.text length]];
                        } else {
                            // default
                            [self applyBoldStyleToText:attrString atPosition:component.position withLength:[component.text length]];
                            [self applyColor:@"#FF0000" toText:attrString atPosition:component.position withLength:[component.text length]];
                        }
                    }
                }
                else // 仅移动进
                {
                    NSString *colorValue = component.attributes[@"color"];
                    if (!colorValue) {
                        for (RTLabelComponent *cpt in textComponents) {
                            if (cpt.position == component.position) {
                                colorValue = cpt.attributes[@"color"];
                                break;
                            }
                        }
                    }
                    if (colorValue) {
                        [self applyCGColor:[[self colorFromAttributesValue:colorValue] blendedColorWithFraction:.3 ofColor:NSColor.whiteColor].CGColor toText:attrString atPosition:component.position withLength:[component.text length]];
                    } else {
                        if (self.linkAttributes)
                        {
                            [self applyFontAttributes:self.linkAttributes toText:attrString atPosition:component.position withLength:[component.text length]];
                        }
                        else
                        {
                            [self applyFontAttributes:component.attributes toText:attrString atPosition:component.position withLength:component.text.length];
//                            [self applyBoldStyleToText:attrString atPosition:component.position withLength:[component.text length]];
//                            [self applySingleUnderlineText:attrString atPosition:component.position withLength:[component.text length]];
                        }
                    }
                }
            }
            else
            {
                if (self.linkAttributes)
                {
                    [self applyFontAttributes:self.linkAttributes toText:attrString atPosition:component.position withLength:[component.text length]];
                }
                else
                {
                    [self applyFontAttributes:component.attributes toText:attrString atPosition:component.position withLength:component.text.length];
//                    [self applyBoldStyleToText:attrString atPosition:component.position withLength:[component.text length]];
//                    [self applySingleUnderlineText:attrString atPosition:component.position withLength:[component.text length]];
                }
            }
			
			NSString *value = (component.attributes)[@"href"];
			value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
			
			if(value)
				component.attributes[@"href"] = value;
			
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
    
    // Create the framesetter with the attributed string.
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attrString);
    CFRelease(attrString);
	
    // Initialize a rectangular path.
	CGMutablePathRef path = CGPathCreateMutable();
	CGRect bounds = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
	CGPathAddRect(path, NULL, bounds);
	
	// Create the frame and draw it into the graphics context
	//CTFrameRef 
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0, 0), path, NULL);
	
	CFRange range;
	CGSize constraint = CGSizeMake(self.frame.size.width, CGFLOAT_MAX);
	self.optimumSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [self.plainText length]), nil, constraint, &range);
	
	
	if (self.currentSelectedButtonComponentIndex==-1)
	{
		// only check for linkable items the first time, not when it's being redrawn on button pressed
		
		for (RTLabelComponent *linkableComponents in links)
		{
			CGFloat height = self.bounds.size.height;
			CFArrayRef frameLines = CTFrameGetLines(frame);
			for (CFIndex i=0; i<CFArrayGetCount(frameLines); i++)
			{
				CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(frameLines, i);
				CFRange lineRange = CTLineGetStringRange(line);
				CGFloat ascent;
				CGFloat descent;
				CGFloat leading;
				
				CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
                CGPoint origin;
				CTFrameGetLineOrigins(frame, CFRangeMake(i, 1), &origin);
                
				if ( (linkableComponents.position<lineRange.location && linkableComponents.position+linkableComponents.text.length>(u_int16_t)(lineRange.location)) || (linkableComponents.position>=lineRange.location && linkableComponents.position<lineRange.location+lineRange.length))
				{
					CGFloat secondaryOffset;
					CGFloat primaryOffset = CTLineGetOffsetForStringIndex(CFArrayGetValueAtIndex(frameLines,i), linkableComponents.position, &secondaryOffset);
					CGFloat primaryOffset2 = CTLineGetOffsetForStringIndex(CFArrayGetValueAtIndex(frameLines,i), linkableComponents.position+linkableComponents.text.length, NULL);
					
					CGFloat button_width = primaryOffset2 - primaryOffset;
					
					RTLabelButton *button = [[RTLabelButton alloc] initWithFrame:CGRectMake(primaryOffset+origin.x, origin.y - descent, button_width, ascent+descent)];
					
//                    [button setBackgroundColor:[UIColor colorWithWhite:0 alpha:0]];
					[button setComponentIndex:linkableComponents.componentIndex];
                    [button setUrl:[NSURL URLWithString:(linkableComponents.attributes)[@"href"]]];
                    button.link = linkableComponents.attributes[@"href"];
                    __weak typeof(self) weakSelf = self;
                    button.eventHandler = ^(__kindof ARTControl * _Nonnull button, ARTControlEventType type, NSEvent *event)
                    {
                        switch (type) {
                            case ARTControlEventTypeMouseIn:
//                                [weakSelf onButtonMouseIn:button];
                                break;
                            case ARTControlEventTypeMouseOut:
//                                [weakSelf onButtonMouseOut:button];
                                break;
                            case ARTControlEventTypeMouseDown:
                            case ARTControlEventTypeRightMouseDown:
                                [weakSelf onButtonTouchDown:button];
                                break;
                            case ARTControlEventTypeMouseUpOutside:
                            case ARTControlEventTypeRightMouseUpOutside:
                                [weakSelf onButtonTouchUpOutside:button];
                                break;
                            case ARTControlEventTypeMouseUpInside:
                                [weakSelf onButtonClicked:button rightMouse:NO];
                                break;
                            case ARTControlEventTypeRightMouseUpInside:
                                [weakSelf onButtonClicked:button rightMouse:YES];
                                break;
                            default:
                                break;
                        }
                    };

//                    [button addTarget:self action:@selector(onButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
//                    [button addTarget:self action:@selector(onButtonTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
//                    [button addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                    [self addSubview:button];

                    [self addTrackingArea:[[NSTrackingArea alloc] initWithRect:button.frame options:NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:@{@"index": @(linkableComponents.componentIndex)}]];
				}
				
				origin.y = self.frame.size.height - origin.y;
				height = origin.y + descent + _lineSpacing;
			}
		}
	}
	
	self.visibleRange = CTFrameGetVisibleStringRange(frame);

	CFRelease(thisFont);
	CFRelease(path);
	CFRelease(styleDict1);
	CFRelease(styleDict);
	CFRelease(framesetter);
	CTFrameDraw(frame, context);
    CFRelease(frame);
}

#pragma mark -
#pragma mark styling

- (void)applyParagraphStyleToText:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(NSInteger)position withLength:(NSInteger)length
{
	CFMutableDictionaryRef styleDict = ( CFDictionaryCreateMutable( (0), 0, (0), (0) ) );
	
	// direction
	CTWritingDirection direction = kCTWritingDirectionLeftToRight; 
	// leading
	CGFloat firstLineIndent = 0.0; 
	CGFloat headIndent = 0.0; 
	CGFloat tailIndent = 0.0; 
	CGFloat lineHeightMultiple = 1.0; 
	CGFloat maxLineHeight = 0; 
	CGFloat minLineHeight = 0; 
	CGFloat paragraphSpacing = 0.0;
	CGFloat paragraphSpacingBefore = 0.0;
	CTTextAlignment textAlignment = (CTTextAlignment)_textAlignment;
	CTLineBreakMode lineBreakMode = (CTLineBreakMode)_lineBreakMode;
	CGFloat lineSpacing = _lineSpacing;
	
	for (NSUInteger i=0; i<[[attributes allKeys] count]; i++)
	{
		NSString *key = [attributes allKeys][i];
		id value = attributes[key];
		if ([key caseInsensitiveCompare:@"align"] == NSOrderedSame)
		{
			if ([value caseInsensitiveCompare:@"left"] == NSOrderedSame)
			{
				textAlignment = kCTTextAlignmentLeft;
			}
			else if ([value caseInsensitiveCompare:@"right"] == NSOrderedSame)
			{
				textAlignment = kCTTextAlignmentRight;
			}
			else if ([value caseInsensitiveCompare:@"justify"] == NSOrderedSame)
			{
				textAlignment = kCTTextAlignmentJustified;
			}
			else if ([value caseInsensitiveCompare:@"center"] == NSOrderedSame)
			{
				textAlignment = kCTTextAlignmentCenter;
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
				lineBreakMode = kCTLineBreakByWordWrapping;
			}
			else if ([value caseInsensitiveCompare:@"charwrap"] == NSOrderedSame)
			{
				lineBreakMode = kCTLineBreakByCharWrapping;
			}
			else if ([value caseInsensitiveCompare:@"clipping"] == NSOrderedSame)
			{
				lineBreakMode = kCTLineBreakByClipping;
			}
			else if ([value caseInsensitiveCompare:@"truncatinghead"] == NSOrderedSame)
			{
				lineBreakMode = kCTLineBreakByTruncatingHead;
			}
			else if ([value caseInsensitiveCompare:@"truncatingtail"] == NSOrderedSame)
			{
				lineBreakMode = kCTLineBreakByTruncatingTail;
			}
			else if ([value caseInsensitiveCompare:@"truncatingmiddle"] == NSOrderedSame)
			{
				lineBreakMode = kCTLineBreakByTruncatingMiddle;
			}
		}
	}
	
	CTParagraphStyleSetting theSettings[] =
	{
		{ kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &textAlignment },
		{ kCTParagraphStyleSpecifierLineBreakMode, sizeof(CTLineBreakMode), &lineBreakMode  },
		{ kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(CTWritingDirection), &direction }, 
		{ kCTParagraphStyleSpecifierMinimumLineSpacing, sizeof(CGFloat), &lineSpacing }, // leading
		{ kCTParagraphStyleSpecifierMaximumLineSpacing, sizeof(CGFloat), &lineSpacing }, // leading
		{ kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &firstLineIndent },
		{ kCTParagraphStyleSpecifierHeadIndent, sizeof(CGFloat), &headIndent }, 
		{ kCTParagraphStyleSpecifierTailIndent, sizeof(CGFloat), &tailIndent }, 
		{ kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(CGFloat), &lineHeightMultiple }, 
		{ kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(CGFloat), &maxLineHeight }, 
		{ kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(CGFloat), &minLineHeight }, 
		{ kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &paragraphSpacing }, 
		{ kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &paragraphSpacingBefore }
	};
	
	
	CTParagraphStyleRef theParagraphRef = CTParagraphStyleCreate(theSettings, sizeof(theSettings) / sizeof(CTParagraphStyleSetting));
	CFDictionaryAddValue( styleDict, kCTParagraphStyleAttributeName, theParagraphRef );
	
	CFAttributedStringSetAttributes( text, CFRangeMake(position, length), styleDict, 0 ); 
	CFRelease(theParagraphRef);
    CFRelease(styleDict);
}

- (void)applyCenterStyleToText:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(NSInteger)position withLength:(NSInteger)length
{
	CFMutableDictionaryRef styleDict = ( CFDictionaryCreateMutable( (0), 0, (0), (0) ) );
	
	// direction
	CTWritingDirection direction = kCTWritingDirectionLeftToRight;
	// leading
	CGFloat firstLineIndent = 0.0;
	CGFloat headIndent = 0.0;
	CGFloat tailIndent = 0.0;
	CGFloat lineHeightMultiple = 1.0;
	CGFloat maxLineHeight = 0;
	CGFloat minLineHeight = 0;
	CGFloat paragraphSpacing = 0.0;
	CGFloat paragraphSpacingBefore = 0.0;
	NSInteger textAlignment = _textAlignment;
	NSInteger lineBreakMode = _lineBreakMode;
	NSInteger lineSpacing = (NSInteger)_lineSpacing;

    textAlignment = kCTTextAlignmentCenter;
	
	CTParagraphStyleSetting theSettings[] =
	{
		{ kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &textAlignment },
		{ kCTParagraphStyleSpecifierLineBreakMode, sizeof(CTLineBreakMode), &lineBreakMode  },
		{ kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(CTWritingDirection), &direction },
		{ kCTParagraphStyleSpecifierLineSpacingAdjustment, sizeof(CGFloat), &lineSpacing },
		{ kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &firstLineIndent },
		{ kCTParagraphStyleSpecifierHeadIndent, sizeof(CGFloat), &headIndent },
		{ kCTParagraphStyleSpecifierTailIndent, sizeof(CGFloat), &tailIndent },
		{ kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(CGFloat), &lineHeightMultiple },
		{ kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(CGFloat), &maxLineHeight },
		{ kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(CGFloat), &minLineHeight },
		{ kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &paragraphSpacing },
		{ kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &paragraphSpacingBefore }
	};
	
	CTParagraphStyleRef theParagraphRef = CTParagraphStyleCreate(theSettings, sizeof(theSettings) / sizeof(CTParagraphStyleSetting));
	CFDictionaryAddValue( styleDict, kCTParagraphStyleAttributeName, theParagraphRef );
	
	CFAttributedStringSetAttributes( text, CFRangeMake(position, length), styleDict, 0 );
	CFRelease(theParagraphRef);
    CFRelease(styleDict);
}

- (void)applySingleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
	CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTUnderlineStyleAttributeName,  (__bridge CFNumberRef)@(kCTUnderlineStyleSingle));
}

- (void)applyDoubleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
	CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTUnderlineStyleAttributeName,  (__bridge CFNumberRef)@(kCTUnderlineStyleDouble));
}

- (void)applyItalicStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    CFTypeRef actualFontRef = CFAttributedStringGetAttribute(text, position, kCTFontAttributeName, NULL);
    CTFontRef italicFontRef = CTFontCreateCopyWithSymbolicTraits(actualFontRef, 0.0, NULL, kCTFontItalicTrait, kCTFontItalicTrait);
    if (!italicFontRef) {
        //fallback to system italic font
        NSFont *font = [[NSFontManager sharedFontManager] fontWithFamily:self.font.familyName traits:NSItalicFontMask weight:0 size:CTFontGetSize(actualFontRef)];
        italicFontRef = CTFontCreateWithName ((__bridge CFStringRef)[font fontName], [font pointSize], NULL);
    }
    CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, italicFontRef);
    CFRelease(italicFontRef);
}

- (void)applyFontAttributes:(NSDictionary*)attributes toText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
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
			CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTStrokeWidthAttributeName, (__bridge CFTypeRef)([NSNumber numberWithFloat:[attributes[@"stroke"] intValue]]));
		}
		else if ([key caseInsensitiveCompare:@"kern"] == NSOrderedSame)
		{
			CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTKernAttributeName, (__bridge CFTypeRef)([NSNumber numberWithFloat:[attributes[@"kern"] intValue]]));
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
		font = [NSFont fontWithName:fontName size:self.font.pointSize];
	}
	else if (!attributes[@"face"] && attributes[@"size"])
	{
		font = [NSFont fontWithName:[self.font fontName] size:[attributes[@"size"] intValue]];
	}
	if (font)
	{
		CTFontRef customFont = CTFontCreateWithName ((__bridge CFStringRef)[font fontName], [font pointSize], NULL); 
		CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, customFont);
		CFRelease(customFont);
	}
}

- (void)applyBoldStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    CFTypeRef actualFontRef = CFAttributedStringGetAttribute(text, position, kCTFontAttributeName, NULL);
    CTFontRef boldFontRef = CTFontCreateCopyWithSymbolicTraits(actualFontRef, 0.0, NULL, kCTFontBoldTrait, kCTFontBoldTrait);
    if (!boldFontRef) {
        //fallback to system bold font
        NSFont *font = [NSFont boldSystemFontOfSize:CTFontGetSize(actualFontRef)];
        boldFontRef = CTFontCreateWithName ((__bridge CFStringRef)[font fontName], [font pointSize], NULL);
    }
    CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, boldFontRef);
    CFRelease(boldFontRef);
}

- (void)applyBoldItalicStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    CFTypeRef actualFontRef = CFAttributedStringGetAttribute(text, position, kCTFontAttributeName, NULL);
    CTFontRef boldItalicFontRef = CTFontCreateCopyWithSymbolicTraits(actualFontRef, 0.0, NULL, kCTFontBoldTrait | kCTFontItalicTrait , kCTFontBoldTrait | kCTFontItalicTrait);
    if (!boldItalicFontRef) {
        //try fallback to system boldItalic font
        NSString *fontName = [NSString stringWithFormat:@"%@-BoldOblique", self.font.fontName];
        boldItalicFontRef = CTFontCreateWithName ((__bridge CFStringRef)fontName, [self.font pointSize], NULL);
    }
    
    if (boldItalicFontRef) {
        CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, boldItalicFontRef);
        CFRelease(boldItalicFontRef);
    }

}

- (void)applyColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    NSColor *color = [self colorFromAttributesValue:value];
    if (color) {
        [self applyCGColor:color.CGColor toText:text atPosition:position withLength:length];
    }
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

- (void)applyCGColor:(CGColorRef)color toText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
    CFAttributedStringSetAttribute(text, CFRangeMake(position, length),kCTForegroundColorAttributeName, color);
}

- (void)applyUnderlineColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(NSInteger)position withLength:(NSInteger)length
{
	
	value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
	if ([value rangeOfString:@"#"].location==0) {
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
		value = [value stringByReplacingOccurrencesOfString:@"#" withString:@"0x"];
		NSArray *colorComponents = [self colorForHex:value];
		CGFloat components[] = { [colorComponents[0] floatValue] , [colorComponents[1] floatValue] , [colorComponents[2] floatValue] , [colorComponents[3] floatValue] };
		CGColorRef color = CGColorCreate(rgbColorSpace, components);
		CFAttributedStringSetAttribute(text, CFRangeMake(position, length),kCTUnderlineColorAttributeName, color);
		CGColorRelease(color);
        CGColorSpaceRelease(rgbColorSpace);
	}
	else
	{
		value = [value stringByAppendingString:@"Color"];
		SEL colorSel = NSSelectorFromString(value);
		if ([NSColor respondsToSelector:colorSel]) {
			NSColor *_color = [NSColor performSelector:colorSel];
			CGColorRef color = [_color CGColor];
			CFAttributedStringSetAttribute(text, CFRangeMake(position, length),kCTUnderlineColorAttributeName, color);
			//CGColorRelease(color);
		}				
	}
}

#pragma mark -
#pragma mark button

- (void)mouseEntered:(NSEvent *)theEvent
{
    NSInteger index = [theEvent.trackingArea.userInfo[@"index"] integerValue];
    if (self.currentMouseInsideButtonComponentIndex != index) {
        self.currentMouseInsideButtonComponentIndex = index;
        self.needsDisplay = YES;
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    if (self.currentMouseInsideButtonComponentIndex != -1) {
        self.currentMouseInsideButtonComponentIndex = -1;
        self.needsDisplay = YES;
    }
}

- (void)onButtonMouseIn:(RTLabelButton *)sender
{
    self.currentMouseInsideButtonComponentIndex = sender.componentIndex;
    self.needsDisplay = YES;
}

- (void)onButtonMouseOut:(RTLabelButton *)sender
{
    self.currentMouseInsideButtonComponentIndex = -1;
    self.needsDisplay = YES;
}

- (void)onButtonTouchDown:(id)sender
{
	RTLabelButton *button = (RTLabelButton*)sender;
    [self setCurrentSelectedButtonComponentIndex:button.componentIndex];
    [self setNeedsDisplay:YES];
}

- (void)onButtonTouchUpOutside:(id)sender
{
	[self setCurrentSelectedButtonComponentIndex:-1];
	[self setNeedsDisplay:YES];
}

- (void)onButtonClicked:(id)sender rightMouse:(BOOL)rightMouse
{
	RTLabelButton *button = (RTLabelButton*)sender;
	[self setCurrentSelectedButtonComponentIndex:-1];
	[self setNeedsDisplay:YES];

	if ([self.delegate respondsToSelector:@selector(label:didSelectLinkWithURL:rightMouse:)])
	{
		[self.delegate label:self didSelectLinkWithURL:button.url rightMouse:rightMouse];
	}
    if ([self.delegate respondsToSelector:@selector(label:didSelectLink:rightMouse:)])
    {
        [self.delegate label:self didSelectLink:button.link rightMouse:rightMouse];
    }
}

- (CGSize)optimumSize
{
	[self render];
	return _optimumSize;
}

- (void)setLineSpacing:(CGFloat)lineSpacing
{
	_lineSpacing = lineSpacing;
	[self setNeedsDisplay:YES];
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (highlighted!=_highlighted)
    {
        _highlighted = highlighted;
        [self setNeedsDisplay:YES];
    }
}

- (void)setHighlightedText:(NSString *)text
{
	_highlightedText = [text stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
	RTLabelExtractedComponent *component = [RTLabel extractTextStyleFromText:_highlightedText paragraphReplacement:self.paragraphReplacement];
    [self setHighlightedTextComponents:component.textComponents];
}

- (void)setText:(NSString *)text
{
	_text = [text stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
	RTLabelExtractedComponent *component = [RTLabel extractTextStyleFromText:_text paragraphReplacement:self.paragraphReplacement];
    [self setTextComponents:component.textComponents];
    [self setPlainText:component.plainText];
    [self setNeedsDisplay:YES];
}

- (void)setText:(NSString *)text extractedTextComponent:(RTLabelExtractedComponent*)extractedComponent
{
	_text = [text stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    [self setTextComponents:extractedComponent.textComponents];
    [self setPlainText:extractedComponent.plainText];
	[self setNeedsDisplay:YES];
}

- (void)setHighlightedText:(NSString *)text extractedTextComponent:(RTLabelExtractedComponent*)extractedComponent
{
    _highlightedText = [text stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    [self setHighlightedTextComponents:extractedComponent.textComponents];
}

// http://forums.macrumors.com/showthread.php?t=925312
// not accurate
- (CGFloat)frameHeight:(CTFrameRef)theFrame
{
	CFArrayRef lines = CTFrameGetLines(theFrame);
    CGFloat height = 0.0;
    CGFloat ascent, descent, leading;
    for (CFIndex index = 0; index < CFArrayGetCount(lines); index++) {
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, index);
        CTLineGetTypographicBounds(line, &ascent,  &descent, &leading);
        height += (ascent + fabs(descent) + leading);
    }
    return (CGFloat)ceil(height);
}

- (void)dealloc 
{
    self.delegate = nil;
}

- (NSArray *)components
{
	NSScanner *scanner = [NSScanner scannerWithString:self.text];
	[scanner setCharactersToBeSkipped:nil]; 
	
	NSMutableArray *components = [NSMutableArray array];
	
	while (![scanner isAtEnd]) 
	{
		NSString *currentComponent;
		BOOL foundComponent = [scanner scanUpToString:@"http" intoString:&currentComponent];
		if (foundComponent) 
		{
			[components addObject:currentComponent];
			
			NSString *string;
			BOOL foundURLComponent = [scanner scanUpToString:@" " intoString:&string];
			if (foundURLComponent) 
			{
				// if last character of URL is punctuation, its probably not part of the URL
				NSCharacterSet *punctuationSet = [NSCharacterSet punctuationCharacterSet];
				NSInteger lastCharacterIndex = string.length - 1;
				if ([punctuationSet characterIsMember:[string characterAtIndex:lastCharacterIndex]]) 
				{
					// remove the punctuation from the URL string and move the scanner back
					string = [string substringToIndex:lastCharacterIndex];
					[scanner setScanLocation:scanner.scanLocation - 1];
				}        
				[components addObject:string];
			}
		} 
		else 
		{ // first string is a link
			NSString *string;
			BOOL foundURLComponent = [scanner scanUpToString:@" " intoString:&string];
			if (foundURLComponent) 
			{
				[components addObject:string];
			}
		}
	}
	return [components copy];
}

+ (RTLabelExtractedComponent*)extractTextStyleFromText:(NSString*)data paragraphReplacement:(NSString*)paragraphReplacement
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
        if (![RTLabelValidTags containsObject:[[text substringFromIndex:1] componentsSeparatedByString:@" "].firstObject])
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
					RTLabelComponent *component = components[i];
					if (component.text==nil && [component.tagLabel isEqualToString:tag])
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

			// start of tag
            /*
			NSArray *textComponents = [[text substringFromIndex:1] componentsSeparatedByString:@" "];
			tag = textComponents[0];
			//NSLog(@"start of tag: %@", tag);
			NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
			for (NSUInteger i=1; i<[textComponents count]; i++)
			{
				NSArray *pair = [textComponents[i] componentsSeparatedByString:@"="];
				if ([pair count] > 0) {
					NSString *key = [pair[0] lowercaseString];
					
					if ([pair count]>=2) {
						// Trim " charactere
						NSString *value = [[pair subarrayWithRange:NSMakeRange(1, [pair count] - 1)] componentsJoinedByString:@"="];
						value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, MIN(1, value.length))];
						value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange(MAX(0, (NSInteger)[value length]-1), MIN(1, value.length))];
						
						attributes[key] = value;
					} else if ([pair count]==1) {
						attributes[key] = key;
					}
				}
			}
             */
			RTLabelComponent *component = [RTLabelComponent componentWithString:nil tag:tag attributes:attributes];
			component.position = position;
			[components addObject:component];
		}
		last_position = position;
	}
	
    return [RTLabelExtractedComponent rtLabelExtractComponentsWithTextComponent:components plainText:data];
}


- (void)parse:(NSString *)data valid_tags:(NSArray *)valid_tags
{
	//use to strip the HTML tags from the data
	NSScanner *scanner = nil;
	NSString *text = nil;
	NSString *tag = nil;
	
	NSMutableArray *components = [NSMutableArray array];
	
	//set up the scanner
	scanner = [NSScanner scannerWithString:data];
	NSMutableDictionary *lastAttributes = nil;
	
	NSInteger last_position = 0;
	while([scanner isAtEnd] == NO) 
	{
		//find start of tag
		[scanner scanUpToString:@"<" intoString:NULL];
		
		//find end of tag
		[scanner scanUpToString:@">" intoString:&text];
		
		NSMutableDictionary *attributes = nil;
		//get the name of the tag
		if([text rangeOfString:@"</"].location != NSNotFound)
			tag = [text substringFromIndex:2]; //remove </
		else 
		{
			tag = [text substringFromIndex:1]; //remove <
			//find out if there is a space in the tag
			if([tag rangeOfString:@" "].location != NSNotFound)
			{
				attributes = [NSMutableDictionary dictionary];
				NSArray *rawAttributes = [tag componentsSeparatedByString:@" "];
				for (NSUInteger i=1; i<[rawAttributes count]; i++)
				{
					NSArray *pair = [rawAttributes[i] componentsSeparatedByString:@"="];
					if ([pair count]==2)
					{
						attributes[pair[0]] = pair[1];
					}
				}
				
				//remove text after a space
				tag = [tag substringToIndex:[tag rangeOfString:@" "].location];
			}
		}
		
		//if not a valid tag, replace the tag with a space
		if([valid_tags containsObject:tag] == NO)
		{
			NSString *delimiter = [NSString stringWithFormat:@"%@>", text];
			NSInteger position = [data rangeOfString:delimiter].location;
			BOOL isEnd = [delimiter rangeOfString:@"</"].location!=NSNotFound;
			if (position!=NSNotFound)
			{
				NSString *text2 = [data substringWithRange:NSMakeRange(last_position, position-last_position)];
				if (isEnd)
				{
					// is inside a tag
					[components addObject:[RTLabelComponent componentWithString:text2 tag:tag attributes:lastAttributes]];
				}
				else
				{
					// is outside a tag
					[components addObject:[RTLabelComponent componentWithString:text2 tag:nil attributes:lastAttributes]];
				}
				data = [data stringByReplacingOccurrencesOfString:delimiter withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, position+delimiter.length-last_position)];
				
				last_position = position;
			}
			else
			{
				NSString *text2 = [data substringFromIndex:last_position];
				// is outside a tag
				[components addObject:[RTLabelComponent componentWithString:text2 tag:nil attributes:lastAttributes]];
			}
			lastAttributes = attributes;
		}
	}
    [self setTextComponents:components];
    [self setPlainText:data];
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

- (NSString*)visibleText
{
    [self render];
    NSString *text = [self.text substringWithRange:NSMakeRange(self.visibleRange.location, self.visibleRange.length)];
    return text;
}

#pragma mark deprecated methods

- (void)setText:(NSString *)text extractedTextStyle:(NSDictionary*)extractTextStyle
{
	_text = [text stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    [self setTextComponents:extractTextStyle[@"textComponents"]];
    [self setPlainText:extractTextStyle[@"plainText"]];
	[self setNeedsDisplay:YES];
}

+ (NSDictionary*)preExtractTextStyle:(NSString*)data
{
    NSString* paragraphReplacement = @"\n";
	
    RTLabelExtractedComponent *component = [RTLabel extractTextStyleFromText:data paragraphReplacement:paragraphReplacement];
	return @{@"textComponents": component.textComponents, @"plainText": component.plainText};
}


@end
