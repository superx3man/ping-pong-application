//
//  NotificationController.m
//  WheArU
//
//  Created by Calvin Ng on 9/16/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "NotificationController.h"

#import "AppDelegate.h"
#import "Internal.h"
#import "UserController.h"

#import "Reachability.h"
#import "WAULog.h"
#import "WAUServerConnector.h"
#import "WAUServerConnectorRequest.h"


NSString *const kWAURequestInfoDictionaryKeyUserId = @"id";

NSString *const kWAURequestInfoDictionaryKeyIOSInfo = @"ios";
NSString *const kWAURequestInfoDictionaryKeyAndroidInfo = @"android";

NSString *const kWAURequestInfoDictionaryKeyExpiration = @"exp";

NSString *const kWAUNotificationKeyRemoteURL = @"update";

@implementation NotificationController
{
    NSManagedObjectContext *managedObjectContext;
    Internal *notificationInternal;
    
    NSMutableArray *delegateList;
}

- (id)init
{
    if (self = [super init]) {
        managedObjectContext = [(AppDelegate *) [[UIApplication sharedApplication] delegate] managedObjectContext];
        delegateList = [[NSMutableArray alloc] init];
        
        [self setNotificationKeyState:WAUNotificationKeyStateNoGeneratedKey];
    }
    return self;
}

#pragma mark - Singleton Class

+ (NotificationController *)sharedInstance
{
    static NotificationController *sharedInstance = nil;
    
    @synchronized(self) {
        if (sharedInstance == nil) sharedInstance = [[NotificationController alloc] init];
    }
    return sharedInstance;
}

#pragma mark - Functions
#pragma mark Support

- (void)validateNotificationKey
{
    if ([self notificationKeyState] == WAUNotificationKeyStateRequestingNotificationKey || [self notificationKeyState] == WAUNotificationKeyStateNoGeneratedKey) return;
    [WAULog log:@"validating notification key" from:self];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:kWAUCoreDataEntityInternal inManagedObjectContext:managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setReturnsObjectsAsFaults:NO];
    
    NSArray *requestResult = [managedObjectContext executeFetchRequest:request error:nil];
    
    BOOL validKey = NO;
    if (requestResult != nil && [requestResult count] >= 1) {
        notificationInternal = (Internal *) [requestResult lastObject];
        
        int64_t currentTimestamp = [[NSDate date] timeIntervalSince1970];
        if ([notificationInternal ios] != nil && [notificationInternal android] != nil && [notificationInternal expiration] > currentTimestamp) {
            NSString *iosKey = [[EncryptionController sharedInstance] decryptStringWithGeneratedKey:[notificationInternal ios]];
            NSString *androidKey = [[EncryptionController sharedInstance] decryptStringWithGeneratedKey:[notificationInternal android]];
            if ([iosKey length] != 0 && [androidKey length] != 0) {
                [self setIOSKey:iosKey];
                [self setAndroidKey:androidKey];
                
                validKey = YES;
                [self setNotificationKeyState:WAUNotificationKeyStateValidNotificationKey];
                
                for (id<NotificationControllerDelegate>delegate in delegateList) {
                    if ([delegate respondsToSelector:@selector(controllerDidValidateNotificationKey:)]) [delegate controllerDidValidateNotificationKey:self];
                }
            }
        }
    }
    if (!validKey) {
        [self setNotificationKeyState:WAUNotificationKeyStateNoNotificationKey];
        [self fetchNotificationKey];
    }
}

- (void)fetchNotificationKey
{
    if ([[UserController sharedInstance] userId] == nil || [self notificationKeyState] != WAUNotificationKeyStateNoNotificationKey) return;
    [self setNotificationKeyState:WAUNotificationKeyStateRequestingNotificationKey];
    
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setObject:[[UserController sharedInstance] userId] forKey:kWAURequestInfoDictionaryKeyUserId];
    
    WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithEndPoint:kWAUNotificationKeyRemoteURL method:@"POST" parameters:userDictionary];
    [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest)
     {
         [WAULog log:@"failed to download notification key" from:self];
         [self setNotificationKeyState:WAUNotificationKeyStateNoNotificationKey];
         
         [self performSelector:@selector(validateNotificationKey) withObject:nil afterDelay:300];
     }];
    [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult)
     {
         NSString *ios = [(NSDictionary *) requestResult objectForKey:kWAURequestInfoDictionaryKeyIOSInfo];
         NSString *android = [[(NSDictionary *) requestResult objectForKey:kWAURequestInfoDictionaryKeyAndroidInfo] objectForKey:kWAURequestInfoDictionaryKeyIOSInfo];
         int64_t expirationTime = [[(NSDictionary *) requestResult objectForKey:kWAURequestInfoDictionaryKeyExpiration] longLongValue];
         
         if (notificationInternal == nil) notificationInternal = [NSEntityDescription insertNewObjectForEntityForName:kWAUCoreDataEntityInternal inManagedObjectContext:managedObjectContext];
         
         [notificationInternal setIos:ios];
         [notificationInternal setAndroid:android];
         [notificationInternal setExpiration:expirationTime];
         [managedObjectContext save:nil];
         
         [WAULog log:[NSString stringWithFormat:@"notification key expiration time: %lld", expirationTime] from:self];
         [self setNotificationKeyState:WAUNotificationKeyStateNoNotificationKey];
         [self validateNotificationKey];
     }];
    [[WAUServerConnector sharedInstance] sendRequest:request withTag:@"RequestNotificationKey"];
}

#pragma mark External

- (void)addDelegate:(id<NotificationControllerDelegate>)delegate
{
    [delegateList addObject:delegate];
}

#pragma mark - Delegates
#pragma mark EncryptionControllerDelegate

- (void)controllerDidValidateGeneratedKey:(EncryptionController *)controller
{
    [self setNotificationKeyState:WAUNotificationKeyStateNoNotificationKey];
    [self validateNotificationKey];
}

@end
