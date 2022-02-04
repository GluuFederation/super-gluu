//
//  UserLoginInfo.h
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/16/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LogState) {
    LOGIN_SUCCESS = 0,
    LOGIN_FAILED,
    LOGIN_DECLINED,
    ENROLL_SUCCESS,
    ENROLL_FAILED,
    ENROLL_DECLINED,
    UNKNOWN_ERROR
};

@interface UserLoginInfo : NSObject

@property NSString* userName;
@property NSString* created;
@property NSString* application;
@property NSString* issuer;
@property NSString* authenticationType;
@property NSString* authenticationMode;
@property NSString* locationIP;
@property NSString* locationCity;
@property LogState logState;
@property NSString* errorMessage;
    
+ (instancetype) sharedInstance;
    
- (NSString *)displayNameForWonderfulType:(LogState)logState;

@end
