//
//  ARTRichTextCell.m
//  Rcode
//
//  Created by TozyZuo on 2018/11/29.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTRichTextCell.h"
#import "ARTRichTextController.h"

@interface ARTRichTextCell ()
<TZRichTextControllerDelegate>
@property (nonatomic, strong) ARTRichTextController *richTextController;
@end

@implementation ARTRichTextCell

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib
{
    [self initialize];
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
//    self.textView.frame = self.bounds;
    CGRect rect = CGRectZero;
    rect.size = self.richTextController.optimumSize;
    rect.origin.y = (frame.size.height - rect.size.height) * .5;
    self.textView.frame = rect;
}

- (void)initialize
{
    if (!self.textView) {
        NSTextView *textView = [[NSTextView alloc] initWithFrame:self.bounds];
//        textView.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable|
//        NSViewMinXMargin|
//        NSViewMaxXMargin|
//        NSViewMinYMargin|
//        NSViewMaxYMargin;

        textView.selectable = YES;
        textView.editable = NO;
        textView.backgroundColor = NSColor.clearColor;
        textView.textContainer.lineBreakMode = NSLineBreakByClipping;
        [self addSubview:textView];
        self.textView = textView;
    }

    self.richTextController = [[ARTRichTextController alloc] initWithView:self.textView];
    self.richTextController.delegate = self;
}

- (CGSize)optimumSize
{
    return self.richTextController.optimumSize;
}

#pragma mark - TZRichTextControllerDelegate

- (void)richTextController:(ARTRichTextController *)richTextController didSelectLink:(NSString *)link rightMouse:(BOOL)rightMouse
{
    if ([self.delegate respondsToSelector:@selector(richTextCell:didClickLink:rightMouse:)]) {
        [self.delegate richTextCell:self didClickLink:link rightMouse:rightMouse];
    }
}

@end
