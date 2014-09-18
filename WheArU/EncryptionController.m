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


NSString *const kWAUGenerateKeyRemoteURL = @"generate";

NSString *const kWAUDeviceInfoDictionaryKeyUserId = @"id";
NSString *const kWAUDeviceInfoDictionaryKeyGeneratedKey = @"gen";

NSString *const kWAUSystemKey = @"4pl5YeFT1MX7QZsND!6v116@7lM1vIxz(SEX*aG)";
NSString *const kWAUUserDictionaryKeyGeneratedKey = @"WAUGeneratedKey";

@implementation EncryptionController
{
    NSString *generatedKey;
    
    NSMutableArray *delegateList;
}

- (id)init
{
    if (self = [super init]) {
        delegateList = [[NSMutableArray alloc] init];
        
        [self setGeneratedKeyState:WAUGeneratedKeyStateNoGeneratedKey];
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

- (void)validateGeneratedKey
{
    if ([self generatedKeyState] == WAUGeneratedKeyStateRequestingGeneratedKey) return;
    [WAULog log:@"validating generated key" from:self];
    
    generatedKey = [[NSUserDefaults standardUserDefaults] objectForKey:kWAUUserDictionaryKeyGeneratedKey];
    [self setGeneratedKeyState:generatedKey == nil ? WAUGeneratedKeyStateNoGeneratedKey : WAUGeneratedKeyStateValidGeneratedKey];
    
    if ([self generatedKeyState] == WAUGeneratedKeyStateNoGeneratedKey) [self fetchGeneratedKey];
    else if ([self generatedKeyState] == WAUGeneratedKeyStateValidGeneratedKey) {
        for (id<EncryptionControllerDelegate>delegate in delegateList) {
            if ([delegate respondsToSelector:@selector(controllerDidValidateGeneratedKey:)]) [delegate controllerDidValidateGeneratedKey:self];
        }
    }
}

- (void)fetchGeneratedKey
{
    if ([[UserController sharedInstance] userId] == nil || [self generatedKeyState] != WAUGeneratedKeyStateNoGeneratedKey) return;
    [self setGeneratedKeyState:WAUGeneratedKeyStateRequestingGeneratedKey];
    
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setObject:[[UserController sharedInstance] userId] forKey:kWAUDeviceInfoDictionaryKeyUserId];
    
    WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithEndPoint:kWAUGenerateKeyRemoteURL method:@"POST" parameters:userDictionary];
    [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest)
    {
        [WAULog log:@"failed to download generated key" from:self];
        [self setGeneratedKeyState:WAUGeneratedKeyStateNoGeneratedKey];
        
        [self performSelector:@selector(validateGeneratedKey) withObject:nil afterDelay:300];
    }];
    [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult)
    {
        generatedKey = [(NSDictionary *) requestResult objectForKey:kWAUDeviceInfoDictionaryKeyGeneratedKey];
        [[NSUserDefaults standardUserDefaults] setObject:generatedKey forKey:kWAUUserDictionaryKeyGeneratedKey];
        
        [WAULog log:[NSString stringWithFormat:@"generated key downloaded"] from:self];
        [self setGeneratedKeyState:WAUGeneratedKeyStateNoGeneratedKey];
        [self validateGeneratedKey];
    }];
    [[WAUServerConnector sharedInstance] sendRequest:request withTag:@"RequestGeneratedKey"];
}

#pragma mark External

- (void)addDelegate:(id<EncryptionControllerDelegate>)delegate
{
    [delegateList addObject:delegate];
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
    return [self encryptString:plainText withKey:generatedKey];
}

- (NSString *)decryptStringWithGeneratedKey:(NSString *)cipherText
{
    return [self decryptString:cipherText withKey:generatedKey];
}

#pragma mark - Delegates
#pragma mark UserControllerDelegate

- (void)controllerDidSetUserId:(UserController *)controller
{
    [self validateGeneratedKey];
}

@end
