//
//  TokenEntity.h
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/3/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TokenEntity : NSObject <NSCoding>

@property (strong, nonatomic) NSString* application;
@property (strong, nonatomic) NSString* issuer;
@property (strong, nonatomic) NSString* privateKey;
@property (strong, nonatomic) NSString* publicKey;
@property (strong, nonatomic) NSString* keyHandle;
@property (strong, nonatomic) NSString* userName;
@property (strong, nonatomic) NSString* pairingTime;
@property (strong, nonatomic) NSString* authenticationMode;
@property (strong, nonatomic) NSString* authenticationType;
@property (strong, nonatomic) NSString* count;
@property (strong, nonatomic) NSString* keyName;
@property (strong, nonatomic) NSDate* createdAt;
@property (nonatomic, assign) BOOL isCountUpdated;


@end
