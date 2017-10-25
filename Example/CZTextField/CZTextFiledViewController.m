//
//  CZTextFiledViewController.m
//  CZTextField
//
//  Created by czeludzki on 10/25/2017.
//  Copyright (c) 2017 czeludzki. All rights reserved.
//

#import "CZTextFiledViewController.h"
#import <CZTextField/CZTextField.h>

@interface CZTextFiledViewController ()
@property (strong, nonatomic) IBOutlet CZTextField *textField;
@property (weak, nonatomic) IBOutlet UITextField *normalTextField;
@end

@implementation CZTextFiledViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.textField.placeholder = @"请输入密码";
    self.textField.font = [UIFont systemFontOfSize:18];
    self.textField.text = @"哦哦哦哦哦";
    
    [self.textField addTarget:self action:@selector(cz_textFieldBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    NSLog(@"textField.frame.size.height = %.2f",self.textField.frame.size.height);
}

- (void)cz_textFieldBeginEditing:(CZTextField *)sender
{

}

- (IBAction)sliderValueChange:(UISlider *)sender {
    self.normalTextField.font = [UIFont systemFontOfSize:sender.value];
}

@end
