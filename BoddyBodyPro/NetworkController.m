//
//  NetworkController.m
//  BoddyBodyPro
//
//  Created by Manuel Broncano Rodriguez on 7/15/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

#import "NetworkController.h"
#import "ModelController.h"

@interface NetworkController() {
    NSURLSession *session;
    ModelController *model;
}

@end

@implementation NetworkController

+ (NetworkController *)sharedInstance {
    static NetworkController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NetworkController alloc] init];
    });
    
    return instance;
}

- (id)init {
    if (self = [super init]) {
        session = [NSURLSession sharedSession];
        model = [ModelController sharedInstance];
    }
    
    return self;
}

- (void)issueRequest:(NSURLRequest *)request update:(updateBlock)update completion:(completionBlock)completion {
    [[session dataTaskWithRequest:request
               completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    if (error != nil) {
                        NSLog(@"error! %@", error);
                        return;
                    }
                   
                    if (response != nil) {
                        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                        if (statusCode != 200) {
                            NSLog(@"response status code: %ld", (long)statusCode);
                            return;
                        }
                    }
                   
                    // TODO: check response is 200
                    if (data != nil) {
                        NSError *jsonError = nil;
                        NSJSONSerialization *jsonObject =
                        [NSJSONSerialization JSONObjectWithData:data
                                                        options:NSJSONReadingAllowFragments
                                                          error:&jsonError];
                        
                        NSLog(@"object: %@", jsonObject);
                        
                        // TODO: check the document actually contains results
                        NSArray *results = [jsonObject mutableArrayValueForKey:@"results"];
                        for (NSDictionary *result in results) {
                            update(result);
                        }

                        // save the results for this request
                        [model synchronize];
                        
                        // check for more pages
                        id next = [jsonObject valueForKey:@"next"];
                        if (next != [NSNull null]) {
                            NSURL *url = [NSURL URLWithString:next];
                            NSURLRequest *request = [NSURLRequest requestWithURL:url];
                            [self issueRequest:request update:update completion:completion];
                        } else {
                            completion();
                        }                        
                    }
                   
               }] resume];
}

- (NSURL *)baseURL {
    return [NSURL URLWithString:@"https://wger.de/api/v2/"];
}

- (NSURLQueryItem *)languageQueryItem {
    NSString *language = [NSString stringWithFormat:@"%@", [ModelController sharedInstance].languageId];
    return [NSURLQueryItem queryItemWithName:@"language" value:language];
}

- (void)getEntityNamed:(NSString *)entityName queryItemArray:(NSArray *)queryItemArray withUpdateBlock:(updateBlock)update withCompletionBlock:(completionBlock)completion {
    NSString *endpoint = [NSString stringWithFormat:@"%@/", entityName.lowercaseString];
    NSURL *url = [self.baseURL URLByAppendingPathComponent:endpoint];

    // add query items
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSMutableArray *queryItems = [components.queryItems? components.queryItems : @[] mutableCopy];
    [queryItems addObjectsFromArray:queryItemArray];
    components.queryItems = queryItems;
    url = components.URL;

    NSURLRequest *request = [NSURLRequest requestWithURL: url];
    NSLog(@"request: %@", request);
    
    [self issueRequest:request update:update completion:completion];
}

- (void)retrieveExercises {
    NSString *entityName = @"Exercise";
    [self getEntityNamed:entityName
          queryItemArray:@[[self languageQueryItem]]
               withUpdateBlock:^(NSDictionary *result) {
        NSManagedObjectContext *context = [[ModelController sharedInstance] privateObjectContext];
        NSManagedObject *exercise = [ModelController objectWithId:result[@"id"] forEntityName:entityName withinContext:context];
        [exercise setValue:result[@"name"] forKey:@"name"];
        [exercise setValue:result[@"description"] forKey:@"desc"];
        [exercise setValue:result[@"language"] forKey:@"language"];
    } withCompletionBlock:^{}];
}

- (void)retrieveMuscles {
    NSString *entityName = @"Muscle";
    [self getEntityNamed:entityName
          queryItemArray:@[[self languageQueryItem]]
               withUpdateBlock:^(NSDictionary *result) {
        NSManagedObjectContext *context = [[ModelController sharedInstance] privateObjectContext];
        NSManagedObject *muscle = [ModelController objectWithId:result[@"id"] forEntityName:entityName withinContext:context];
        [muscle setValue:result[@"name"] forKey:@"name"];
    } withCompletionBlock:^{}];
}

- (void)retrieveLanguagesWithCompletion:(completionBlock)block {
    NSString *entityName = @"Language";
    [self getEntityNamed:entityName
          queryItemArray:@[]
               withUpdateBlock:^(NSDictionary *result) {
        NSManagedObjectContext *context = [[ModelController sharedInstance] privateObjectContext];
        NSManagedObject *object = [ModelController objectWithId:result[@"id"] forEntityName:entityName withinContext:context];
        [object setValue:result[@"short_name"] forKey:@"short_name"];
        [object setValue:result[@"full_name"] forKey:@"full_name"];
    } withCompletionBlock:block];
}

// NOTE: the completion block is invocated for every resource loaded
- (void)retrieveMuscleImagesWithCompletion:(completionBlock)block {
    NSArray *resources = @[@"/static/images/muscles/muscular_system_front.svg",
                           @"/static/images/muscles/muscular_system_back.svg"];

    for (NSString *imagePath in resources) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imagePath relativeToURL:self.baseURL]];
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                        if (error != nil) {
                            NSLog(@"error! %@", error);
                            return;
                        }
                        
                        if (response != nil) {
                            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                            if (statusCode != 200) {
                                NSLog(@"response status code: %ld", (long)statusCode);
                                return;
                            }
                        }
                        
                        if (data != nil) {
                            NSManagedObjectContext *context = [[ModelController sharedInstance] privateObjectContext];
                            NSString *fileName = request.URL.lastPathComponent;
                            NSArray *images = [ModelController objectWithValue:fileName forAttribute:@"name" forEntityName:@"Image" withinContext:context];
                            if (images.count != 1) {
                                NSLog(@"image cache inconsistency");
                                abort();
                            }
                            
                            NSManagedObject *image = images[0];
                            [image setValue:data forKey:@"data"];
                            
                            [[ModelController sharedInstance] synchronize];
                        }
                        
                        block();
                    }] resume];
    }
}

@end
