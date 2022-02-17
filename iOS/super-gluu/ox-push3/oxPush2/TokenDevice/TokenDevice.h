//
//  TokenDevice.h
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/16/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TokenDevice : NSObject

@property (strong, nonatomic) NSString* deviceUUID;
@property (nonatomic) BOOL deviceTokenRefreshed;

+ (instancetype) sharedInstance;

-(NSData*)getTokenDeviceJSON;
-(void)saveDevicePushToken:(NSString*)pushToken;
-(NSString*)getPushToken;
-(BOOL)isTokenDeviceRefreshed;

@end
