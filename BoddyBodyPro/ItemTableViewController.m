//
//  ItemTableViewController.m
//  BoddyBodyPro
//
//  Created by Manuel Broncano Rodriguez on 7/16/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

#import "ItemTableViewController.h"

@interface ItemTableViewController ()

@end

@implementation ItemTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSUInteger index = [self.items indexOfObject:self.selectedItem];
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
    [self tableView:self.tableView willSelectRowAtIndexPath:path];
    [self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionTop];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *index = tableView.indexPathForSelectedRow;
    [tableView cellForRowAtIndexPath:index].accessoryType = UITableViewCellAccessoryNone;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    
    self.selectedItem = self.items[indexPath.row];
    
    return indexPath;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    self.itemBlock(cell, self.items[indexPath.row]);
    
    return cell;
}

@end
