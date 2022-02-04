//
//  UserLoginInfo.m
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/16/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import "UserLoginInfo.h"

@implementation UserLoginInfo

+ (instancetype) sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}
    
- (NSString *)displayNameForWonderfulType:(LogState)LogState {
    switch(LogState) {
        case LOGIN_SUCCESS:
            return @"LOGIN_SUCCESS";
        case LOGIN_FAILED:
            return @"LOGIN_FAILED";
        case LOGIN_DECLINED:
            return @"LOGIN_DECLINED";
        case ENROLL_SUCCESS:
            return @"ENROLL_SUCCESS";
        case ENROLL_FAILED:
            return @"ENROLL_FAILED";
        case ENROLL_DECLINED:
            return @"ENROLL_DECLINED";
        case UNKNOWN_ERROR:
            return @"UNKNOWN_ERROR";
    }
    [NSException raise:NSInvalidArgumentException format:@"The given format type number, %ld, is not known.", (unsigned long)_logState];
    return nil; // Keep the compiler happy - does not understand above line never returns!
}

- (LogState)displayTypeForWonderfulName:(NSString *)LogState {
    if ([LogState isEqualToString:@"LOGIN_SUCCESS"]) {
        return LOGIN_SUCCESS;
    }
    if ([LogState isEqualToString:@"LOGIN_FAILED"]) {
        return LOGIN_FAILED;
    }
    if ([LogState isEqualToString:@"LOGIN_DECLINED"]) {
        return LOGIN_DECLINED;
    }
    if ([LogState isEqualToString:@"ENROLL_SUCCESS"]) {
        return ENROLL_SUCCESS;
    }
    if ([LogState isEqualToString:@"ENROLL_FAILED"]) {
        return ENROLL_FAILED;
    }
    if ([LogState isEqualToString:@"ENROLL_DECLINED"]) {
        return ENROLL_DECLINED;
    }
    return UNKNOWN_ERROR;
}
    
    /* This code has been added to support encoding and decoding my objecst */
    
-(void)encodeWithCoder:(NSCoder *)encoder {
	//Encode the properties of the object
	[encoder encodeObject:_userName forKey:@"userName"];
	[encoder encodeObject:_created forKey:@"created"];
	[encoder encodeObject:_application forKey:@"application"];
	[encoder encodeObject:_issuer forKey:@"issuer"];
	[encoder encodeObject:_authenticationType forKey:@"authenticationType"];
	[encoder encodeObject:_authenticationMode forKey:@"authenticationMode"];
	[encoder encodeObject:_locationIP forKey:@"locationIP"];
	[encoder encodeObject:_locationCity forKey:@"locationCity"];
	[encoder encodeObject:[self displayNameForWonderfulType:_logState] forKey:@"logState"];
	[encoder encodeObject:_errorMessage forKey:@"errorMessage"];
}
    
-(id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if ( self != nil )
	{
		//decode the properties
		_userName = [decoder decodeObjectForKey:@"userName"];
		_created = [decoder decodeObjectForKey:@"created"];
		_application = [decoder decodeObjectForKey:@"application"];
		_issuer = [decoder decodeObjectForKey:@"issuer"];
		_authenticationType = [decoder decodeObjectForKey:@"authenticationType"];
		_authenticationMode = [decoder decodeObjectForKey:@"authenticationMode"];
		_locationIP = [decoder decodeObjectForKey:@"locationIP"];
		_locationCity = [decoder decodeObjectForKey:@"locationCity"];
		_locationCity = [decoder decodeObjectForKey:@"locationCity"];
		_logState = [self displayTypeForWonderfulName:[decoder decodeObjectForKey:@"logState"]];
		_errorMessage = [decoder decodeObjectForKey:@"errorMessage"];
	}
	return self;
}

- (BOOL)isEqual:(id)object
{
    BOOL result = NO;

    if ([object isKindOfClass:[self class]]) {
        UserLoginInfo *otherLog = object;
		
        result = [self.application isEqualToString:[otherLog application]] &&
        [self.userName isEqualToString:[otherLog userName]] &&
		[self.created isEqualToString: [otherLog created]];
    }

    return result;
}

- (NSUInteger)hash
{
    NSUInteger result = 1;
    NSUInteger prime = 31;

    result = prime * result + [_userName hash];
    result = prime * result + [_application hash];
	result = prime * result + [_created hash];
	
    return result;
}


@end
