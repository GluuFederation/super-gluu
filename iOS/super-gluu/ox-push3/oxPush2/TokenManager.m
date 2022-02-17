//
//  TokenManager.m
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/3/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import "TokenManager.h"
#import "Constants.h"
#import "Base64.h"
#import "NSString+URLEncode.h"
#import "TokenDevice.h"

// Constants for ClientData.typ
NSString* const REQUEST_TYPE_REGISTER = @"navigator.id.finishEnrollment";
NSString* const REQUEST_TYPE_AUTHENTICATE = @"navigator.id.getAssertion";
//for decline
NSString* const REGISTER_CANCEL_TYPE = @"navigator.id.cancelEnrollment";
NSString* const AUTHENTICATE_CANCEL_TYPE = @"navigator.id.cancelAssertion";

// Constants for building ClientData.challenge
NSString* const JSON_PROPERTY_REGISTER_REQUEST  = @"registerRequests";
NSString* const JSON_PROPERTY_AUTENTICATION_REQUEST  = @"authenticateRequests";
NSString* const JSON_PROPERTY_REQUEST_TYPE  = @"typ";
NSString* const JSON_PROPERTY_SERVER_CHALLENGE = @"challenge";
NSString* const JSON_PROPERTY_SERVER_ORIGIN = @"origin";
NSString* const JSON_PROPERTY_VERSION = @"version";
NSString* const JSON_PROPERTY_APP_ID = @"appId";
NSString* const JSON_PROPERTY_KEY_HANDLE = @"keyHandle";

NSString* const SUPPORTED_U2F_VERSION = @"U2F_V2";

Byte USER_PRESENT_FLAG = 0x01;
Byte USER_PRESENCE_SIGN = 0x03;
Byte CHECK_ONLY = 0x07;

@implementation TokenManager{

    TokenResponseCompletionHandler responseHandler;
}

-(id)init{
    
    codec = [[RawMessageCodec alloc] init];

    return self;
}

-(void)enroll:(NSDictionary*)parameters baseUrl:(NSString*)baseUrl isDecline:(BOOL)isDecline isSecureClick:(BOOL)isSecureClick callBack:(TokenResponseCompletionHandler)handler {
    
    responseHandler = handler;
    
    NSDictionary* registerRequests = [parameters objectForKey:JSON_PROPERTY_REGISTER_REQUEST];
    
    NSString* version = [registerRequests valueForKey:JSON_PROPERTY_VERSION];
    NSString* appParam = [registerRequests valueForKey:JSON_PROPERTY_APP_ID];
    NSString* challenge = [registerRequests valueForKey:JSON_PROPERTY_SERVER_CHALLENGE];
    
    if ([appParam isKindOfClass:[NSArray class]]){
        appParam = [((NSArray*)appParam) objectAtIndex:0];
    }
    if ([version isKindOfClass:[NSArray class]]){
        version = [((NSArray*)version) objectAtIndex:0];
    }
    if ([challenge isKindOfClass:[NSArray class]]){
        challenge = [((NSArray*)challenge) objectAtIndex:0];
    }
    
    if (![version isEqualToString:SUPPORTED_U2F_VERSION]){
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UNSUPPORTED_VERSION object:nil];
    }
    
    //Need create EnrollmentResponse
    //enrollmentResponse should be generated byt SecureClick or our u2f lib
    // TODO: Make possibility to use SecureClick as alternative
    EnrollmentRequest* enrollmentRequest = [[EnrollmentRequest alloc] initWithVersion:version challenge:challenge application:appParam issuer:baseUrl];
    [_u2FKey handleEnrollmentRequest:enrollmentRequest isDecline:isDecline isSecureClick: isSecureClick callback:^(EnrollmentResponse *response, NSError *error){
        TokenResponse* tokenResponse = [self makeTokenResponse:response isDecline:isDecline isSecureClick: isSecureClick challenge:challenge baseUrl:baseUrl];
        handler(tokenResponse, nil);
    }];
    
}

-(void)sign:(NSDictionary*)parameters u2fMetaData:(U2fMetaData*)u2fMetaData isDecline:(BOOL)isDecline isSecureClick:(BOOL)isSecureClick userName:(NSString*)userName callBack:(TokenResponseCompletionHandler)handler{
    NSArray* autenticateRequests = [parameters objectForKey:JSON_PROPERTY_AUTENTICATION_REQUEST];
    NSDictionary* authRequest = [[NSDictionary alloc] init];
    NSString* baseUrl = u2fMetaData.registrationEndpoint;
    responseHandler = handler;

    NSMutableDictionary* clientMutableData = [[NSMutableDictionary alloc] init];
    if (isDecline){
        [clientMutableData setObject:AUTHENTICATE_CANCEL_TYPE forKey:JSON_PROPERTY_REQUEST_TYPE];
    } else {
        [clientMutableData setObject:REQUEST_TYPE_AUTHENTICATE forKey:JSON_PROPERTY_REQUEST_TYPE];
    }

    for (NSDictionary* autenticateRequest in autenticateRequests){
        authRequest = autenticateRequest;
        
        NSString* version = [authRequest valueForKey:JSON_PROPERTY_VERSION];
        NSString* appParam = [authRequest valueForKey:JSON_PROPERTY_APP_ID];
        NSString* challenge = [authRequest valueForKey:JSON_PROPERTY_SERVER_CHALLENGE];
        NSString* keyHandleString = [authRequest valueForKey:JSON_PROPERTY_KEY_HANDLE];
        keyHandleString = [keyHandleString stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
        keyHandleString = [keyHandleString stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
        keyHandleString = [keyHandleString stringByAppendingString:@"="];
        NSData* keyHandle = [keyHandleString base64DecodedData];
        if (![version isEqualToString:SUPPORTED_U2F_VERSION]){
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UNSUPPORTED_VERSION object:nil];
        }

        [clientMutableData setObject:[authRequest valueForKey:JSON_PROPERTY_SERVER_CHALLENGE] forKey:JSON_PROPERTY_SERVER_CHALLENGE];

        [clientMutableData setObject:[authRequest valueForKey:JSON_PROPERTY_APP_ID] forKey:JSON_PROPERTY_SERVER_ORIGIN];
        NSData *clientData = [NSJSONSerialization dataWithJSONObject:clientMutableData options:NSJSONWritingPrettyPrinted error:nil];
        challenge = [[NSString alloc] initWithData:clientData encoding:NSUTF8StringEncoding];

        NSData* controlData = [[NSData alloc] initWithBytes:&USER_PRESENCE_SIGN length:1];
        __block BOOL isSucess = NO;
        
        AuthenticateRequest* authenticateRequest = [[AuthenticateRequest alloc] initWithVersion:version control:controlData challenge:challenge application:appParam keyHandle:keyHandle];

        [_u2FKey handleAuthenticationRequest:authenticateRequest isSecureClick:isSecureClick userName: userName callback: ^(AuthenticateResponse *response, NSError *error){
            if (!error){
                TokenResponse* tokenResponse = [self makeAuthenticationResponse:response authenticatedChallenge:challenge isDecline:isDecline isSecureClick:isSecureClick authRequest:authRequest baseUrl:baseUrl clientData:clientData];
                handler(tokenResponse, nil);
                isSucess = YES;
            } else {
                handler(nil, error);
                isSucess = NO;
            }
        }];
        if (isSucess){break;}
    }
    
}

-(TokenResponse*)makeTokenResponse:(EnrollmentResponse*)enrollmentResponse isDecline:(BOOL)isDecline isSecureClick:(BOOL)isSecureClick challenge:(NSString*) challenge baseUrl:(NSString*)baseUrl{
    NSData* result = isSecureClick ? enrollmentResponse.secureClickEnrollData : [codec encodeRegisterResponse:enrollmentResponse];
    NSString* resultForService = [result base64EncodedString];
    
    NSMutableDictionary* clientData = [[NSMutableDictionary alloc] init];
    if (isDecline){
        [clientData setObject:REGISTER_CANCEL_TYPE forKey:JSON_PROPERTY_REQUEST_TYPE];
    } else {
        [clientData setObject:REQUEST_TYPE_REGISTER forKey:JSON_PROPERTY_REQUEST_TYPE];
    }
    [clientData setObject:challenge forKey:JSON_PROPERTY_SERVER_CHALLENGE];
    [clientData setObject:baseUrl forKey:JSON_PROPERTY_SERVER_ORIGIN];
    
    NSData *clientDataString = [NSJSONSerialization dataWithJSONObject:clientData options:NSJSONWritingPrettyPrinted error:nil];
    
    NSData* tokenDeviceData = [[TokenDevice sharedInstance] getTokenDeviceJSON];
    
    NSMutableDictionary* response = [[NSMutableDictionary alloc] init];
    [response setObject:resultForService forKey:@"registrationData"];
    [response setObject:[clientDataString base64EncodedStringWithOptions:0] forKey:@"clientData"];
    [response setObject:[tokenDeviceData base64EncodedStringWithOptions:0] forKey:@"deviceData"];
    
    NSError * err;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response options:0 error:&err];
    NSString * responseJSONString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    responseJSONString = [responseJSONString URLEncode];
    
    TokenResponse* tokenResponse = [[TokenResponse alloc] init];
    [tokenResponse setResponse:responseJSONString];
    [tokenResponse setChallenge:challenge];
    [tokenResponse setKeyHandle:[[enrollmentResponse keyHandle] base64EncodedString]];
    
    return tokenResponse;
}

-(TokenResponse*)makeAuthenticationResponse:(AuthenticateResponse*) authenticateResponse authenticatedChallenge:(NSString*)authenticatedChallenge isDecline:(BOOL)isDecline isSecureClick:(BOOL)isSecureClick authRequest:(NSDictionary*) authRequest baseUrl:(NSString*)baseUrl clientData:(NSData*)clientData {
    if (authenticateResponse == nil){
        return nil;
    }

    NSString* keyHandle = [authRequest valueForKey:JSON_PROPERTY_KEY_HANDLE];

    // eric, this is where the encoding happens
    NSData* resp = [self->codec encodeAuthenticateResponse:authenticateResponse];
    NSString* clientDataString = [clientData base64EncodedString];

    NSMutableDictionary* responseData = [[NSMutableDictionary alloc] init];
    [responseData setObject:[resp base64EncodedString] forKey:@"signatureData"];
    [responseData setObject:clientDataString forKey:@"clientData"];
    [responseData setObject:keyHandle forKey:@"keyHandle"];

    // Add device info once Push Token re-generates
    BOOL isTokenDeviceRefreshed = [[TokenDevice sharedInstance] isTokenDeviceRefreshed];
    if (isTokenDeviceRefreshed) {
        NSData* tokenDeviceData = [[TokenDevice sharedInstance] getTokenDeviceJSON];
        [responseData setObject:[tokenDeviceData base64EncodedStringWithOptions:0] forKey:@"deviceData"];
    }

    NSError * err;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:responseData options:0 error:&err];
    NSString * responseJSONString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    responseJSONString = [responseJSONString URLEncode];

    TokenResponse* tokenResponse = [[TokenResponse alloc] init];
    [tokenResponse setResponse:responseJSONString];
    [tokenResponse setChallenge:authenticatedChallenge];
    [tokenResponse setKeyHandle:keyHandle];
    
    return tokenResponse;
}

@end
