//
//  NotificationController.h
//  WheArU
//
//  Created by Calvin Ng on 9/16/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EncryptionController.h"


extern NSString *const kWAURequestInfoDictionaryKeyUserId;

extern NSString *const kWAURequestInfoDictionaryKeyIOSInfo;
extern NSString *const kWAURequestInfoDictionaryKeyAndroidInfo;

extern NSString *const kWAURequestInfoDictionaryKeyExpiration;

extern NSString *const kWAUNotificationKeyRemoteURL;

typedef NS_ENUM(int, WAUNotificationKeyState)
{
    WAUNotificationKeyStateNoGeneratedKey,
    WAUNotificationKeyStateNoNotificationKey,
    WAUNotificationKeyStateRequestingNotificationKey,
    WAUNotificationKeyStateValidNotificationKey,
};

@protocol NotificationControllerDelegate;

@interface NotificationController : NSObject <EncryptionControllerDelegate>

@property (nonatomic, assign) WAUNotificationKeyState notificationKeyState;

@property (nonatomic, strong) NSString *IOSKey;
@property (nonatomic, strong) NSString *androidKey;

+ (NotificationController *)sharedInstance;

- (void)addDelegate:(id<NotificationControllerDelegate>)delegate;

@end

@protocol NotificationControllerDelegate <NSObject>

@optional
- (void)controllerDidValidateNotificationKey:(NotificationController *)controller;

@end
