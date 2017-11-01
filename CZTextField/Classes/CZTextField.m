//
//  CZTextField.m
//  CZTextField
//
//  Created by siu on 25/10/17.
//

#import "CZTextField.h"
#import "Masonry.h"

#define kMargin 4

typedef NS_ENUM(NSUInteger, CZTextFieldOverideMethodType) {
    CZTextFieldOverideMethodType_TextRect = 1,
    CZTextFieldOverideMethodType_EditingRect = 1 << 1,
    CZTextFieldOverideMethodType_ClearButtonRect = 1 << 2,
    CZTextFieldOverideMethodType_LeftViewRect = 1 << 3,
    CZTextFieldOverideMethodType_RightViewRect = 1 << 4,
    CZTextFieldOverideMethodType_PlaceholderRect = 1 << 5
};

typedef NS_ENUM(NSUInteger, CZTextFieldPlaceholderStatus) {
    CZTextFieldPlaceholderStatus_UnKnow = 0,
    CZTextFieldPlaceholderStatus_Normal = 1 << 1,
    CZTextFieldPlaceholderStatus_ZoomOut = 1 << 2
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
@property (nonatomic, assign) CZTextFieldPlaceholderStatus placeholderStatus;
/**
 记录原生的 placeholderLabel
 */
@property (nonatomic, weak) UILabel *OriginalPlaceholderLabel;
/**
 记录 Placeholder 的处于非编辑状态时的 Rect
 */
@property (nonatomic, assign) CGRect placeholderLabelNormalRect;
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

- (UILabel *)OriginalPlaceholderLabel
{
    if (!_OriginalPlaceholderLabel) {
        [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UILabel class]]) {
                _OriginalPlaceholderLabel = obj;
            }
        }];
    }
    return _OriginalPlaceholderLabel;
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
        //  重新设置在 storyboard / xib 中默认的 Placeholder 到 self.placeHolderLabel
        NSAttributedString *attributesPlaceholder = self.attributedPlaceholder;
        self.attributedPlaceholder = attributesPlaceholder;
        
        NSString *placeholderContent = self.placeholder;
        self.placeholder = placeholderContent;
        
        self.placeHolderLabel.textColor = [UIColor lightGrayColor];
    }
    return self;
}

- (void)initSetup
{
    _placeholderScalingFactor = .7f;
    // placeHolderLabel
    UILabel *placeHolderLabel = [[UILabel alloc] init];
    placeHolderLabel.backgroundColor = [UIColor clearColor];
    placeHolderLabel.font = self.font;
    [self addSubview:placeHolderLabel];
    _placeHolderLabel = placeHolderLabel;
}

#pragma mark - Override
- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.text.length > 0 || self.isEditing) {
        [self zoomOutPlaceholderLabel:CZTextFieldPlaceholderStatus_ZoomOut animate:YES];
    }else{
        [self zoomOutPlaceholderLabel:CZTextFieldPlaceholderStatus_Normal animate:YES];
    }
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    if (text.length > 0 || self.isEditing) {
        [self zoomOutPlaceholderLabel:CZTextFieldPlaceholderStatus_ZoomOut animate:YES];
    }else{
        [self zoomOutPlaceholderLabel:CZTextFieldPlaceholderStatus_Normal animate:YES];
    }
}

- (void)setPlaceholder:(NSString *)placeholder
{
    [super setPlaceholder:placeholder];
    self.placeHolderLabel.text = placeholder;
}

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder
{
    [super setAttributedPlaceholder:attributedPlaceholder];
    self.placeHolderLabel.attributedText = attributedPlaceholder;
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    self.placeHolderLabel.font = font;
}

- (CGSize)intrinsicContentSize
{
    CGSize superSize = [super intrinsicContentSize];
    if (self.borderStyle == UITextBorderStyleNone) {
        superSize = CGSizeMake(superSize.width, superSize.height >= 30 ? superSize.height : 30);
    }
    self.textContentOffset = superSize.height * self.placeholderScalingFactor;
    return CGSizeMake(superSize.width, superSize.height + self.textContentOffset);
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    CGRect superTextRect = [super textRectForBounds:bounds];
    CGRect calculateRect = [self calculateOffSetRectFromSuper:superTextRect withOverideMethodType:CZTextFieldOverideMethodType_TextRect];
    
    // 如果 placeholderLabelNormalRect 已有值 || textContentOffset 还没计算完毕, 则不往下计算
    if (self.textContentOffset == 0 || !CGRectEqualToRect(self.placeholderLabelNormalRect, CGRectZero)) return calculateRect;
    // 从此处取得 Placeholder 的 frame, 设置到 PlaceholderLabel
    CGFloat y = calculateRect.origin.y + self.textContentOffset * .5f;
    CGFloat x = calculateRect.origin.x;
    CGSize placeholderSize = [self sizeWithText:self.placeholder font:self.font maxSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    self.placeHolderLabel.frame = CGRectMake(x, y, placeholderSize.width , placeholderSize.height);
    self.placeholderLabelNormalRect = self.placeHolderLabel.frame;
    
    return calculateRect;
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

- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
    CGRect superPlaceholderRect = [super placeholderRectForBounds:bounds];
    return superPlaceholderRect;
}

- (void)drawPlaceholderInRect:(CGRect)rect
{
    [super drawTextInRect:rect];
    self.OriginalPlaceholderLabel.hidden = YES;
}

#pragma mark - Helper
- (CGRect)calculateOffSetRectFromSuper:(CGRect)superRect withOverideMethodType:(CZTextFieldOverideMethodType)methodType
{
    CGFloat y = superRect.origin.y + self.textContentOffset * .5f;
    
    // 判断如果 borderStyle 是 UITextBorderStyleNone, 且 重构位置的方法 是 clearButton 或 rightView, 就使他们右移 8pt
    BOOL judgeMethod = !(methodType & (CZTextFieldOverideMethodType_ClearButtonRect |  CZTextFieldOverideMethodType_RightViewRect));
    BOOL judgeStyle = (self.borderStyle == UITextBorderStyleNone);
    
    CGFloat x = (judgeStyle && judgeMethod) ? superRect.origin.x + 8 : superRect.origin.x;
    CGRect result = CGRectMake(x, y, superRect.size.width, superRect.size.height);
    return result;
}

- (void)zoomOutPlaceholderLabel:(CZTextFieldPlaceholderStatus)placeholderStatus animate:(BOOL)animate
{
    if (CGRectEqualToRect(self.placeHolderLabel.frame, CGRectZero) || self.placeholderStatus == placeholderStatus) return;
    self.placeholderStatus = placeholderStatus;
    
    if (placeholderStatus == CZTextFieldPlaceholderStatus_ZoomOut) {      // 缩小
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(self.placeholderScalingFactor, self.placeholderScalingFactor);
        
        CGFloat translationX = -(self.placeholderLabelNormalRect.size.width * .5f - self.placeholderLabelNormalRect.size.width * .5f * self.placeholderScalingFactor + self.leftView.frame.size.width);
        CGFloat translationY = -(self.placeholderLabelNormalRect.size.height * .5f - self.placeholderLabelNormalRect.size.height * .5f * self.placeholderScalingFactor + self.placeholderLabelNormalRect.origin.y - kMargin);
        CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(translationX, translationY);
        
        if (animate) {
            [UIView animateWithDuration:.3f animations:^{
                self.placeHolderLabel.frame = self.placeholderLabelNormalRect;
                self.placeHolderLabel.transform = CGAffineTransformConcat(scaleTransform, translationTransform);
            }];
        }else{
            self.placeHolderLabel.frame = self.placeholderLabelNormalRect;
            self.placeHolderLabel.transform = CGAffineTransformConcat(scaleTransform, translationTransform);
        }
    }else if (placeholderStatus == CZTextFieldPlaceholderStatus_Normal){      // 还原
        if (animate) {
            [UIView animateWithDuration:.3f animations:^{
                self.placeHolderLabel.transform = CGAffineTransformIdentity;
                self.placeHolderLabel.frame = self.placeholderLabelNormalRect;
            }];
        }else{
            self.placeHolderLabel.transform = CGAffineTransformIdentity;
            self.placeHolderLabel.frame = self.placeholderLabelNormalRect;
        }
    }
}

- (CGSize)sizeWithText:(NSString *)text font:(UIFont *)font maxSize:(CGSize)maxSize
{
    NSDictionary *attrs = @{NSFontAttributeName : font};
    return [text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
}

@end

