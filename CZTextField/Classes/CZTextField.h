//
//  CZTextField.h
//  CZTextField
//
//  Created by siu on 25/10/17.
//

#import <UIKit/UIKit.h>

/**
 1.请务必搭配 autolayout 使用, 直接的 frame 赋值, 会异常
 2.请尽量不要为 CZTextFiled 指定高度,否则可能会出现界面异常的情况, 根据设置的字体, CZTextField 会自动为高度赋值
 */
@interface CZTextField : UITextField
// Placeholder 缩小系数 默认为 .7f
@property (nonatomic, assign) CGFloat placeholderScalingFactor;
@property (nonatomic) UIColor *placeHolderTextColor;
@end
