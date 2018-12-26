//
//  ARTCategoryView.m
//  Rcode
//
//  Created by TozyZuo on 2018/12/11.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTCategoryView.h"
#import <XUIKit/XUIKit.h>

@interface ARTCategoryView ()
@property (nonatomic, strong) NSFont *font;
@property (nonatomic, strong) NSCache<NSAttributedString *, NSBezierPath *> *cache;
@end

@implementation ARTCategoryView

- (void)initialize
{
    [super initialize];
    self.strokeColor = NSColor.whiteColor;
    self.textColor = NSColor.whiteColor;
//    self.font = [NSFont fontWithName:@"PingFangSC-Semibold" size:100];
    self.font = [NSFont boldSystemFontOfSize:100];
}

- (void)setColor:(NSColor *)color
{
    if (![_color isEqual:color]) {
        _color = color;
        self.needsDisplay = YES;
    }
}

- (void)setTextColor:(NSColor *)textColor
{
    if (![_textColor isEqual:textColor]) {
        _textColor = textColor;
        self.needsDisplay = YES;
    }
}

- (void)setFont:(NSFont *)font
{
    if (![_font isEqual:font]) {
        _font = font;
        self.needsDisplay = YES;
    }
}

- (void)setCharacter:(NSAttributedString *)character
{
    NSAssert(character.length == 1, @"");

    if ([character isKindOfClass:NSString.class]) {
        character = [[NSAttributedString alloc] initWithString:(NSString *)character];
    }

    if (![character isEqualToAttributedString:_character]) {
        _character = character;
        self.needsDisplay = YES;
    }
}

- (NSBezierPath *)pathForCharacter:(NSAttributedString *)character
{
    NSBezierPath *bezierPath = [self.cache objectForKey:character];
    if (bezierPath) {
        return bezierPath;
    }

    NSMutableAttributedString *string = character.mutableCopy;
    NSFont *font = [string attributesAtIndex:0 effectiveRange:NULL][NSFontAttributeName];
    if (!font) {
        font = self.font;
    }
    font = [NSFont fontWithName:font.fontName size:100];
    [string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.length)];

    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFTypeRef)string);

    CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(CTLineGetGlyphRuns(line), 0);

    CGGlyph glyph;
    CTRunGetGlyphs(run, CFRangeMake(0, 1), &glyph);
    CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);

//    NSBezierPath *bPath = [NSBezierPath bezierPath];
//    [bPath appendBezierPathWithCGGlyph:glyph inFont:self.font];

    CGMutablePathRef path = CGPathCreateMutable();

    CGPathRef glyphPath = CTFontCreatePathForGlyph(runFont, glyph, NULL);
    CGRect boundingBox = CGPathGetPathBoundingBox(glyphPath);

    CGFloat width = MIN(boundingBox.size.width, boundingBox.size.height);

    CGFloat deltaY = 0;

    // 12 -> 1.5 100 -> 12.5
    if ([string attributesAtIndex:0 effectiveRange:NULL][NSUnderlineStyleAttributeName]) {
        CGPathAddRect(path, NULL, NSMakeRect(0, 0, width, 12.5));
        deltaY = 25;
    }

    if (glyphPath) {
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-boundingBox.origin.x, -boundingBox.origin.y + deltaY);
        transform = CGAffineTransformMake(width / boundingBox.size.width, 0, 0, width / boundingBox.size.height, -boundingBox.origin.x, -boundingBox.origin.y + deltaY);
        CGPathAddPath(path, &transform, glyphPath);
        CGPathRelease(glyphPath);
    }

    bezierPath = [NSBezierPath bezierPathWithCGPath:path];

    CGSize size = bezierPath.bounds.size;
    if (size.width != size.height) {
        CGFloat ratio = size.width / size.height; // height must be > width
        [bezierPath applyTransform:CGAffineTransformMakeScale(ratio, ratio)];
    }

    CFRelease(path);
    CFRelease(line);

    [self.cache setObject:bezierPath forKey:character];

    return bezierPath;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    CGFloat width = self.width;
    CGFloat height = self.height;
    CGFloat length = MIN(width, height);
    CGFloat imageSize = length / 2;
    CGFloat radius = length * .2;
    CGFloat radiusDelta = 1.0 / 16 * length;

    NSBezierPath *path1 = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:radius yRadius:radius];
    [[self.strokeColor colorWithAlphaComponent:.75] setFill];
    [path1 fill];

    NSBezierPath *path2 = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, radiusDelta, radiusDelta) xRadius:radius - radiusDelta yRadius:radius - radiusDelta];
//    [[self.color blendedColorWithFraction:.3 ofColor:NSColor.whiteColor] setFill];
    [self.color setFill];
    [path2 fill];

    NSBezierPath *path3 = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, radiusDelta * 2, radiusDelta * 2) xRadius:radius - radiusDelta * 2 yRadius:radius - radiusDelta * 2];
    [[self.color blendedColorWithFraction:.3 ofColor:NSColor.whiteColor] setFill];
//    [self.color setFill];
    [path3 fill];

    NSBezierPath *path4 = [self pathForCharacter:self.character].copy;
    NSSize pathSize = path4.bounds.size;
    CGFloat s = imageSize/pathSize.height;
    CGFloat tx = (width - pathSize.width * s) / 2;
    CGFloat ty = (height - imageSize) / 2;
    [path4 applyTransform:CGAffineTransformMake(s, 0, 0, s, tx, ty)];
    [self.textColor setFill];
    [path4 fill];
}

@end
