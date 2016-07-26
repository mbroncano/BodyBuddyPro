//
//  NetworkController.h
//  BoddyBodyPro
//
//  Created by Manuel Broncano Rodriguez on 7/15/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const muscularSystemFront;
FOUNDATION_EXPORT NSString *const muscularSystemBack;
FOUNDATION_EXPORT NSString *const muscleMainURL;
FOUNDATION_EXPORT NSString *const muscleSecondaryURL;



typedef void(^updateBlock)(NSDictionary *);
typedef void(^completionBlock)();

@interface NetworkController : NSObject

+ (NetworkController *)sharedInstance;

- (void)retrieveExercises;
- (void)retrieveMuscles;
- (void)retrieveLanguagesWithCompletion:(completionBlock)block;
- (void)retrieveMuscleImagesWithCompletion:(completionBlock)block;

@end
