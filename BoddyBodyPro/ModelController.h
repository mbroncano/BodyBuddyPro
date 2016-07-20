//
//  ModelController.h
//  BoddyBodyPro
//
//  Created by Manuel Broncano Rodriguez on 7/15/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ModelController : NSObject

@property(assign) NSNumber *languageId;

+ (ModelController *)sharedInstance;
- (NSManagedObjectContext *)mainObjectContext;
- (NSManagedObjectContext *)privateObjectContext;
- (BOOL)synchronize;

+ (NSArray *)objectWithValue:(id)value forAttribute:(NSString *)attribute forEntityName:(NSString *)entityName withinContext:(NSManagedObjectContext *)context;
+ (NSManagedObject *)objectWithId:(NSNumber *)objectId forEntityName:(NSString *)entityName withinContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *)requestForEntityName:(NSString *)entityName;

- (NSFetchRequest *)allExercisesRequest;
- (NSPredicate *)allExercisesPredicateWithSearchFilter:(NSString *)searchFilter;

@end
