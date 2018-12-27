//
//  TZRichTextController.h
//
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class TZRichTextController;
@protocol TZRichTextControllerDelegate <NSObject>
@optional
- (void)richTextController:(TZRichTextController *)richTextController didSelectLink:(NSString *)link rightMouse:(BOOL)rightMouse;
@end


@protocol TZRichTextViewProtocol <NSObject>
@property NSAttributedString *attributedStringValue;
@property (readonly) NSColor *textColor;
@property (readonly) NSTextAlignment alignment;
@property (readonly) NSFont *font;
@property (readonly) NSLineBreakMode lineBreakMode;
@property (getter=isSelectable) BOOL selectable;
@optional
@property (readonly) CGFloat lineSpacing;
@property (readonly) CGFloat extraLineSpacing; // for calculating tracking area
@property (readonly) NSEdgeInsets textInsets;
@end


@interface TZRichTextController : NSObject
@property (nonatomic,  strong ) NSString *text;
@property (nonatomic,  strong ) NSAttributedString *attributedText;
@property (nonatomic, readonly) CGSize optimumSize;
@property (nonatomic,   weak  ) NSView<TZRichTextViewProtocol> *view;
@property (nonatomic,   weak  ) id<TZRichTextControllerDelegate> delegate;
- (instancetype)initWithView:(NSView<TZRichTextViewProtocol> * _Nullable)view NS_DESIGNATED_INITIALIZER;
@end

// TODO
//@interface NSTextField (TZRichTextController)
///<TZRichTextViewProtocol>
//@end

@interface NSTextView (TZRichTextController)
<TZRichTextViewProtocol>
@end

NS_ASSUME_NONNULL_END
