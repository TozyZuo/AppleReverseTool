//
//  RTLabel.h
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

#import <CoreText/CoreText.h>

typedef enum
{
	RTTextAlignmentRight = kCTTextAlignmentRight,
	RTTextAlignmentLeft = kCTTextAlignmentLeft,
	RTTextAlignmentCenter = kCTTextAlignmentCenter,
	RTTextAlignmentJustify = kCTTextAlignmentJustified
} RTTextAlignment;

typedef enum
{
	RTTextLineBreakModeWordWrapping = kCTLineBreakByWordWrapping,
	RTTextLineBreakModeCharWrapping = kCTLineBreakByCharWrapping,
	RTTextLineBreakModeClip = kCTLineBreakByClipping,
}RTTextLineBreakMode;

@class RTLabel;
@protocol RTLabelDelegate <NSObject>
@optional
- (void)label:(RTLabel *)label didSelectLinkWithURL:(NSURL *)url rightMouse:(BOOL)rightMouse;
- (void)label:(RTLabel *)label didSelectLink:(NSString *)link rightMouse:(BOOL)rightMouse;
@end

@interface RTLabelComponent : NSObject
@property (nonatomic, assign) NSInteger componentIndex;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *tagLabel;
@property (nonatomic) NSMutableDictionary *attributes;
@property (nonatomic, assign) NSInteger position;

- (id)initWithString:(NSString*)aText tag:(NSString*)aTagLabel attributes:(NSMutableDictionary*)theAttributes;
+ (id)componentWithString:(NSString*)aText tag:(NSString*)aTagLabel attributes:(NSMutableDictionary*)theAttributes;
- (id)initWithTag:(NSString*)aTagLabel position:(NSInteger)_position attributes:(NSMutableDictionary*)_attributes;
+ (id)componentWithTag:(NSString*)aTagLabel position:(NSInteger)aPosition attributes:(NSMutableDictionary*)theAttributes;

@end

@interface RTLabelExtractedComponent : NSObject
@property (nonatomic, strong) NSMutableArray *textComponents;
@property (nonatomic, copy) NSString *plainText;
+ (RTLabelExtractedComponent*)rtLabelExtractComponentsWithTextComponent:(NSMutableArray*)textComponents plainText:(NSString*)plainText;
@end

IB_DESIGNABLE
@interface RTLabel : NSView
@property (nonatomic,  copy ) IBInspectable NSString *text, *plainText, *highlightedText;
@property (nonatomic, strong) IBInspectable NSColor *textColor;
@property (nonatomic, strong) IBInspectable NSFont *font;
@property (nonatomic, strong) NSDictionary *linkAttributes;
@property (nonatomic, strong) NSDictionary *selectedLinkAttributes;
@property (nonatomic,  weak ) id<RTLabelDelegate> delegate;
@property (nonatomic,  copy ) IBInspectable NSString *paragraphReplacement;
@property (nonatomic, strong) NSMutableArray *textComponents, *highlightedTextComponents;
@property (nonatomic, assign) RTTextAlignment textAlignment;
@property (nonatomic, assign) IBInspectable CGSize optimumSize;
@property (nonatomic, assign) RTTextLineBreakMode lineBreakMode;
@property (nonatomic, assign) IBInspectable CGFloat lineSpacing;
@property (nonatomic, assign) NSInteger currentSelectedButtonComponentIndex;
@property (nonatomic, assign) NSInteger currentMouseInsideButtonComponentIndex;
@property (nonatomic, assign) CFRange visibleRange;
@property (nonatomic, assign) BOOL highlighted;

// set text
- (void)setText:(NSString*)text;
+ (RTLabelExtractedComponent*)extractTextStyleFromText:(NSString*)data paragraphReplacement:(NSString*)paragraphReplacement;
// get the visible text
- (NSString*)visibleText;

// alternative
// from susieyy http://github.com/susieyy
// The purpose of this code is to cache pre-create the textComponents, is to improve the performance when drawing the text.
// This improvement is effective if the text is long.
- (void)setText:(NSString *)text extractedTextComponent:(RTLabelExtractedComponent*)extractedComponent;
- (void)setHighlightedText:(NSString *)text extractedTextComponent:(RTLabelExtractedComponent*)extractedComponent;
- (void)setText:(NSString *)text extractedTextStyle:(NSDictionary*)extractTextStyle __attribute__((deprecated));
+ (NSDictionary*)preExtractTextStyle:(NSString*)data __attribute__((deprecated));



@end