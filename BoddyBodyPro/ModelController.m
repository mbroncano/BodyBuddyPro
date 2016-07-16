//
//  ModelController.m
//  BoddyBodyPro
//
//  Created by Manuel Broncano Rodriguez on 7/15/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

#import "ModelController.h"

@implementation ModelController

+ (ModelController *)sharedInstance {
    static ModelController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ModelController alloc] init];
        instance.language = 2;
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

+ (NSManagedObject *)exerciseWithId:(nonnull NSNumber *)objectId withContext:(nonnull NSManagedObjectContext *)context{
    NSError *error = nil;

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Exercise"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"id == %@", objectId];
    
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    // TODO: check for errors
    if (error == nil) {
        // TODO: check for multiple results
        if (results.count == 0) {
            NSManagedObject *exercise = [NSEntityDescription
                                         insertNewObjectForEntityForName:@"Exercise"
                                         inManagedObjectContext:context];
            
            [exercise setValue:objectId forKey:@"id"];
            results = @[exercise];
        }
        
        return results[0];
    }
    
    return nil;
}

- (NSPredicate *)allExercisesPredicateWithSearchFilter:(nonnull NSString *)searchFilter {
    NSMutableArray *predicateArray = [@[] mutableCopy];

    [predicateArray addObject: [NSPredicate predicateWithFormat:@"language == %ld", self.language]];
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
