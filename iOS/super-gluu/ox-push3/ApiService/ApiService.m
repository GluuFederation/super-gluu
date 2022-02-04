//
//  ApiService.m
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/2/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import "ApiService.h"
#import "AFHTTPSessionManager.h"
#import "Constants.h"
#import "LogManager.h"
#import "DataStoreManager.h"

@implementation ApiService

+ (instancetype) sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)doGET:(NSString *)baseUrl parameters:(NSDictionary *)parameters callback:(RequestCompletionHandler)handler{

    [self callGETAPIService:baseUrl andParameters:parameters andCallback:handler];
}

- (void)doPOST:(NSString *)baseUrl parameters:(NSDictionary *)parameters callback:(RequestCompletionHandler)handler{
    
    [self callPOSTAPIService:baseUrl andParameters:parameters andCallback:handler];
}

//---------------------- HTTP REQUEST MANAGER ---------------------------------

-(AFHTTPSessionManager*)getAFHTTPRequestManager{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer
                                  serializerWithReadingOptions:NSJSONReadingAllowFragments];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    
    /**** SSL Pinning ****/
    BOOL isTrustAll = [[NSUserDefaults standardUserDefaults] boolForKey:@"is_ssl_enabled"];
    if (!isTrustAll){
        /**** SSL Pinning ****/
        
        AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        manager.securityPolicy = policy;
        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"www.gluu.org" ofType:@"cer"];
        NSData *certData = [NSData dataWithContentsOfFile:cerPath];
        [manager.securityPolicy setPinnedCertificates:@[certData]];
        manager.securityPolicy.allowInvalidCertificates = YES;
        [manager.securityPolicy setValidatesDomainName:NO];
        
        /**** End SSL Pinning ****/
    }
    
    return manager;
}

-(void)callGETAPIService:(NSString*)url andParameters:(NSDictionary*)parameters andCallback:(RequestCompletionHandler)handler{
    AFHTTPSessionManager *manager = [self getAFHTTPRequestManager];
    
    [manager GET:url parameters:parameters success:^(NSURLSessionDataTask *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        handler(responseObject ,nil);
    } failure:^(NSURLSessionDataTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        handler(nil , error);
    }];
    
}

-(void)callPOSTAPIService:(NSString*)url andParameters:(NSDictionary*)parameters andCallback:(RequestCompletionHandler)handler{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer
                                  serializerWithReadingOptions:NSJSONReadingAllowFragments];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/x-www-form-urlencoded"];
    
    [manager POST:url parameters:parameters success:^(NSURLSessionDataTask *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        handler(responseObject ,nil);
    } failure:^(NSURLSessionDataTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        handler(nil , error);
    }];
    
}

//---------------------- END OF HTTP REQUEST MANAGER ---------------------------------

- (BOOL)isSuccessResponse:(NSHTTPURLResponse*) response {
	if (response != nil && [response statusCode] >=200 && [response statusCode] <300) {
		return true;
	} else {
		return false;
	}
}

-(void)callPOSTMultiPartAPIService:(NSString*)url andParameters:(NSDictionary*)parameters isDecline:(BOOL)isDecline callback:(RequestCompletionHandler)handler {
    
	BOOL isEnroll = [url rangeOfString:@"registration"].location != NSNotFound ? YES : NO;
    // the server url to which the image (or the media) is uploaded. Use your server url here
    NSURL *baseUrl = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:baseUrl];
    [request setHTTPMethod:@"POST"];
    NSString *contentType = @"application/x-www-form-urlencoded";
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"username=%@", @""] dataUsingEncoding:NSUTF8StringEncoding]];
    
	[body appendData:[[NSString stringWithFormat:@"&tokenResponse=%@", [parameters objectForKey:@"tokenResponse"]] dataUsingEncoding:NSUTF8StringEncoding]];
    
	[request setHTTPBody:body];

    NSHTTPURLResponse* response = nil;
    NSError* error;
    
    NSData* urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
	[UserLoginInfo sharedInstance].created = [NSString stringWithFormat:@"%@", [NSDate date]];
    
	if ([self isSuccessResponse:response]) {
        
		NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:urlData options:kNilOptions error:&error];
        
		handler(jsonData, nil);
        
		if([[jsonData objectForKey:@"status"] isEqualToString:@"success"]) {
            if (isDecline){
                if (isEnroll){
                    [UserLoginInfo sharedInstance].logState = ENROLL_DECLINED;
                    [UserLoginInfo sharedInstance].errorMessage = @"Enrol was declined";
                    [[DataStoreManager sharedInstance] saveUserLoginInfo:[UserLoginInfo sharedInstance]];
                } else {
                    [UserLoginInfo sharedInstance].logState = LOGIN_DECLINED;
                    [UserLoginInfo sharedInstance].errorMessage = @"Login was declined";
                    [[DataStoreManager sharedInstance] saveUserLoginInfo:[UserLoginInfo sharedInstance]];
                }
            } else {
                if (isEnroll){
                    [UserLoginInfo sharedInstance].logState = ENROLL_SUCCESS;
                    [[DataStoreManager sharedInstance] saveUserLoginInfo:[UserLoginInfo sharedInstance]];
                } else {
                    [UserLoginInfo sharedInstance].logState = LOGIN_SUCCESS;
                    [[DataStoreManager sharedInstance] saveUserLoginInfo:[UserLoginInfo sharedInstance]];
                }
            }
			
        // Not Success status
			
		} else {
            handler(nil, error);
                if (isEnroll){
                    [UserLoginInfo sharedInstance].logState = ENROLL_FAILED;
                    [[DataStoreManager sharedInstance] saveUserLoginInfo:[UserLoginInfo sharedInstance]];
                } else {
                    [UserLoginInfo sharedInstance].logState = LOGIN_FAILED;
                    [[DataStoreManager sharedInstance] saveUserLoginInfo:[UserLoginInfo sharedInstance]];
                }
        }
	// error or unsuccessful response
    } else {
        handler(nil, error);

        NSString* errrorMessage = (urlData == nil) ? [self handleDefaultURLErrors: error] : [self handleCustomURLErrors: urlData];
        
        if (isDecline) {
			// not handling this currently
        } else {
            if (isEnroll){
                [UserLoginInfo sharedInstance].logState = ENROLL_FAILED;
                [UserLoginInfo sharedInstance].errorMessage = errrorMessage;
                [[DataStoreManager sharedInstance] saveUserLoginInfo:[UserLoginInfo sharedInstance]];
            } else {
                [UserLoginInfo sharedInstance].logState = LOGIN_FAILED;
                [UserLoginInfo sharedInstance].errorMessage = errrorMessage;
                [[DataStoreManager sharedInstance] saveUserLoginInfo:[UserLoginInfo sharedInstance]];
            }
        }
    }
}

-(NSString*)handleDefaultURLErrors:(NSError*) error {
    return [[error userInfo] valueForKey:@"NSLocalizedDescription"];
}

-(NSString*)handleCustomURLErrors:(NSData*) urlData {
    NSString* erStr = [[NSString alloc] initWithData: urlData encoding: NSUTF8StringEncoding];
    NSLog(@"ERROR MESSAGE - %@", erStr);
    NSError* error;
    NSDictionary* jsonError = [NSJSONSerialization JSONObjectWithData: urlData options: kNilOptions error: &error];
    NSString* errrorMessage = @"";
    if (jsonError != nil){
        NSString* reason = [jsonError valueForKey: @"error_description"];
        if (reason != nil){
            errrorMessage = reason;
        } else {
            errrorMessage = erStr;
        }
    } else {
        errrorMessage = erStr;
    }
    
    return errrorMessage;
}

@end
