//
//  ECCKey.m
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/3/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import "TokenEntity.h"

@implementation TokenEntity
    
/* This code has been added to support encoding and decoding my objecst */
    
-(void)encodeWithCoder:(NSCoder *)encoder {
	//Encode the properties of the object
	[encoder encodeObject:_application forKey:@"application"];
	[encoder encodeObject:_issuer forKey:@"issuer"];
	[encoder encodeObject:_privateKey forKey:@"privateKey"];
	[encoder encodeObject:_publicKey forKey:@"publicKey"];
	[encoder encodeObject:_keyHandle forKey:@"keyHandle"];
	[encoder encodeObject:_userName forKey:@"userName"];
	[encoder encodeObject:_pairingTime forKey:@"pairingTime"];
	[encoder encodeObject:_authenticationMode forKey:@"authenticationMode"];
	[encoder encodeObject:_authenticationType forKey:@"authenticationType"];
	[encoder encodeObject:_count forKey:@"count"];
	[encoder encodeObject:_keyName forKey:@"keyName"];
	[encoder encodeBool:_isCountUpdated forKey:@"isCountUpdated"];
}
    
-(id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if ( self != nil )
	{
		//decode the properties
		_application = [decoder decodeObjectForKey:@"application"];
		_issuer = [decoder decodeObjectForKey:@"issuer"];
		_privateKey = [decoder decodeObjectForKey:@"privateKey"];
		_publicKey = [decoder decodeObjectForKey:@"publicKey"];
		_keyHandle = [decoder decodeObjectForKey:@"keyHandle"];
		_userName = [decoder decodeObjectForKey:@"userName"];
		_pairingTime = [decoder decodeObjectForKey:@"pairingTime"];
		_authenticationMode = [decoder decodeObjectForKey:@"authenticationMode"];
		_authenticationType = [decoder decodeObjectForKey:@"authenticationType"];
		_count = [decoder decodeObjectForKey:@"count"];
		_keyName = [decoder decodeObjectForKey:@"keyName"];
		_isCountUpdated = [decoder decodeBoolForKey:@"isCountUpdated"];
	}
	return self;
}

// this does not use the timestamp or keyHandle. The purpose is so that we can remove old tokens for the same app/username
- (BOOL)isEqual:(id)object
{
    BOOL result = NO;

    if ([object isKindOfClass:[self class]]) {
        TokenEntity *otherToken = object;
        result = [self.application isEqualToString:[otherToken application]] &&
        [self.userName isEqualToString:[otherToken userName]];
    }

    return result;
}

- (NSUInteger)hash
{
    NSUInteger result = 1;
    NSUInteger prime = 31;

    result = prime * result + [_userName hash];
    result = prime * result + [_application hash];

    return result;
}

@end
