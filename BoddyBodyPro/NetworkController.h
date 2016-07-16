//
//  NetworkController.h
//  BoddyBodyPro
//
//  Created by Manuel Broncano Rodriguez on 7/15/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkController : NSObject

+ (NetworkController *)sharedInstance;
- (void)retrieveExercises;

@end
