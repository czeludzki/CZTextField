//
//  CZTextField.m
//  CZTextField
//
//  Created by siu on 25/10/17.
//

#import "CZTextField.h"
#import "Masonry.h"

#define kBottomMargin 4

@interface CZTextField ()
@property (nonatomic, weak, readonly) UILabel *placeHolderLabel;
// 输入内容往下偏移量
@property (nonatomic, assign) CGFloat textContentOffset;
@property (nonatomic, assign) BOOL isZoomingOut;
@end

@implementation CZTextField

#pragma mark - Getter && Setter
- (void)setTextContentOffset:(CGFloat)textContentOffset
{
    if (textContentOffset < 20) {
        _textContentOffset = 20;
    }else{
        _textContentOffset = textContentOffset;
    }
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
    }
    return self;
}

- (void)initSetup
{
    _placeholderScalingFactor = .7f;
    // 计算 往下偏移的量
    self.textContentOffset = self.font.lineHeight * self.placeholderScalingFactor;
    // placeHolderLabel
    UILabel *placeHolderLabel = [[UILabel alloc] init];
    placeHolderLabel.backgroundColor = [UIColor clearColor];
    placeHolderLabel.font = self.font;
    placeHolderLabel.textColor = [UIColor lightGrayColor];
    [self addSubview:placeHolderLabel];
    _placeHolderLabel = placeHolderLabel;
    [placeHolderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(8);
        make.centerY.mas_equalTo(self.textContentOffset * .5f - kBottomMargin);
    }];
    
    [self addTarget:self action:@selector(cz_textFieldBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
    [self addTarget:self action:@selector(cz_textFieldEditingChange:) forControlEvents:UIControlEventEditingChanged];
    [self addTarget:self action:@selector(cz_textFieldEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
    [self addTarget:self action:@selector(cz_textFieldEndEditing:) forControlEvents:UIControlEventEditingDidEndOnExit];
}

#pragma mark - Override
- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.text.length > 0) {
        [self zoomOutPlaceholderLabel:YES animate:NO];
    }else{
        [self zoomOutPlaceholderLabel:NO animate:NO];
    }
}

- (void)setText:(NSString *)text
{
    [super setText:text];
}

- (void)setPlaceholder:(NSString *)placeholder
{
    self.placeHolderLabel.text = placeholder;
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    self.placeHolderLabel.font = font;
    self.textContentOffset = self.font.capHeight * self.placeholderScalingFactor;
    [self.placeHolderLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(8);
        make.centerY.mas_equalTo(self.textContentOffset * .5f - kBottomMargin);
    }];
}

- (CGSize)intrinsicContentSize
{
    CGSize superSize = [super intrinsicContentSize];
    return CGSizeMake(superSize.width,
                      superSize.height + self.textContentOffset);
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    CGRect superTextRect = [super textRectForBounds:bounds];
    CGFloat y = self.frame.size.height - 4 > superTextRect.origin.y + superTextRect.size.height ? superTextRect.origin.y + self.textContentOffset * .5f - kBottomMargin : superTextRect.origin.y + self.textContentOffset * .5f;
    return CGRectMake(superTextRect.origin.x, y, superTextRect.size.width, superTextRect.size.height);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    CGRect superTextRect = [super editingRectForBounds:bounds];
    CGFloat y = self.frame.size.height - 4 > superTextRect.origin.y + superTextRect.size.height ? superTextRect.origin.y + self.textContentOffset * .5f - kBottomMargin : superTextRect.origin.y + self.textContentOffset * .5f;
    return CGRectMake(superTextRect.origin.x,
                      y,
                      superTextRect.size.width,
                      superTextRect.size.height);
}

- (CGRect)clearButtonRectForBounds:(CGRect)bounds
{
    CGRect superClearBottonRect = [super clearButtonRectForBounds:bounds];
    CGFloat y = self.frame.size.height - 4 > superClearBottonRect.origin.y + superClearBottonRect.size.height ? superClearBottonRect.origin.y + self.textContentOffset * .5f - kBottomMargin : superClearBottonRect.origin.y + self.textContentOffset * .5f;
    return CGRectMake(superClearBottonRect.origin.x,
                      y,
                      superClearBottonRect.size.width,
                      superClearBottonRect.size.height);
}

#pragma mark - Action
- (void)cz_textFieldBeginEditing:(CZTextField *)sender
{
    if (self.text.length == 0) {
        [self zoomOutPlaceholderLabel:YES animate:YES];
    }
}

- (void)cz_textFieldEditingChange:(CZTextField *)sender
{
    
}

- (void)cz_textFieldEndEditing:(CZTextField *)sender
{
    if (self.text.length == 0) {
        [self zoomOutPlaceholderLabel:NO animate:YES];
    }else{
        [self zoomOutPlaceholderLabel:YES animate:YES];
    }
}

#pragma mark - Helper
- (void)zoomOutPlaceholderLabel:(BOOL)zoomOut animate:(BOOL)animate
{
    if (zoomOut == self.isZoomingOut) return;
    if (zoomOut) {      // 缩小
        self.isZoomingOut = YES;
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(self.placeholderScalingFactor, self.placeholderScalingFactor);
        CGFloat translationX = -(self.placeHolderLabel.frame.size.width * .5f - self.placeHolderLabel.frame.size.width * .5f * self.placeholderScalingFactor);
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
        self.isZoomingOut = NO;
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
