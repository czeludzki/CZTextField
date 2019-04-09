//
//  TableViewController.m
//  CZTextField_Example
//
//  Created by siu on 27/10/17.
//  Copyright © 2017年 czeludzki. All rights reserved.
//

#import "TableViewController.h"

@interface TableViewController ()
@property (weak, nonatomic) IBOutlet UIButton *tableViewHeaderBtn;

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (IBAction)tableViewHeaderBtnOnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    [self.view endEditing:YES];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma mark - Table view data source && delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat superHeight = [super tableView:tableView heightForRowAtIndexPath:indexPath];
    if (indexPath.row == 0){
        return !self.tableViewHeaderBtn.selected ? .1f : UITableViewAutomaticDimension;
    }else{
        return superHeight;
    }
}

@end
