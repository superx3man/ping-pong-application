//
//  UserController.h
//  WheArU
//
//  Created by Calvin Ng on 9/6/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "User.h"


extern NSString *const kWAUImageUploadRemoteURL;

extern NSString *const kWAUImageUploadDictionaryKeyUserId;
extern NSString *const kWAUImageUploadDictionaryKeyImageData;

extern NSString *const kWAUUserDictionaryKeyUsername;
extern NSString *const kWAUUserDictionaryKeyUserIcon;
extern NSString *const kWAUUserDictionaryKeyUserColor;
extern NSString *const kWAUUserDictionaryKeyVersion;
extern NSString *const kWAUUserDictionaryKeyNotificationKey;
extern NSString *const kWAUUserDictionaryKeyPlatform;

@protocol UserControllerDelegate;

@interface UserController : NSObject

typedef NS_ENUM(NSInteger, WAUUserPlatformType)
{
    WAUUserPlatformTypeIOS,
    WAUUserPlatformTypeAndroid
};

typedef NS_ENUM(NSInteger, WAUUploadImageIconState)
{
    WAUUploadImageIconStateNoIcon,
    WAUUploadImageIconStateNotUploaded,
    WAUUploadImageIconStateUploading,
    WAUUploadImageIconStateUploaded
};

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) UIColor *userColor;

@property (nonatomic, strong) UIImage *userIcon;
@property (nonatomic, assign) WAUUploadImageIconState userIconUploadState;

@property (nonatomic, strong) NSData *notificationKey;

@property (nonatomic, readonly, strong) UIColor *wordColor;

@property (nonatomic, assign) int fetchCount;

- (void)addDelegate:(id<UserControllerDelegate>)delegate;

- (BOOL)isUserRegistered;
- (void)createUser;

- (void)uploadUserIcon;

- (NSString *)JSONDescription;

+ (NSArray *)availableUserColor;

@end

@protocol UserControllerDelegate <NSObject>

@optional
- (void)userDidUpdateUsername:(UserController *)controller;
- (void)userDidUpdateUserIcon:(UserController *)controller;
- (void)userDidUpdateUserColor:(UserController *)controller;

@end