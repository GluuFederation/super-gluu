//
//  U2FKeyImpl.m
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/12/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import "U2FKeyImpl.h"
#import "GMEllipticCurveCrypto.h"
#import "GMEllipticCurveCrypto+hash.h"
#import "TokenEntity.h"
#import <NSHash/NSString+NSHash.h>
#import <NSHash/NSData+NSHash.h>
#import "Base64.h"
#import "Constants.h"
#import "DataStoreManager.h"
#import "NSString+URLEncode.h"
#import "AuthenticateResponse.h"
#import "AuthenticateRequest.h"
#import "UserPresenceVerifier.h"

#define INIT_SECURE_CLICK_NOTIFICATION @"INIT_SECURE_CLICK_NOTIFICATION"

Byte REGISTRATION_RESERVED_BYTE_VALUE = 0x05;
int keyHandleLength = 64;

@implementation U2FKeyImpl {
    SecureClickCompletionHandler secureClickHandler;
    SecureClickAuthCompletionHandler secureClickAuthHandler;
    TokenEntity* secureClickToken;
    GMEllipticCurveCrypto *secureClickCrypto;
    NSData* secureClickUserPublicKey;
    NSMutableData* secureClickKeyHandle;
    
    Boolean isAuthSent;
}

-(id)init{
    codec = [[RawMessageCodec alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(waitForSecureClickNotification:) name:@"didUpdateValueForCharacteristic" object:nil];
    return self;
}

-(void)handleEnrollmentRequest:(EnrollmentRequest*)enrollmentRequest isDecline:(BOOL)isDecline isSecureClick:(BOOL)isSecureClick callback:(SecureClickCompletionHandler)handler {
    
    NSString* application = [enrollmentRequest application];
    NSString* challenge = [enrollmentRequest challenge];
    
    //Generate a new ECC key pair
    GMEllipticCurveCrypto *crypto = [GMEllipticCurveCrypto generateKeyPairForCurve:
                                     GMEllipticCurveSecp256r1];
    
    NSData* userPublicKey = crypto.publicKey;
    NSMutableData* keyHandle = [[NSMutableData alloc] init];
    for (int i = 0; i < keyHandleLength; i ++){
        int randomByte = arc4random() % 256;
        [keyHandle appendBytes:&randomByte length:1];
    }
    if (!isDecline){
        //Save new key into database
        TokenEntity* newTokenEntity = [[TokenEntity alloc] init];
        newTokenEntity.application = application;
        newTokenEntity.issuer = [enrollmentRequest issuer];
        newTokenEntity.keyHandle = [keyHandle base64EncodedString];
        newTokenEntity.userName = [UserLoginInfo sharedInstance].userName;
        newTokenEntity.pairingTime = [UserLoginInfo sharedInstance].created;
        newTokenEntity.authenticationMode = [UserLoginInfo sharedInstance].authenticationMode;
        newTokenEntity.authenticationType = [UserLoginInfo sharedInstance].authenticationType;
        if (!isSecureClick){
            newTokenEntity.publicKey = crypto.publicKeyBase64;
            newTokenEntity.privateKey = crypto.privateKeyBase64;
            [[DataStoreManager sharedInstance] saveTokenEntity:newTokenEntity];
        } else {
            newTokenEntity.publicKey = @"";
            newTokenEntity.privateKey = @"";
            secureClickToken = newTokenEntity;
        }
        
    }
    NSData* applicationSha256 = [[application SHA256] dataUsingEncoding:NSUTF8StringEncoding];
    NSData* challengeSha256 = [[challenge SHA256] dataUsingEncoding:NSUTF8StringEncoding];
    
    
    NSMutableData* signedData = [[NSMutableData alloc] init];
    //if we're using SecureClick, then responce we'll get from DP SC device
    if (isSecureClick) {
        NSData* applicationSha256Data = [application SHA256Data];
        NSData* challengeSha256Data = [challenge SHA256Data];
        [signedData appendData:challengeSha256Data];
        [signedData appendData:applicationSha256Data];
        [self initBLE:signedData crypto:crypto userPublicKey:userPublicKey keyHandle:keyHandle callback:handler];
    } else {
        signedData = [[NSMutableData alloc] initWithData:[codec encodeEnrollementSignedBytes:REGISTRATION_RESERVED_BYTE_VALUE applicationSha256:applicationSha256 challengeSha256:challengeSha256 keyHandle:keyHandle userPublicKey:userPublicKey]];
        EnrollmentResponse* response = [self makeEnrollmentResponse:signedData crypto:crypto userPublicKey:userPublicKey keyHandle:keyHandle];
        handler(response ,nil);
    }
}

-(void)handleAuthenticationRequest:(AuthenticateRequest*)request isSecureClick:(BOOL)isSecureClick userName:(NSString*)userName callback:(SecureClickAuthCompletionHandler)handler{
    isAuthSent = false;
    //    NSData* control = [request control];
    NSString* application = [request application];
    NSString* challenge = [request challenge];
    //    NSData* keyHandle = [request keyHandle];
    
	TokenEntity* tokenEntity = [[DataStoreManager sharedInstance] getTokenEntityForApplication:application userName:userName];

    NSMutableData* signedData = [[NSMutableData alloc] init];
    //if we're using SecureClick, then responce we'll get from DP SC device
    if (isSecureClick) {
        //Make authentication message for VASCO SecureClick device 
        NSData* applicationSha256Data = [application SHA256Data];
        NSData* challengeSha256Data = [challenge SHA256Data];
        signedData = [[NSMutableData alloc] initWithData:[codec makeAuthenticateMessage:applicationSha256Data challengeSha256:challengeSha256Data keyHandle:request.keyHandle]];
        [self initBLEForAuthentication:signedData callback:handler];
    } else {
		int32_t count = [[DataStoreManager sharedInstance] incrementCountForToken:tokenEntity];
        UserPresenceVerifier* userPres = [[UserPresenceVerifier alloc] init];
        NSData* userPresence = [userPres verifyUserPresence];
        NSData* applicationSha256 = [application SHA256Data];
        NSData* challengeSha256 = [challenge SHA256Data];

        signedData = [[NSMutableData alloc] initWithData:[codec encodeAuthenticateSignedBytes:applicationSha256 userPresence:userPresence counter:count challengeSha256:challengeSha256]];
        GMEllipticCurveCrypto* crypto2 = [GMEllipticCurveCrypto cryptoForKeyBase64:tokenEntity.privateKey];

        NSData *signature = [crypto2 hashSHA256AndSignDataEncoded:signedData];
        
        AuthenticateResponse* response = [[AuthenticateResponse alloc] initWithUserPresence:userPresence counter:count signature:signature];
        handler(response ,nil);
    }
}

-(EnrollmentResponse*)makeEnrollmentResponse:(NSData*)signedData crypto:(GMEllipticCurveCrypto*)crypto userPublicKey:(NSData*) userPublicKey keyHandle:(NSData*) keyHandle{
    NSData *signature = [crypto hashSHA256AndSignDataEncoded:signedData];
    
    NSData* sertificate = [VENDOR_CERTIFICATE_CERT dataFromHexString];
    
    EnrollmentResponse* response = [[EnrollmentResponse alloc] initWithUserPublicKey:userPublicKey keyHandle:keyHandle attestationCertificate:sertificate signature:signature];
    
    return response;
}

-(void)initBLE:(NSData*)valueData crypto:(GMEllipticCurveCrypto*)crypto userPublicKey:(NSData*) userPublicKey keyHandle:(NSData*)keyHandle callback:(SecureClickCompletionHandler)handler{
    
    secureClickHandler = handler;
    secureClickCrypto = crypto;
    secureClickUserPublicKey = userPublicKey;
    secureClickKeyHandle = [[NSMutableData alloc] initWithData:keyHandle];
    [[NSNotificationCenter defaultCenter] postNotificationName:INIT_SECURE_CLICK_NOTIFICATION object:valueData];
}

-(void)initBLEForAuthentication:(NSData*)valueData callback:(SecureClickAuthCompletionHandler)handler{
    secureClickAuthHandler = handler;
    [[NSNotificationCenter defaultCenter] postNotificationName:INIT_SECURE_CLICK_NOTIFICATION object:valueData];
}

-(void)waitForSecureClickNotification:(NSNotification*)notification{
    NSDictionary* dic = notification.object;
    if ([dic objectForKey:@"error"]){
        NSString* errorMessage = [dic objectForKey:@"error"];
        NSError *err = [NSError errorWithDomain:@"Super_Gluu"
                                           code:100
                                       userInfo:@{
                                                  NSLocalizedDescriptionKey:errorMessage
                                                  }];
        secureClickHandler != nil ? secureClickHandler(nil, err) : secureClickAuthHandler(nil, err);
    }
    NSData* responseData = [dic objectForKey:@"responseData"];
    NSString* isEnrollStr = [dic objectForKey:@"isEnroll"];
    BOOL isEnroll = [isEnrollStr boolValue];
    if (responseData != nil){
        //response when keyHandle and/or public key not from u2f
        if (responseData.length == 5){
            secureClickAuthHandler(nil, nil);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_ERROR object:@"KeyHandle and/or public key not from u2f"];
        } else {
            if (isEnroll){
                //So we should extract userPublicKey and keyHandle from response data
                NSData* userPublicKey = [self extractUserPublicKey:responseData];
                NSData* keyHandle = [self extractKeyHandle:responseData];
                NSData* u2FMessage = [self extractU2FMessage:responseData];
                
                EnrollmentResponse* response = [self makeEnrollmentResponse:responseData crypto:secureClickCrypto userPublicKey:userPublicKey keyHandle:keyHandle];
                response.secureClickEnrollData = u2FMessage;
                if (secureClickHandler == nil){
                    
                } else {
                    //Save token for ble device
                    if (secureClickToken != nil) {
                        [[DataStoreManager sharedInstance] saveTokenEntity:secureClickToken];
                    }
                    secureClickHandler(response, nil);
                }
            } else {
                if (!isAuthSent) {
                    isAuthSent = !isAuthSent;
                    int u2FCounter = [self extractCounter:responseData];
                    NSData *signature = [self extractSignature:responseData];
                    NSData *authMessage = [self extractAuthMessage:responseData];
                    UserPresenceVerifier* userPres = [[UserPresenceVerifier alloc] init];
                    NSData* userPresence = [userPres verifyUserPresence];
                    GMEllipticCurveCrypto* crypto = [GMEllipticCurveCrypto generateKeyPairForCurve:
                                                     GMEllipticCurveSecp256r1];
                    
                    NSData *signatureData = [crypto hashSHA256AndSignDataEncoded:signature];
                    AuthenticateResponse* response = [[AuthenticateResponse alloc] initWithUserPresence:userPresence counter:u2FCounter signature:signatureData];
                    response.secureClickData = authMessage;
                    if (secureClickAuthHandler == nil){
                        
                    } else {
                        secureClickAuthHandler(response, nil);
                    }
                }
            }
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(NSData*)extractUserPublicKey:(NSData*)responseData{
    NSData* userPublicKey = [[NSData alloc] init];
    // userPublicKey range 1...65 (0 -0x05, from 1 till 65 userPublicKey)
    userPublicKey = [responseData subdataWithRange:NSMakeRange(1, 65)];
    
    return userPublicKey;
}

-(NSData*)extractKeyHandle:(NSData*)responseData{
    NSData* keyHandle = [[NSData alloc] init];
    // userPublicKey range 67...length (0 reserved byte, 65 userPublicKey length, 1 byte length, length)
    NSData* keyHandleLengthByte = [responseData subdataWithRange:NSMakeRange(66, 1)];
    NSString* lengthStr = [keyHandleLengthByte.description substringWithRange:NSMakeRange(1, 2)];
    int length = [self intFromHexString: lengthStr];
    keyHandle = [responseData subdataWithRange:NSMakeRange(67, length)];
    return keyHandle;
}

-(NSData*)extractU2FMessage:(NSData*)responseData{
    NSData* u2FMessageBytes = [responseData subdataWithRange:NSMakeRange(0, responseData.length-2)];
    
    return u2FMessageBytes;
}

-(int)extractCounter:(NSData*)responseData{
    NSData* u2FCounterBytes = [responseData subdataWithRange:NSMakeRange(4, 1)];
    NSString* lengthStr = [u2FCounterBytes.description substringWithRange:NSMakeRange(1, 2)];
    int counter = [self intFromHexString: lengthStr];
    return counter;
}

-(NSData*)extractSignature:(NSData*)responseData{
    NSData* u2FSignatureBytes = [responseData subdataWithRange:NSMakeRange(5, responseData.length-7)];
    
    return u2FSignatureBytes;
}

-(NSData*)extractAuthMessage:(NSData*)responseData{
    NSMutableData* u2FAuthMessageBytes = [[NSMutableData alloc] init];
    NSData* u2FAuthMessage = [[responseData subdataWithRange:NSMakeRange(0, responseData.length-2)] copy];
    UserPresenceVerifier* userPres = [[UserPresenceVerifier alloc] init];
    NSData* userPresence = [userPres verifyUserPresence];
    [u2FAuthMessageBytes appendData:userPresence];
    [u2FAuthMessageBytes appendData:u2FAuthMessage];
    
    return u2FAuthMessageBytes;
}

- (unsigned int)intFromHexString:(NSString *) hexStr
{
    unsigned int hexInt = 0;
    
    // Create scanner
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    
    // Tell scanner to skip the # character
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
    
    // Scan hex value
    [scanner scanHexInt:&hexInt];
    
    return hexInt;
}

@end
