//
//  ModelController.m
//  BoddyBodyPro
//
//  Created by Manuel Broncano Rodriguez on 7/15/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

#import "ModelController.h"

@implementation ModelController

- (void)setLanguageId:(NSNumber *)languageId {
    [[NSUserDefaults standardUserDefaults] setValue:languageId forKey:@"languageId"];
}

- (NSNumber *)languageId {
    NSNumber *languageId = [[NSUserDefaults standardUserDefaults] valueForKey:@"languageId"];
    if (languageId == nil) {
        languageId = @(2);
    }
    return languageId;
}

+ (ModelController *)sharedInstance {
    static ModelController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ModelController alloc] init];
    });
    
    return instance;
}

- (NSManagedObjectContext *)mainObjectContext {
    static NSManagedObjectContext *context = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
        context.persistentStoreCoordinator = self.storeCoordinator;
    });

    return context;
}

- (NSManagedObjectContext *)privateObjectContext {
    static NSManagedObjectContext *context = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
        context.parentContext = self.mainObjectContext;
    });

    return context;
}

- (NSManagedObjectModel *)objectModel {
    static NSManagedObjectModel *model = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        model = [NSManagedObjectModel mergedModelFromBundles: @[[NSBundle mainBundle]]];
        
        if (model == nil) {
            NSLog(@"error opening the model");
        
            abort();
        }
        
        // TODO: check for errors
    });
    
    return model;
}

- (NSPersistentStoreCoordinator *)storeCoordinator {
    static NSPersistentStoreCoordinator *store = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: self.objectModel];
        
        NSError *error = nil;
        NSURL *storeURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        [store addPersistentStoreWithType:NSSQLiteStoreType
                            configuration:nil
                                      URL:[storeURL URLByAppendingPathComponent:@"BuddyBodyPro.sqlite"]
                                  options:nil
                                    error:&error];
        
        if (error != nil) {
            NSLog(@"error opening the db: %@", error);
            
            abort();
        }
    });
    
    return store;
}

+ (NSManagedObject *)objectWithId:(NSNumber *)objectId forEntityName:(NSString *)entityName withinContext:(NSManagedObjectContext *)context{
    NSError *error = nil;

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"id == %@", objectId];
    
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    // TODO: check for errors
    if (error == nil) {
        // TODO: check for multiple results
        if (results.count == 0) {
            NSManagedObject *exercise = [NSEntityDescription
                                         insertNewObjectForEntityForName:entityName
                                         inManagedObjectContext:context];
            
            [exercise setValue:objectId forKey:@"id"];
            results = @[exercise];
        }
        
        return results[0];
    }
    
    return nil;
}

- (NSPredicate *)allExercisesPredicateWithSearchFilter:(NSString *)searchFilter {
    NSMutableArray *predicateArray = [@[] mutableCopy];

    [predicateArray addObject: [NSPredicate predicateWithFormat:@"language == %@", self.languageId]];
    if (![searchFilter isEqualToString:@""]) {
        [predicateArray addObject: [NSPredicate predicateWithFormat:@"name contains %@", searchFilter]];
    }

    return [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType
                                       subpredicates:predicateArray];
}


- (NSFetchRequest *)allExercisesRequest {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Exercise"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                              ascending:YES
                                                               selector:@selector(localizedCaseInsensitiveCompare:)]];
    return request;
}

+ (NSFetchRequest *)requestForEntityName:(NSString *)entityName {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES]];
    return request;
}

- (BOOL)synchronize {
    NSError *error = nil;

    // TODO: process error
    [self.privateObjectContext save:&error];
    if (error != nil) {
        NSLog(@"error saving private context: %@", error);
    }
    
    // TODO: process error
    [self.mainObjectContext save:&error];
    if (error != nil) {
        NSLog(@"error saving main context: %@", error);
    }
    
    return (error != nil);
}

@end
