//
//  TokenDevice.m
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/16/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TokenDevice.h"
#import "Constants.h"

@implementation TokenDevice

+ (instancetype) sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(void)saveDevicePushToken:(NSString*)pushToken{
    [[NSUserDefaults standardUserDefaults] setValue:pushToken forKey:@"DEVICE_PUSH_TOKEN"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"Saved Push Token");
}

-(NSString*)getPushToken{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"DEVICE_PUSH_TOKEN"];
}

-(NSData*)getTokenDeviceJSON{
    _deviceUUID = [self generateDeviceUUID];
    NSMutableDictionary* tokenDeviceDic = [[NSMutableDictionary alloc] init];
    [tokenDeviceDic setObject:_deviceUUID forKey:@"uuid"];
    [tokenDeviceDic setObject:[self getPushToken] forKey:@"push_token"];
    [tokenDeviceDic setObject:DEVICE_TYPE forKey:@"type"];
    [tokenDeviceDic setObject:OS_NAME forKey:@"platform"];
    [tokenDeviceDic setObject:[[UIDevice currentDevice] name] forKey:@"name"];
    [tokenDeviceDic setObject:[[UIDevice currentDevice] systemName] forKey:@"os_name"];
    [tokenDeviceDic setObject:[[UIDevice currentDevice] systemVersion] forKey:@"os_version"];

    NSError * err;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:tokenDeviceDic options:0 error:&err];
    
    return jsonData;
}

-(BOOL)isTokenDeviceRefreshed{
    return _deviceTokenRefreshed;
}

- (NSString*)generateDeviceUUID{
    if (!_deviceUUID){
        NSString* UUID = [[NSUUID UUID] UUIDString];
        _deviceUUID = UUID;
        return UUID;
    }
    return _deviceUUID;
}

@end
