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
@property (nonatomic, strong) NSCache<NSString *, NSBezierPath *> *cache;
@end

@implementation ARTCategoryView

- (void)initialize
{
    [super initialize];
    self.textColor = NSColor.whiteColor;
    self.font = [NSFont fontWithName:@"PingFangSC-Semibold" size:100];
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

- (void)setCharacter:(NSString *)character
{
    if (character.length > 1) {
        character = [character substringToIndex:1];
    }
    if (![character isEqualToString:_character]) {
        _character = character;
        self.needsDisplay = YES;
    }
}

- (NSBezierPath *)pathForCharacter:(NSString *)character
{
    NSBezierPath *bezierPath = [self.cache objectForKey:character];
    if (bezierPath) {
        return bezierPath;
    }

    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFTypeRef)[[NSAttributedString alloc] initWithString:character attributes:@{NSFontAttributeName: self.font}]);

    CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(CTLineGetGlyphRuns(line), 0);
    CGGlyph glyph;
    CTRunGetGlyphs(run, CFRangeMake(0, 1), &glyph);
    CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);

//    NSBezierPath *bPath = [NSBezierPath bezierPath];
//    [bPath appendBezierPathWithCGGlyph:glyph inFont:self.font];

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathRef glyphPath = CTFontCreatePathForGlyph(runFont, glyph, NULL);
    if (glyphPath) {
        CGRect boundingBox = CGPathGetPathBoundingBox(glyphPath);
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-boundingBox.origin.x, -boundingBox.origin.y);
        CGPathAddPath(path, &transform, glyphPath);
        CGPathRelease(glyphPath);
    }

    bezierPath = [NSBezierPath bezierPathWithCGPath:path];
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

    NSBezierPath *path1 = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:radius yRadius:radius];
    [[NSColor.whiteColor colorWithAlphaComponent:.75] setFill];
    [path1 fill];

    NSBezierPath *path2 = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 1.5, 1.5) xRadius:radius - 1.5 yRadius:radius - 1.5];
//    [[self.color blendedColorWithFraction:.3 ofColor:NSColor.whiteColor] setFill];
    [self.color setFill];
    [path2 fill];

    NSBezierPath *path3 = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 3, 3) xRadius:radius - 3 yRadius:radius - 3];
    [[self.color blendedColorWithFraction:.3 ofColor:NSColor.whiteColor] setFill];
//    [self.color setFill];
    [path3 fill];

    NSBezierPath *path4 = [self pathForCharacter:self.character].copy;
    NSSize pathSize = path4.bounds.size;
    CGFloat sx = imageSize/pathSize.width;
    CGFloat sy = imageSize/pathSize.height;
    CGFloat tx = (width - imageSize) / 2;
    CGFloat ty = (height - imageSize) / 2;
    [path4 applyTransform:CGAffineTransformMake(sx, 0, 0, sy, tx, ty)];
    [self.textColor setFill];
    [path4 fill];
}

@end
