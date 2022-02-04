//
//  DataStoreManager.m
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/3/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import "DataStoreManager.h"
#import <CoreData/CoreData.h>
#import "UserLoginInfo.h"
#import "FDKeychain.h"
#import "KeychainWrapper.h"

#define KEY_ENTITIES @"TokenEntities"
#define USER_INFO_ENTITIES @"LoginInfoEntities"

@implementation DataStoreManager {
	
	NSMutableArray *tokens;
	NSMutableArray *logs;
	NSDateFormatter *dateFormatter;

}

+ (instancetype) sharedInstance {
	static DataStoreManager* instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[DataStoreManager alloc] init];
		instance->tokens = [instance getTokenEntities];
		instance->logs = [instance getUserLoginInfo];
		instance->dateFormatter = [[NSDateFormatter alloc] init];
		[instance->dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss ZZZ"];
	});
	return instance;
}

// public, how clients should get keys
- (NSArray *)keys {
	return tokens;
}

- (void)saveTokenEntity:(TokenEntity*)tokenEntity {
	
	// remove old/defunct tokens
	// removes tokens with matching username & application
	// device and server are not synched, so this can be
	// caused by users removing a device and then
	// adding it back without deleting the local key
	
	do {
		[tokens removeObject: tokenEntity];
	} while ([tokens containsObject:tokenEntity]);
		
	tokenEntity.createdAt = [dateFormatter dateFromString: tokenEntity.pairingTime];
	tokenEntity.isCountUpdated = true;
	
	if (tokens != nil){
		[tokens insertObject:tokenEntity atIndex:0];
	} else {
		tokens = [[NSMutableArray alloc] initWithObjects:tokenEntity, nil];
	}
	
	[self saveTokens];
}

- (int32_t)incrementCountForToken:(TokenEntity*)tokenEntity {
		
	int32_t intCount = [tokenEntity.count intValue];
	
	// this is to handle case of incorrect counter value.
	// Related to issue "Negative 'oxCounter' value upon re-registration #5"
	// https://github.com/GluuFederation/oxAuth/commit/d64425950d953c06fb1a8c89c9d029bcb9a880ea

	if (tokenEntity.isCountUpdated != true && intCount > 0) {
		intCount = 0;
		tokenEntity.count = [NSString stringWithFormat:@"%d", intCount];
		tokenEntity.isCountUpdated = true;
		[self saveTokens];
		return INT_MAX;
	} else {
		intCount += 1;
		tokenEntity.count = [NSString stringWithFormat:@"%d", intCount];
		[self saveTokens];
		return intCount;
	}
}

- (void)orderTokens {
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending: false];
	[tokens sortUsingDescriptors:[NSMutableArray arrayWithObject:sortDescriptor]];
}

- (BOOL)isUniqueTokenName:(NSString *)tokenName {
	
	for (TokenEntity *token in tokens) {
		if ([token.keyName isEqualToString:tokenName] == true) {
			return false;
		} else {
			continue;
		}
	}
	
	return true;
}
	
-(TokenEntity*)getTokenEntityForApplication:(NSString*)app userName:(NSString*)userName {
		
	for (TokenEntity *token in tokens) {
		if ([token.application isEqualToString:app] && [token.userName isEqualToString: userName]) {
			return token;
		}
	}
	
	return nil;
}
	
// private, returns unarchived, date ordered array of tokens or an empty array

-(NSMutableArray *)getTokenEntities{
	
	if (tokens == nil) {
		tokens = [[NSMutableArray alloc] init];
		
		NSArray* tokenArray = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_ENTITIES];
		
		if (tokenArray != nil){
			for (NSData* tokenData in tokenArray){
				TokenEntity* token = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
				token.createdAt = [dateFormatter dateFromString: token.pairingTime];
				[tokens addObject:token];
			}
		}
		
		[self orderTokens];
		[self removeDuplicates];
	}
	
	return tokens;
}

- (void)removeDuplicates {
	
	// versions prior to 34.0.5 did not account for duplicate tokens for the same username & app
	// this happens when a user's device is removed but the local token is not deleted
	// there is no synch call, so we need to handle it manually on the device
	
	[self orderTokens];
	
	// quick check to see if there are duplicates
	NSSet *copySet = [[NSSet alloc] initWithArray:[tokens copy]];
	
	NSLog(@"Token Count: %lu", (unsigned long)tokens.count);
	NSLog(@"Set Count: %lu", copySet.count);
	
	if (tokens.count == copySet.count) {
		return;
	}
	
	NSArray *orderedArray = [tokens copy];
	NSArray *reversedOrderedArray = [[orderedArray reverseObjectEnumerator] allObjects];
	
	for (TokenEntity * orderedToken in orderedArray) {
		for (TokenEntity *reversedToken in reversedOrderedArray) {
			// remove older tokens with matching app & username
			if ([reversedToken isEqual: orderedToken] &&
				[reversedToken.createdAt compare: orderedToken.createdAt] == NSOrderedAscending) {
				NSLog(@"%@", [reversedToken description]);
				[tokens removeObject:reversedToken];
			}
		}
	}
}

- (void)editToken:(TokenEntity *)token name:(NSString *)newName {
	
	if (token != nil) {
		token.keyName = newName;
		[self saveTokens];
	}
}

-(TokenEntity*)getTokenEntityByKeyHandle:(NSString*)keyHandle {

	for (TokenEntity *token in tokens) {
		if ([token.keyHandle isEqualToString:keyHandle]) {
			return token;
		}
	}
	
	return nil;
}

-(BOOL)deleteTokenEntity:(TokenEntity *)token {
	
	[tokens removeObject: token];
	
	[self saveTokens];
	
	return NO;
}

- (void)saveTokens {
	NSMutableArray *archiveArray = [NSMutableArray arrayWithCapacity:tokens.count];
	for (TokenEntity *tokenEntity in tokens) {
		if ([tokenEntity isKindOfClass:[NSData class]]){
			[archiveArray addObject:tokenEntity];
		} else {
			NSData *personEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:tokenEntity];
			[archiveArray addObject:personEncodedObject];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:archiveArray forKey:KEY_ENTITIES];
	[[NSUserDefaults standardUserDefaults] synchronize];
	NSLog(@"Saved updated Token Array");
}

// LOGS

// public, how clients should get logs
- (NSArray *)userLogs {
	return logs;
}

-(void)saveUserLoginInfo:(UserLoginInfo*)userLoginInfo{
	
	[logs addObject: userLoginInfo];
	
	[self saveLogs];
}

-(NSMutableArray*)getUserLoginInfo{
	if (logs == nil) {
		logs = [[NSMutableArray alloc] init];
		NSMutableArray* logsDataArray = [[NSUserDefaults standardUserDefaults] valueForKey:USER_INFO_ENTITIES];
		if (logsDataArray != nil){
			for (NSData* logsData in logsDataArray){
				UserLoginInfo* info = (UserLoginInfo*)[NSKeyedUnarchiver unarchiveObjectWithData:logsData];
				[logs addObject:info];
			}
		}
	}
	
	return logs;
}

-(void)deleteLogs:(NSArray*)logsToDelete{
	
	for (UserLoginInfo* log in logsToDelete){
		[logs removeObject: log];
	}
	
	[self saveLogs];
}

-(void)deleteLog:(UserLoginInfo*) log {

	[logs removeObject: log];
	
	[self saveLogs];
}

-(BOOL)deleteAllLogs {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_INFO_ENTITIES];
	return YES;
}

- (void)saveLogs {
	NSMutableArray *archiveArray = [NSMutableArray arrayWithCapacity: logs.count];
	for (UserLoginInfo *userLoginEntity in logs) {
		NSData *personEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:userLoginEntity];
		[archiveArray addObject:personEncodedObject];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:archiveArray forKey:USER_INFO_ENTITIES];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	NSLog(@"Saved UserLoginInfoEntity to database success");
}

@end
