//
//  ViewController.m
//  BoddyBodyPro
//
//  Created by Manuel Broncano Rodriguez on 7/15/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

#import "ExerciseTableController.h"
#import "ModelController.h"
#import "NetworkController.h"
#import "ExerciseDetailViewController.h"

@interface ExerciseTableController () <NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate> {
    NSFetchedResultsController *fetchedController;
    NSString *searchString;
}

@property (strong, nonatomic) UISearchController *searchController;

@end

@implementation ExerciseTableController

- (void)refreshData {
    [[NetworkController sharedInstance] retrieveExercises];
    [[NetworkController sharedInstance] retrieveMuscles];

    [self updateFetchRequest];
    [self.tableView reloadData];

    if (self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
}

- (IBAction)settingsUpdated:(UIStoryboardSegue *)sender {
    [self refreshData];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    searchString = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    [self updateFetchRequest];
    [self.tableView reloadData];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return fetchedController.fetchedObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ExerciseCell"];
    NSManagedObject *object = fetchedController.fetchedObjects[indexPath.row];
    
    cell.textLabel.text = [object valueForKey:@"name"];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Detail"]) {
        NSIndexPath *index = self.tableView.indexPathForSelectedRow;
        NSManagedObject *exercise = fetchedController.fetchedObjects[index.row];
        
        ExerciseDetailViewController *next = segue.destinationViewController;
        next.exerciseId = [exercise valueForKey:@"id"];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // search controller setup
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
    
    // try and update the list from the network
    // TODO: track some form of cache to avoid reloading
    [[NetworkController sharedInstance] retrieveExercises];
    [[NetworkController sharedInstance] retrieveMuscles];
    
    // init fetch controller
    searchString = @"";
    fetchedController = [[NSFetchedResultsController alloc]
                         initWithFetchRequest:[[ModelController sharedInstance] allExercisesRequest]
                         managedObjectContext:[[ModelController sharedInstance] mainObjectContext]
                         sectionNameKeyPath:nil
                         cacheName:nil];
                             
    fetchedController.delegate = self;
    [self updateFetchRequest];
}

- (void)updateFetchRequest {
    fetchedController.fetchRequest.predicate = [[ModelController sharedInstance] allExercisesPredicateWithSearchFilter:searchString];

    NSError *error = nil;
    if (![fetchedController performFetch:&error]) {
        NSLog(@"fetch error! %@", error.localizedDescription);
        
        abort();
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
