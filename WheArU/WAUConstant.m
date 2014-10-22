//
//  WAUConstant.m
//  WheArU
//
//  Created by Calvin Ng on 9/21/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "WAUConstant.h"


NSString *const kWAUServerEndpoint = @"pingpong.calvinx3.com";

NSString *const kWAUServerEndpointRegister = @"register";
NSString *const kWAUServerEndpointUserSync = @"user_sync";
NSString *const kWAUServerEndpointContactSync = @"contact_sync";
NSString *const kWAUServerEndpointPing = @"ping";
NSString *const kWAUServerEndpointPingSync = @"ping_sync";
NSString *const kWAUServerEndpointUserRelation = @"relate_user";
NSString *const kWAUServerEndpointLinkExternal = @"link_external";
NSString *const kWAUServerEndpointSyncLink = @"sync_link";

NSString *const kWAUDictionaryKeyDevelopment = @"dev";

NSString *const kWAUDictionaryKeyUserId = @"id";

NSString *const kWAUDictionaryKeyUsername = @"name";
NSString *const kWAUDictionaryKeyUserIcon = @"icon";
NSString *const kWAUDictionaryKeyUserColor = @"color";
NSString *const kWAUDictionaryKeyNotificationKey = @"token";
NSString *const kWAUDictionaryKeyVersion = @"ver";
NSString *const kWAUDictionaryKeyPlatform = @"os";

NSString *const kWAUDictionaryKeyGeneratedKey = @"key";

NSString *const kWAUDictionaryKeyModifiedList = @"modified";

NSString *const kWAUDictionaryKeyContactList = @"clist";
NSString *const kWAUDictionaryKeyContactId = @"cid";
NSString *const kWAUDictionaryKeyIsNewContact = @"new";

NSString *const kWAUDictionaryKeyContentType = @"ntype";
NSString *const kWAUDictionaryKeyUserJSON = @"user";

NSString *const kWAUDictionaryKeyPingType = @"ping";
NSString *const kWAUDictionaryKeyLocationInfo = @"loc";
NSString *const kWAUDictionaryKeyPingCount = @"count";

NSString *const kWAUDictionaryKeyRelationType = @"rtype";

NSString *const kWAUDictionaryKeyExternalId = @"eid";
NSString *const kWAUDictionaryKeyExternalList = @"elist";
NSString *const kWAUDictionaryKeyExternalType = @"etype";

float const kWAUContactUpdateAnimationDuration = 0.3f;

int const kWAULocationMaximumRetryFetch = 3;
float const kWAULocationTargetAccuracy = 100.f;

@implementation WAUConstant

@end
