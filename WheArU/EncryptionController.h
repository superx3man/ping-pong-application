//
//  EncryptionController.h
//  WheArU
//
//  Created by Calvin Ng on 9/16/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UserController.h"


extern NSString *const kWAUGenerateKeyRemoteURL;

extern NSString *const kWAUDeviceInfoDictionaryKeyUserId;
extern NSString *const kWAUDeviceInfoDictionaryKeyGeneratedKey;

extern NSString *const kWAUSystemKey;
extern NSString *const kWAUUserDictionaryKeyGeneratedKey;

typedef NS_ENUM(int, WAUGeneratedKeyState)
{
    WAUGeneratedKeyStateNoGeneratedKey,
    WAUGeneratedKeyStateRequestingGeneratedKey,
    WAUGeneratedKeyStateValidGeneratedKey,
};

@protocol EncryptionControllerDelegate;

@interface EncryptionController : NSObject <UserControllerDelegate>

@property (nonatomic, assign) WAUGeneratedKeyState generatedKeyState;

+ (EncryptionController *)sharedInstance;

- (void)addDelegate:(id<EncryptionControllerDelegate>)delegate;

- (NSString *)encryptStringWithSystemKey:(NSString *)plainText;
- (NSString *)decryptStringWithSystemKey:(NSString *)cipherText;

- (NSString *)encryptStringWithGeneratedKey:(NSString *)plainText;
- (NSString *)decryptStringWithGeneratedKey:(NSString *)cipherText;

@end

@protocol EncryptionControllerDelegate <NSObject>

@optional
- (void)controllerDidValidateGeneratedKey:(EncryptionController *)controller;

@end
