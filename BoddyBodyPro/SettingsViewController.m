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

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *languageLabel;

@end

@implementation SettingsViewController

- (IBAction)languageSelected:(UIStoryboardSegue *)sender {
}

- (void)updateView {
    NSNumber *languageId = [[NSUserDefaults standardUserDefaults] valueForKey:@"language"];
    if (languageId == nil) {
        languageId = @(2);
    }
    
    NSManagedObject *language = [ModelController objectWithId:languageId
                                                forEntityName:@"Language"
                                                withinContext:[[ModelController sharedInstance] mainObjectContext]];
    
    if (language != nil) {
        self.languageLabel.text = [language valueForKey:@"full_name"];
    }
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

@end
