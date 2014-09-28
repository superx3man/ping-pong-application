//
//  WAUConstant.h
//  WheArU
//
//  Created by Calvin Ng on 9/21/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *const kWAUServerEndpoint;

extern NSString *const kWAUServerEndpointRegister;
extern NSString *const kWAUServerEndpointUserSync;
extern NSString *const kWAUServerEndpointContactSync;
extern NSString *const kWAUServerEndpointPing;
extern NSString *const kWAUServerEndpointPingSync;
extern NSString *const kWAUServerEndpointUserRelation;

extern NSString *const kWAUDictionaryKeyDevelopment;

extern NSString *const kWAUDictionaryKeyUserId;

extern NSString *const kWAUDictionaryKeyUsername;
extern NSString *const kWAUDictionaryKeyUserIcon;
extern NSString *const kWAUDictionaryKeyUserColor;
extern NSString *const kWAUDictionaryKeyNotificationKey;
extern NSString *const kWAUDictionaryKeyVersion;
extern NSString *const kWAUDictionaryKeyPlatform;

extern NSString *const kWAUDictionaryKeyGeneratedKey;

extern NSString *const kWAUDictionaryKeyModifiedList;

extern NSString *const kWAUDictionaryKeyContactId;
extern NSString *const kWAUDictionaryKeyIsNewContact;

extern NSString *const kWAUDictionaryKeyContentType;
extern NSString *const kWAUDictionaryKeyUserJSON;

extern NSString *const kWAUDictionaryKeyPingType;
extern NSString *const kWAUDictionaryKeyLocationInfo;
extern NSString *const kWAUDictionaryKeyPingCount;

extern NSString *const kWAUDictionaryKeyRelationType;

extern float const kWAUContactUpdateAnimationDuration;

@interface WAUConstant : NSObject

@end
