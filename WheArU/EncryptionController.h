//
//  EncryptionController.h
//  WheArU
//
//  Created by Calvin Ng on 9/16/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UserController.h"


extern NSString *const kWAUSystemKey;
extern NSString *const kWAUUserDictionaryKeyGeneratedKey;

@protocol EncryptionControllerDelegate;

@interface EncryptionController : NSObject

@property (nonatomic, strong) NSString *generatedKey;

+ (EncryptionController *)sharedInstance;

- (void)addDelegate:(id<EncryptionControllerDelegate>)delegate;

- (NSString *)encryptStringWithSystemKey:(NSString *)plainText;
- (NSString *)decryptStringWithSystemKey:(NSString *)cipherText;

- (NSString *)encryptStringWithGeneratedKey:(NSString *)plainText;
- (NSString *)decryptStringWithGeneratedKey:(NSString *)cipherText;

@end

@protocol EncryptionControllerDelegate <NSObject>

@optional
- (void)controllerDidSetGeneratedKey:(EncryptionController *)controller;

@end
