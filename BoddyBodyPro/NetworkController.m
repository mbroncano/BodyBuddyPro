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

- (void)issueRequest: (NSURLRequest *)request withUpdateBlock:(void (^)(NSDictionary *result))block {
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
                            block(result);
                        }
                        
                        // check for more pages
                        id next = [jsonObject valueForKey:@"next"];
                        if (next != [NSNull null]) {
                            NSURL *url = [NSURL URLWithString:next];
                            NSURLRequest *request = [NSURLRequest requestWithURL:url];
                            [self issueRequest:request withUpdateBlock:block];
                        }
                        
                        // save the results for this request
                        [model synchronize];
                    }
                   
               }] resume];
}

- (void)issueRequest: (NSURLRequest *)request update:(void (^)(NSDictionary *result))update completion:(void(^)(void))completion {
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
                        
                        // check for more pages
                        id next = [jsonObject valueForKey:@"next"];
                        if (next != [NSNull null]) {
                            NSURL *url = [NSURL URLWithString:next];
                            NSURLRequest *request = [NSURLRequest requestWithURL:url];
                            [self issueRequest:request update:update completion:completion];
                        } else {
                            completion();
                        }
                        
                        // save the results for this request
                        [model synchronize];
                    }
                   
               }] resume];
}

- (NSURL *)baseURL {
    return [NSURL URLWithString:@"https://wger.de/api/v2/"];
}

- (void)retrieveExercises {
    NSURL *url = [self.baseURL URLByAppendingPathComponent:@"exercise/"];

    // add language query
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSMutableArray *queryItems = [components.queryItems? components.queryItems : @[] mutableCopy];
    NSString *language = [NSString stringWithFormat:@"%@", [ModelController sharedInstance].languageId];
    [queryItems addObject: [NSURLQueryItem queryItemWithName:@"language" value:language]];
    components.queryItems = queryItems;
    url = components.URL;

    NSURLRequest *request = [NSURLRequest requestWithURL: url];
    NSLog(@"request: %@", request);
    
    [self issueRequest:request withUpdateBlock:^(NSDictionary *result) {
        NSManagedObjectContext *context = [[ModelController sharedInstance] privateObjectContext];
        NSManagedObject *exercise = [ModelController objectWithId:result[@"id"] forEntityName:@"Exercise" withinContext:context];
        [exercise setValue:result[@"name"] forKey:@"name"];
        [exercise setValue:result[@"description"] forKey:@"desc"];
        [exercise setValue:result[@"language"] forKey:@"language"];
    }];
}

- (void)retrieveLanguagesWithCompletion:(void (^)(void))block {
    NSURL *url = [self.baseURL URLByAppendingPathComponent:@"language/"];

    // add language query
    NSURLRequest *request = [NSURLRequest requestWithURL: url];
    
    [self issueRequest:request update:^(NSDictionary *result) {
        NSManagedObjectContext *context = [[ModelController sharedInstance] privateObjectContext];
        NSManagedObject *object = [ModelController objectWithId:result[@"id"] forEntityName:@"Language" withinContext:context];
        [object setValue:result[@"short_name"] forKey:@"short_name"];
        [object setValue:result[@"full_name"] forKey:@"full_name"];
    } completion: block];
}

@end
