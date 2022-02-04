//
//  TokenManager.h
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/3/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TokenResponse.h"
#import "RawMessageCodec.h"
#import "U2FKeyImpl.h"
#import "U2fMetaData.h"

@interface TokenManager : NSObject{

    RawMessageCodec* codec;
}

typedef void(^TokenResponseCompletionHandler)(TokenResponse* tokenResponce, NSError *error);

@property (strong, nonatomic) U2FKeyImpl* u2FKey;

-(void)enroll:(NSDictionary*)parameters baseUrl:(NSString*)baseUrl isDecline:(BOOL)isDecline isSecureClick:(BOOL)isSecureClick callBack:(TokenResponseCompletionHandler)handler;
-(void)sign:(NSDictionary*)parameters u2fMetaData:(U2fMetaData*)u2fMetaData isDecline:(BOOL)isDecline isSecureClick:(BOOL)isSecureClick userName:(NSString*)userName callBack:(TokenResponseCompletionHandler)handler;

@end
