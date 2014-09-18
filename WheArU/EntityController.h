//
//  EntityController.h
//  WheArU
//
//  Created by Calvin Ng on 9/15/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


extern NSString *const kWAUUserDictionaryKeyUserId;
extern NSString *const kWAUUserDictionaryKeyUsername;
extern NSString *const kWAUUserDictionaryKeyUserIcon;
extern NSString *const kWAUUserDictionaryKeyUserColor;
extern NSString *const kWAUUserDictionaryKeyVersion;
extern NSString *const kWAUUserDictionaryKeyNotificationKey;
extern NSString *const kWAUUserDictionaryKeyPlatform;

typedef NS_ENUM(int, WAUUserPlatformType)
{
    WAUUserPlatformTypeIOS,
    WAUUserPlatformTypeAndroid
};

typedef NS_ENUM(int, WAUImageIconState)
{
    WAUImageIconStateNoIcon,
    WAUImageIconStateNotSynced,
    WAUImageIconStateSyncing,
    WAUImageIconStateSynced
};

@interface EntityController : NSObject

@property (nonatomic, readonly, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSString *userId;

@property (nonatomic, assign) WAUUserPlatformType platform;
@property (nonatomic, strong) NSData *notificationKey;

@property (nonatomic, strong) NSString *username;

@property (nonatomic, strong) UIColor *userColor;
@property (nonatomic, readonly, strong) UIColor *wordColor;

@property (nonatomic, strong) UIImage *userIcon;
@property (nonatomic, strong) NSString *userIconLink;
@property (nonatomic, assign) WAUImageIconState userIconState;

+ (NSArray *)availableUserColor;

@end
