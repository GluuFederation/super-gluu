//
//  DataStoreManager.h
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/3/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "TokenEntity.h"
#import "UserLoginInfo.h"

@interface DataStoreManager : NSObject

+ (instancetype) sharedInstance;


-(NSArray *)keys;
-(void)saveTokenEntity:(TokenEntity*)tokenEntity;
-(int)incrementCountForToken:(TokenEntity*)tokenEntity;
-(TokenEntity*)getTokenEntityForApplication:(NSString*)app userName:(NSString*)userName;
-(TokenEntity*)getTokenEntityByKeyHandle:(NSString*)keyHandle;
-(BOOL)deleteTokenEntity:(TokenEntity *)token;
-(BOOL)isUniqueTokenName:(NSString *)tokenName;
-(void)editToken:(TokenEntity *)tokenEdited name:(NSString *) newName;

-(NSArray*)userLogs;
-(void)saveUserLoginInfo:(UserLoginInfo*)userLoginInfo;
-(void)deleteLogs:(NSArray*)logs;
-(void)deleteLog:(UserLoginInfo*) log;
-(BOOL)deleteAllLogs;

@end
