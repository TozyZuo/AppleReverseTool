//
//  ARTRichTextController.h
//  TextViewDemo
//
//  Created by TozyZuo on 2018/10/15.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTRichTextController;
@protocol ARTRichTextControllerDelegate <NSObject>
@optional
- (void)richTextController:(ARTRichTextController *)richTextController didSelectLink:(NSString *)link rightMouse:(BOOL)rightMouse;
@end


@protocol ARTRichTextViewProtocol <NSObject>
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


@interface ARTRichTextController : NSObject
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSAttributedString *attributedText;
@property (nonatomic, readonly) CGSize optimumSize;
@property (nonatomic,  weak ) NSView<ARTRichTextViewProtocol> *view;
@property (nonatomic,  weak ) id<ARTRichTextControllerDelegate> delegate;

@property (nonatomic, strong) NSString *filterConditionText;

- (instancetype)initWithView:(NSView<ARTRichTextViewProtocol> * _Nullable)view NS_DESIGNATED_INITIALIZER;

// return value < 0 is invalid
+ (CGFloat)priorityForFilterCondition:(NSString *)conditionText string:(NSString *)string;
+ (nullable NSIndexSet *)fuzzySearchWithString:(NSString *)string conditionText:(NSString *)conditionText;

@end

// TODO
//@interface NSTextField (ARTRichTextController)
///<ARTRichTextViewProtocol>
//@end

@interface NSTextView (ARTRichTextController)
<ARTRichTextViewProtocol>
@end

NS_ASSUME_NONNULL_END
