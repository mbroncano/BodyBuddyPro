//
//  ItemTableViewController.h
//  BoddyBodyPro
//
//  Created by Manuel Broncano Rodriguez on 7/16/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^ItemCellBlock)(UITableViewCell *, id);

@interface ItemTableViewController : UITableViewController

@property(strong, nonatomic) NSArray *items;
@property(strong, nonatomic) id selectedItem;
@property(assign, nonatomic) ItemCellBlock itemBlock;

@end
