//
//  SettingsViewController.m
//  BoddyBodyPro
//
//  Created by Manuel Broncano Rodriguez on 7/16/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

#import "SettingsViewController.h"
#import "NetworkController.h"
#import "ModelController.h"
#import "ItemTableViewController.h"

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *languageLabel;

@end

@implementation SettingsViewController

- (IBAction)languageSelected:(UIStoryboardSegue *)sender {
    ItemTableViewController *prev = sender.sourceViewController;
    
    NSNumber *languageId = [(NSManagedObject *)prev.selectedItem valueForKey:@"id"];
    [ModelController sharedInstance].languageId = languageId;

    [self updateView];
}

- (NSManagedObject *)currentLanguage {
    NSNumber *languageId = [ModelController sharedInstance].languageId;
    NSManagedObjectContext *context = [[ModelController sharedInstance] mainObjectContext];
    NSManagedObject *language = [ModelController objectWithId:languageId
                                                forEntityName:@"Language"
                                                withinContext:context];
    return language;
}

- (void)updateView {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *fullName = [[self currentLanguage] valueForKey:@"full_name"];
        
        // be sure that we warn the user if the languages are not retrieved yet
        self.tableView.allowsSelection = (fullName != nil);
        if (fullName == nil) {
            fullName = @"(loading ...)";
        }
        
        self.languageLabel.text = fullName;
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NetworkController sharedInstance] retrieveLanguagesWithCompletion:^{
        [self updateView];
    }];

    [self updateView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Detail"]) {
        ItemTableViewController *next = segue.destinationViewController;
        
        NSFetchRequest *request = [ModelController requestForEntityName:@"Language"];
        NSArray *items = [[[ModelController sharedInstance] mainObjectContext] executeFetchRequest:request error:nil];
        
        next.items = items;
        next.selectedItem = [self currentLanguage];
        next.itemBlock = ^(UITableViewCell *cell, id item) {
            NSManagedObject *language = item;
            cell.textLabel.text = [language valueForKey:@"full_name"];
            cell.detailTextLabel.text = [language valueForKey:@"short_name"];
        };
    }
}

@end
