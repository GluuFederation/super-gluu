//
//  U2FKeyImpl.h
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/12/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnrollmentRequest.h"
#import "EnrollmentResponse.h"
#import "RawMessageCodec.h"
#import "AuthenticateRequest.h"

@interface U2FKeyImpl : NSObject{
    
    RawMessageCodec* codec;
}

typedef void(^SecureClickCompletionHandler)(EnrollmentResponse *response, NSError *error);
typedef void(^SecureClickAuthCompletionHandler)(AuthenticateResponse *response, NSError *error);

-(void)handleEnrollmentRequest:(EnrollmentRequest*)request isDecline:(BOOL)isDecline isSecureClick:(BOOL)isSecureClick callback:(SecureClickCompletionHandler)handler;

-(void)handleAuthenticationRequest:(AuthenticateRequest*)request isSecureClick:(BOOL)isSecureClick userName:(NSString*)userName callback:(SecureClickAuthCompletionHandler)handler;

@end
