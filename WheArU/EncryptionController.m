//
//  EncryptionController.m
//  WheArU
//
//  Created by Calvin Ng on 9/16/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "EncryptionController.h"

#import "AppDelegate.h"
#import "UserController.h"
#import "NotificationController.h"

#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "WAULog.h"
#import "WAUServerConnector.h"
#import "WAUServerConnectorRequest.h"


NSString *const kWAUSystemKey = @"4pl5YeFT1MX7QZsND!6v116@7lM1vIxz(SEX*aG)";
NSString *const kWAUUserDictionaryKeyGeneratedKey = @"WAUGeneratedKey";

@implementation EncryptionController
{
    NSMutableArray *delegateList;
}

- (id)init
{
    if (self = [super init]) {
        delegateList = [[NSMutableArray alloc] init];
        
        NSString *generatedKey = [[NSUserDefaults standardUserDefaults] objectForKey:kWAUUserDictionaryKeyGeneratedKey];
        if (generatedKey != nil) [self setGeneratedKey:generatedKey];
    }
    return self;
}

#pragma mark - Singleton Class

+ (EncryptionController *)sharedInstance
{
    static EncryptionController *sharedInstance = nil;
    
    @synchronized(self) {
        if (sharedInstance == nil) sharedInstance = [[EncryptionController alloc] init];
    }
    return sharedInstance;
}

#pragma mark - Functions
#pragma mark Support

- (NSString *)encryptString:(NSString *)plainText withKey:(NSString *)key
{
    NSError *error = nil;
    NSData *plainData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    NSString *cipherText = [[RNEncryptor encryptData:plainData withSettings:kRNCryptorAES256Settings password:key error:&error] base64EncodedStringWithOptions:kNilOptions];
    
    if (error != nil) [WAULog log:[NSString stringWithFormat:@"encryption error: %@", [error localizedDescription]] from:self];
    return cipherText;
}

- (NSString *)decryptString:(NSString *)cipherText withKey:(NSString *)key
{
    NSError *error = nil;
    NSData *cipherData = [[NSData alloc] initWithBase64EncodedString:cipherText options:kNilOptions];
    NSString *plainText = [[NSString alloc] initWithData:[RNDecryptor decryptData:cipherData withPassword:key error:&error] encoding:NSUTF8StringEncoding];
    
    if (error != nil) [WAULog log:[NSString stringWithFormat:@"decryption error: %@", [error localizedDescription]] from:self];
    return plainText;
}

#pragma mark External

- (void)addDelegate:(id<EncryptionControllerDelegate>)delegate
{
    [delegateList addObject:delegate];
    
    if ([self generatedKey] != nil && [delegate respondsToSelector:@selector(controllerDidSetGeneratedKey:)]) [delegate controllerDidSetGeneratedKey:self];
}

- (NSString *)encryptStringWithSystemKey:(NSString *)plainText
{
    return [self encryptString:plainText withKey:kWAUSystemKey];
}

- (NSString *)decryptStringWithSystemKey:(NSString *)cipherText
{
    return [self decryptString:cipherText withKey:kWAUSystemKey];
}

- (NSString *)encryptStringWithGeneratedKey:(NSString *)plainText
{
    return [self encryptString:plainText withKey:[self generatedKey]];
}

- (NSString *)decryptStringWithGeneratedKey:(NSString *)cipherText
{
    return [self decryptString:cipherText withKey:[self generatedKey]];
}

#pragma mark - Properties

- (void)setGeneratedKey:(NSString *)generatedKey
{
    _generatedKey = generatedKey;
    
    [[NSUserDefaults standardUserDefaults] setObject:generatedKey forKey:kWAUUserDictionaryKeyGeneratedKey];
    
    for (id<EncryptionControllerDelegate> delegate in delegateList) {
        if ([delegate respondsToSelector:@selector(controllerDidSetGeneratedKey:)]) [delegate controllerDidSetGeneratedKey:self];
    }
}

@end
