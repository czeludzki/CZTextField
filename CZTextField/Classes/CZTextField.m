//
//  CZTextField.m
//  CZTextField
//
//  Created by siu on 25/10/17.
//

#import "CZTextField.h"
#import "Masonry.h"

#define kBottomMargin 4

typedef NS_ENUM(NSUInteger, CZTextFieldOverideMethodType) {
    CZTextFieldOverideMethodType_TextRect = 1,
    CZTextFieldOverideMethodType_EditingRect = 1 << 1,
    CZTextFieldOverideMethodType_ClearButtonRect = 1 << 2,
    CZTextFieldOverideMethodType_LeftViewRect = 1 << 3,
    CZTextFieldOverideMethodType_RightViewRect = 1 << 4
};

@interface CZTextField ()
@property (nonatomic, weak, readonly) UILabel *placeHolderLabel;
// 输入内容往下偏移量
@property (nonatomic, assign) CGFloat textContentOffset;
/*
 缩放状态
 YES: 缩小到左上角
 NO : 正常状态
 */
@property (nonatomic, assign) BOOL isZoomingOut;
@end

@implementation CZTextField
@dynamic placeHolderTextColor;

#pragma mark - Getter && Setter
- (void)setPlaceHolderTextColor:(UIColor *)placeHolderTextColor
{
    self.placeHolderLabel.textColor = placeHolderTextColor;
}

- (UIColor *)placeHolderTextColor
{
    return self.placeHolderLabel.textColor;
}

#pragma mark - LifeCycle
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initSetup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self initSetup];
        //  抹掉原有的 Placeholder, 重新设置在 storyboard / xib 中默认的 Placeholder 到 self.placeHolderLabel
        NSString *placeholderContent = self.placeholder;
        [super setPlaceholder:nil];
        self.placeholder = placeholderContent;
        // attributesPlaceholder
        NSAttributedString *attributesPlaceholder = self.attributedPlaceholder;
        [super setAttributedPlaceholder:nil];
        self.attributedPlaceholder = attributesPlaceholder;
    }
    return self;
}

- (void)initSetup
{
    _placeholderScalingFactor = .7f;
    _isZoomingOut = NO;
    // placeHolderLabel
    UILabel *placeHolderLabel = [[UILabel alloc] init];
    placeHolderLabel.backgroundColor = [UIColor clearColor];
    placeHolderLabel.font = self.font;
    placeHolderLabel.textColor = [UIColor lightGrayColor];
    [self addSubview:placeHolderLabel];
    _placeHolderLabel = placeHolderLabel;
}

#pragma mark - Override
- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.placeHolderLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(8 + self.leftView.frame.size.width);
        make.centerY.mas_equalTo(self.textContentOffset * .5f - kBottomMargin);
    }];
    if (self.text.length > 0 || self.isEditing) {
        [self zoomOutPlaceholderLabel:YES animate:YES];
    }else{
        [self zoomOutPlaceholderLabel:NO animate:YES];
    }
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    NSLog(@"self.placeHolderLabel.frame = %@",NSStringFromCGRect(self.placeHolderLabel.frame));
    if (CGRectEqualToRect(CGRectZero, self.placeHolderLabel.frame)) return;
    if (text.length > 0) {
        [self zoomOutPlaceholderLabel:YES animate:NO];
    }else{
        [self zoomOutPlaceholderLabel:NO animate:NO];
    }
}

- (NSString *)placeholder
{
    return self.placeHolderLabel.text;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    self.placeHolderLabel.text = placeholder;
}

- (NSAttributedString *)attributedPlaceholder
{
    return self.placeHolderLabel.attributedText;
}

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder
{
    self.placeHolderLabel.attributedText = attributedPlaceholder;
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    self.placeHolderLabel.font = font;
    self.textContentOffset = self.font.capHeight * self.placeholderScalingFactor;
}

- (CGSize)intrinsicContentSize
{
    CGSize superSize = [super intrinsicContentSize];
    if (self.borderStyle == UITextBorderStyleNone) {
        NSLog(@"superSize = %@",NSStringFromCGSize(superSize));
        superSize = CGSizeMake(superSize.width, superSize.height >= 30 ? superSize.height : 30);
    }
    self.textContentOffset = superSize.height * self.placeholderScalingFactor;
    return CGSizeMake(superSize.width, superSize.height + self.textContentOffset);
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    CGRect superTextRect = [super textRectForBounds:bounds];
    return [self calculateOffSetRectFromSuper:superTextRect withOverideMethodType:CZTextFieldOverideMethodType_TextRect];
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    CGRect superTextRect = [super editingRectForBounds:bounds];
    return [self calculateOffSetRectFromSuper:superTextRect withOverideMethodType:CZTextFieldOverideMethodType_EditingRect];
}

- (CGRect)clearButtonRectForBounds:(CGRect)bounds
{
    CGRect superClearBottonRect = [super clearButtonRectForBounds:bounds];
    return [self calculateOffSetRectFromSuper:superClearBottonRect withOverideMethodType:CZTextFieldOverideMethodType_ClearButtonRect];
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds
{
    CGRect superLeftViewRect = [super leftViewRectForBounds:bounds];
    return [self calculateOffSetRectFromSuper:superLeftViewRect withOverideMethodType:CZTextFieldOverideMethodType_LeftViewRect];
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds
{
    CGRect superRightViewRect = [super rightViewRectForBounds:bounds];
    return [self calculateOffSetRectFromSuper:superRightViewRect withOverideMethodType:CZTextFieldOverideMethodType_RightViewRect];
}

#pragma mark - Helper
- (CGRect)calculateOffSetRectFromSuper:(CGRect)superRect withOverideMethodType:(CZTextFieldOverideMethodType)methodType
{
    CGFloat y = self.frame.size.height - 4 > superRect.origin.y + superRect.size.height ?
    superRect.origin.y + self.textContentOffset * .5f - kBottomMargin :
    superRect.origin.y + self.textContentOffset * .5f;
    
    // 判断如果 borderStyle 是 UITextBorderStyleNone, 且 重构位置的方法 是 clearButton 或 rightView, 就使他们右移 8pt
    BOOL judgeMethod = !(methodType & (CZTextFieldOverideMethodType_ClearButtonRect |  CZTextFieldOverideMethodType_RightViewRect));
    BOOL judgeStyle = (self.borderStyle == UITextBorderStyleNone);
    
    CGFloat x = (judgeStyle && judgeMethod) ? superRect.origin.x + 8 : superRect.origin.x;
    return CGRectMake(x, y, superRect.size.width, superRect.size.height);
}

- (void)zoomOutPlaceholderLabel:(BOOL)zoomOut animate:(BOOL)animate
{
    if (zoomOut == self.isZoomingOut) return;
    self.isZoomingOut = !self.isZoomingOut;
    if (zoomOut) {      // 缩小
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(self.placeholderScalingFactor, self.placeholderScalingFactor);
        CGFloat translationX = -(self.placeHolderLabel.frame.size.width * .5f - self.placeHolderLabel.frame.size.width * .5f * self.placeholderScalingFactor + self.leftView.frame.size.width);
        CGFloat translationY = -(self.placeHolderLabel.frame.size.height * .5f - self.placeHolderLabel.frame.size.height * .5f * self.placeholderScalingFactor + self.placeHolderLabel.frame.origin.y - kBottomMargin);
        CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(translationX, translationY);
        if (animate) {
            [UIView animateWithDuration:.3f animations:^{
                self.placeHolderLabel.transform = CGAffineTransformConcat(scaleTransform, translationTransform);
            }];
        }else{
            self.placeHolderLabel.transform = CGAffineTransformConcat(scaleTransform, translationTransform);
        }
    }else{      // 放大
        if (animate) {
            [UIView animateWithDuration:.3f animations:^{
                self.placeHolderLabel.transform = CGAffineTransformIdentity;
            }];
        }else{
            self.placeHolderLabel.transform = CGAffineTransformIdentity;
        }
    }
}

@end

