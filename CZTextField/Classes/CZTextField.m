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
    CZTextFieldOverideMethodType_RightViewRect = 1 << 4,
    CZTextFieldOverideMethodType_PlaceholderRect = 1 << 5
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
        NSString *placeholderContent = self.placeholder;
        self.placeholder = placeholderContent;
        // attributesPlaceholder
        NSAttributedString *attributesPlaceholder = self.attributedPlaceholder;
        self.attributedPlaceholder = attributesPlaceholder;
    }
    return self;
}

- (void)initSetup
{
    _placeholderScalingFactor = .7f;
    _isZoomingOut = NO;
//    self.clipsToBounds = YES;
    // placeHolderLabel
    UILabel *placeHolderLabel = [[UILabel alloc] init];
    placeHolderLabel.backgroundColor = [UIColor colorWithRed:255/255 green:132/255 blue:99/255 alpha:.6f];
    placeHolderLabel.font = self.font;
    [self addSubview:placeHolderLabel];
    _placeHolderLabel = placeHolderLabel;
}

#pragma mark - Override
- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.text.length > 0 || self.isEditing) {
        [self zoomOutPlaceholderLabel:YES animate:YES];
    }else{
        [self zoomOutPlaceholderLabel:NO animate:YES];
    }
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    if (text.length > 0) {
        [self zoomOutPlaceholderLabel:YES animate:NO];
    }else{
        [self zoomOutPlaceholderLabel:NO animate:NO];
    }
}

- (NSString *)placeholder
{
    return [super placeholder];
}

- (void)setPlaceholder:(NSString *)placeholder
{
    self.placeHolderLabel.text = placeholder;
    [super setPlaceholder:placeholder];
}

- (NSAttributedString *)attributedPlaceholder
{
    return [super attributedPlaceholder];
}

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder
{
    self.placeHolderLabel.attributedText = attributedPlaceholder;
    [super setAttributedPlaceholder:attributedPlaceholder];
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
    CGRect calculateRect = [self calculateOffSetRectFromSuper:superTextRect withOverideMethodType:CZTextFieldOverideMethodType_TextRect];
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

- (void)drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:rect];
    CGFloat y = self.textContentOffset + kBottomMargin;
    CGFloat x = (self.borderStyle == UITextBorderStyleNone) ? 8 + rect.origin.x : rect.origin.x;
    self.placeHolderLabel.frame = CGRectMake(x, y, rect.size.width, rect.size.height);
    [self.placeHolderLabel sizeToFit];
    self.placeholderLabelNormalRect = self.placeHolderLabel.frame;
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
//    if (CGRectEqualToRect(self.placeHolderLabel.frame, CGRectZero)) return;
    self.isZoomingOut = zoomOut;
    
    if (zoomOut) {      // 缩小
        if (animate) {
            [UIView animateWithDuration:.3f animations:^{
                self.placeHolderLabel.layer.transform = CATransform3DMakeScale(.7f, .7f, 1);
//                self.placeHolderLabel.frame = CGRectMake(self.placeholderLabelNormalRect.origin.x, 4, self.placeholderLabelNormalRect.size.width, self.placeholderLabelNormalRect.size.height);
            }];
        }else{
            self.placeHolderLabel.layer.transform = CATransform3DMakeScale(.7f, .7f, 1);
//            self.placeHolderLabel.frame = CGRectMake(self.placeholderLabelNormalRect.origin.x, 4, self.placeholderLabelNormalRect.size.width, self.placeholderLabelNormalRect.size.height);
        }
    }else{      // 放大
        if (animate) {
            [UIView animateWithDuration:.3f animations:^{
                self.placeHolderLabel.layer.transform = CATransform3DIdentity;
//                self.placeHolderLabel.frame = self.placeholderLabelNormalRect;
            }];
        }else{
            self.placeHolderLabel.layer.transform = CATransform3DIdentity;
//            self.placeHolderLabel.frame = self.placeholderLabelNormalRect;
        }
    }
}

@end

